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
};
