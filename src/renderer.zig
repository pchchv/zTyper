const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const glyph_lib = @import("glyphee.zig");
const constants = @import("constants.zig");

const Camera = helpers.Camera;
const Vector2_gl = helpers.Vector2_gl;
const Vector3_gl = helpers.Vector3_gl;
const Vector4_gl = helpers.Vector4_gl;
const TypeSetter = glyph_lib.TypeSetter;

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
};
