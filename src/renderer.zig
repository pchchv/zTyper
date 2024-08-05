const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const glyph_lib = @import("glyphee.zig");

const Camera = helpers.Camera;
const Vector2_gl = helpers.Vector2_gl;
const Vector3_gl = helpers.Vector3_gl;
const Vector4_gl = helpers.Vector4_gl;
const TypeSetter = glyph_lib.TypeSetter;

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
};
