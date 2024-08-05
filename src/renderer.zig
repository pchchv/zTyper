const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const glyph_lib = @import("glyphee.zig");
const constants = @import("constants.zig");

const Camera = helpers.Camera;
const Vector2 = helpers.Vector2;
const Vector2_gl = helpers.Vector2_gl;
const Vector3_gl = helpers.Vector3_gl;
const Vector4_gl = helpers.Vector4_gl;
const TypeSetter = glyph_lib.TypeSetter;

const CIRCLE_TEXTURE_SIZE = 512;
const FONT_TEX_SIZE = glyph_lib.FONT_TEX_SIZE;
const VERTEX_BASE_FILE: [:0]const u8 = @embedFile("../data/shaders/vertex.glsl");
const FRAGMENT_ALPHA_FILE: [:0]const u8 = @embedFile("../data/shaders/fragment_texalpha.glsl");

const VertexData = struct {
    position: Vector3_gl = .{},
    texCoord: Vector2_gl = .{},
    color: Vector4_gl = .{},
};

const ShaderData = struct {
    const Self = @This();
    program: c.GLuint = 0,
    texture: c.GLuint = 0,
    has_tris: bool = true,
    has_lines: bool = false,
    indices: std.ArrayList(c_uint),
    triangle_verts: std.ArrayList(VertexData),

    pub fn init(allocator: *std.mem.Allocator) Self {
        return Self{
            .triangle_verts = std.ArrayList(VertexData).init(allocator),
            .indices = std.ArrayList(c_uint).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.triangle_verts.deinit();
        self.indices.deinit();
    }

    pub fn clear_buffers(self: *Self) void {
        self.triangle_verts.shrinkRetainingCapacity(0);
        self.indices.shrinkRetainingCapacity(0);
    }
};

pub const Renderer = struct {
    const Self = @This();
    ticks: u32 = 0,
    camera: *Camera,
    vao: c.GLuint = 0,
    vbo: c.GLuint = 0,
    ebo: c.GLuint = 0,
    z_val: f32 = 0.999,
    window: *c.SDL_Window,
    base_shader: ShaderData,
    text_shader: ShaderData,
    typesetter: *TypeSetter,
    renderer: *c.SDL_Renderer,
    gl_context: c.SDL_GLContext,
    allocator: *std.mem.Allocator,

    pub fn init(typesetter: *TypeSetter, camera: *Camera, allocator: *std.mem.Allocator, window_title: []const u8) !Self {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 16);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3); // OpenGL 3+
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3); // OpenGL 3.3
        const window = c.SDL_CreateWindow(window_title.ptr, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, @as(c_int, constants.DEFAULT_WINDOW_WIDTH * camera.window_scale), @as(c_int, constants.DEFAULT_WINDOW_HEIGHT * camera.window_scale), c.SDL_WINDOW_OPENGL).?;
        const gl_context = c.SDL_GL_CreateContext(window);
        _ = c.SDL_GL_MakeCurrent(window, gl_context);
        _ = c.gladLoadGLLoader(@ptrCast(c.GLADloadproc), @ptrCast(c.SDL_GL_GetProcAddress));
        var self = Self{
            .window = window,
            .renderer = undefined,
            .gl_context = gl_context,
            .allocator = allocator,
            .base_shader = ShaderData.init(allocator),
            .text_shader = ShaderData.init(allocator),
            .camera = camera,
            .typesetter = typesetter,
        };
        try self.init_gl();
        try self.init_main_texture();
        try self.init_text_renderer();
        self.typesetter.free_texture_data();
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.base_shader.deinit();
        self.text_shader.deinit();
        c.SDL_DestroyWindow(self.window);
    }

    fn init_gl(self: *Self) !void {
        c.glGenVertexArrays(1, &self.vao);
        c.glGenBuffers(1, &self.vbo);
        c.glGenBuffers(1, &self.ebo);
        c.glBindVertexArray(self.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(VertexData), null);
        c.glEnableVertexAttribArray(0);
        c.glVertexAttribPointer(1, 4, c.GL_FLOAT, c.GL_FALSE, @sizeOf(VertexData), @ptrFromInt(@offsetOf(VertexData, "color")));
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(VertexData), @ptrFromInt(@offsetOf(VertexData, "texCoord")));
        c.glEnableVertexAttribArray(2);
        try self.init_shader_program(VERTEX_BASE_FILE, FRAGMENT_ALPHA_FILE, &self.base_shader);
        try self.init_shader_program(VERTEX_BASE_FILE, FRAGMENT_ALPHA_FILE, &self.text_shader);
    }

    fn init_text_renderer(self: *Self) !void {
        c.glGenTextures(1, &self.text_shader.texture);
        c.glBindTexture(c.GL_TEXTURE_2D, self.text_shader.texture);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RED, FONT_TEX_SIZE, FONT_TEX_SIZE, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, &self.typesetter.texture_data[0]);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    }

    fn init_shader_program(self: *Self, vertex_src: []const u8, fragment_src: []const u8, shader_prog: *ShaderData) !void {
        _ = self;
        const fs: ?[*]const u8 = fragment_src.ptr;
        const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(fragment_shader, 1, &fs, null);
        c.glCompileShader(fragment_shader);
        var compile_success: c_int = undefined;
        c.glGetShaderiv(fragment_shader, c.GL_COMPILE_STATUS, &compile_success);
        if (compile_success == 0) {
            std.debug.print("Fragment shader compilation failed\n", .{});
            var compile_message: [1024]u8 = undefined;
            c.glGetShaderInfoLog(fragment_shader, 1024, null, &compile_message[0]);
            std.debug.print("{s}\n", .{compile_message});
            return error.FragmentSyntaxError;
        }

        var vs: ?[*]const u8 = vertex_src.ptr;
        const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(vertex_shader, 1, &vs, null);
        c.glCompileShader(vertex_shader);
        c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &compile_success);
        if (compile_success == 0) {
            std.debug.print("Vertex shader compilation failed\n", .{});
            var compile_message: [1024]u8 = undefined;
            c.glGetShaderInfoLog(vertex_shader, 1024, null, &compile_message[0]);
            std.debug.print("{s}\n", .{compile_message});
            return error.VertexSyntaxError;
        }

        shader_prog.program = c.glCreateProgram();
        c.glAttachShader(shader_prog.program, vertex_shader);
        c.glAttachShader(shader_prog.program, fragment_shader);
        c.glLinkProgram(shader_prog.program);
        c.glDeleteShader(vertex_shader);
        c.glDeleteShader(fragment_shader);
    }

    /// Generates a circle texture that is used to draw filled circles.
    fn init_main_texture(self: *Self) !void {
        const temp_bitmap = try self.allocator.alloc(u8, CIRCLE_TEXTURE_SIZE * CIRCLE_TEXTURE_SIZE);
        defer self.allocator.free(temp_bitmap);
        // Circle texture leaves one pixel at the 0,0 point as filled,
        // so all other fills can use that pixel.
        var i: usize = 0;
        var j: usize = 0;
        // First, temp_bitmap is initialized to 0.
        while (i < CIRCLE_TEXTURE_SIZE) : (i += 1) {
            j = 0;
            while (j < CIRCLE_TEXTURE_SIZE) : (j += 1) {
                temp_bitmap[(i * CIRCLE_TEXTURE_SIZE) + j] = 0;
            }
        }

        i = 1;
        temp_bitmap[0] = 255;
        const radius: usize = (CIRCLE_TEXTURE_SIZE - 1) / 2;
        const center = Vector2.from_usize(radius, radius);
        while (i < CIRCLE_TEXTURE_SIZE) : (i += 1) {
            j = 1;
            while (j < CIRCLE_TEXTURE_SIZE) : (j += 1) {
                const current = Vector2.from_usize(i - 1, j - 1);
                if (Vector2.distance(center, current) <= @as(f32, radius)) {
                    temp_bitmap[(i * CIRCLE_TEXTURE_SIZE) + j] = 255;
                } else {
                    temp_bitmap[(i * CIRCLE_TEXTURE_SIZE) + j] = 0;
                }
            }
        }

        c.glGenTextures(1, &self.base_shader.texture);
        c.glBindTexture(c.GL_TEXTURE_2D, self.base_shader.texture);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RED, CIRCLE_TEXTURE_SIZE, CIRCLE_TEXTURE_SIZE, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, &temp_bitmap[0]);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    }

    fn draw_buffers(self: *Self) void {
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
        self.draw_shader_buffers(&self.base_shader);
        self.fill_text_buffers();
        self.draw_shader_buffers(&self.text_shader);
    }

    fn draw_shader_buffers(self: *Self, shader: *ShaderData) void {
        c.glUseProgram(shader.program);
        c.glViewport(0, 0, @as(c_int, self.camera.window_size.x), @as(c_int, self.camera.window_size.y));
        c.glEnable(c.GL_BLEND);
        c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
        c.glUniform1i(c.glGetUniformLocation(shader.program, "tex"), 0);
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, shader.texture);
        c.glBindVertexArray(self.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        if (shader.triangle_verts.items.len > 0 and shader.indices.items.len > 0) {
            c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(VertexData) * @as(c_longlong, shader.triangle_verts.items.len), &shader.triangle_verts.items[0], c.GL_DYNAMIC_DRAW);
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
            c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(c_uint) * @as(c_longlong, shader.indices.items.len), &shader.indices.items[0], c.GL_DYNAMIC_DRAW);
            c.glDrawElements(c.GL_TRIANGLES, @as(c_int, shader.indices.items.len), c.GL_UNSIGNED_INT, null);
        }
    }

    /// Fills text buffers with character data from the typesetter.
    fn fill_text_buffers(self: *Self) void {
        var i: usize = 0;
        while (i < self.typesetter.glyphs.items.len) : (i += 1) {
            const glyph = self.typesetter.glyphs.items[i];
            const quad = glyph.quad;
            const color = glyph.color;
            const z = glyph.z;
            const p1 = self.screen_pixel_to_gl(.{ .x = quad.x0, .y = quad.y0 }, self.camera.render_size(), z);
            const p2 = self.screen_pixel_to_gl(.{ .x = quad.x1, .y = quad.y1 }, self.camera.render_size(), z);
            const base = @as(c_uint, self.text_shader.triangle_verts.items.len);
            self.text_shader.triangle_verts.append(.{ .position = p1, .texCoord = .{ .x = quad.s0, .y = quad.t0 }, .color = color }) catch unreachable;
            self.text_shader.triangle_verts.append(.{ .position = .{ .x = p2.x, .y = p1.y, .z = 1.0 }, .texCoord = .{ .x = quad.s1, .y = quad.t0 }, .color = color }) catch unreachable;
            self.text_shader.triangle_verts.append(.{ .position = p2, .texCoord = .{ .x = quad.s1, .y = quad.t1 }, .color = color }) catch unreachable;
            self.text_shader.triangle_verts.append(.{ .position = .{ .x = p1.x, .y = p2.y, .z = 1.0 }, .texCoord = .{ .x = quad.s0, .y = quad.t1 }, .color = color }) catch unreachable;
            const indices = [_]c_uint{ base + 0, base + 1, base + 3, base + 1, base + 2, base + 3 };
            self.text_shader.indices.appendSlice(indices[0..6]) catch unreachable;
        }
    }
};
