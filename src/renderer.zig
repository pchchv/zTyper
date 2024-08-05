const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");

const Vector2_gl = helpers.Vector2_gl;
const Vector3_gl = helpers.Vector3_gl;
const Vector4_gl = helpers.Vector4_gl;

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
