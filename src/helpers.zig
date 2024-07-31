const std = @import("std");
const c = @import("c.zig");

pub const PI = std.math.pi;
pub const HALF_PI = PI / 2.0;
pub const TWO_PI = PI * 2.0;

pub fn lerpf(start: f32, end: f32, t: f32) f32 {
    return (start * (1.0 - t)) + (end * t);
}

pub fn unlerpf(start: f32, end: f32, t: f32) f32 {
    if ((end == t) or (end <= start)) {
        return 1.0;
    }
    return (t - start) / (end - start);
}

pub fn is_nanf(f: f32) bool {
    return f != f;
}

pub fn easeinoutf(start: f32, end: f32, t: f32) f32 {
    return start + ((end - start) * (t * t * (3.0 - (2.0 * t))));
}

pub const Vector2 = struct {
    const Self = @This();
    x: f32 = 0.0,
    y: f32 = 0.0,

    pub fn lerp(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
        };
    }

    /// Suppose that v lies along the line v1-v2 (may be outside the segment).
    /// Then do not check both x and y unlerp.
    /// Just return the first value found.
    pub fn unlerp(v1: Vector2, v2: Vector2, v: Vector2) f32 {
        if (v1.x != v2.x) {
            return unlerpf(v1.x, v2.x, v.x);
        } else if (v1.y != v2.y) {
            return unlerpf(v1.y, v2.y, v.y);
        }
        return 0;
    }

    pub fn ease(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = easeinoutf(v1.x, v2.x, t),
            .y = easeinoutf(v1.y, v2.y, t),
        };
    }

    pub fn add(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
        };
    }

    pub fn added(v1: *const Vector2, v2: Vector2) Vector2 {
        return Vector2.add(v1.*, v2);
    }

    pub fn add3(v1: Vector2, v2: Vector2, v3: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x + v3.x,
            .y = v1.y + v2.y + v3.y,
        };
    }

    pub fn subtract(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
        };
    }

    pub fn distance(v1: Vector2, v2: Vector2) f32 {
        return @sqrt(((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y)));
    }

    pub fn distance_sqr(v1: Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn distance_to_sqr(v1: *const Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn length(v1: Vector2) f32 {
        return @sqrt((v1.x * v1.x) + (v1.y * v1.y));
    }

    pub fn length_sqr(v1: Vector2) f32 {
        return (v1.x * v1.x) + (v1.y * v1.y);
    }

    pub fn scale(v1: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scaled(v1: *const Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scale_anchor(v1: *const Vector2, anchor: Vector2, f: f32) Vector2 {
        const translated = Vector2.subtract(v1.*, anchor);
        return Vector2.add(anchor, Vector2.scale(translated, f));
    }

    pub fn scale_vec(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x * v2.x,
            .y = v1.y * v2.y,
        };
    }

    pub fn negated(v1: *const Vector2) Vector2 {
        return Vector2{
            .x = -v1.x,
            .y = -v1.y,
        };
    }

    pub fn subtract_half(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - (0.5 * v2.x),
            .y = v1.y - (0.5 * v2.y),
        };
    }

    pub fn rotate(v: Vector2, a: f32) Vector2 {
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    pub fn rotate_deg(v: Vector2, d: f32) Vector2 {
        const a = d * std.math.pi / 180.0;
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    pub fn rotate_about_point(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn rotate_about_point_deg(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate_deg(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn normalize(v1: Vector2) Vector2 {
        const l = Vector2.length(v1);
        return Vector2{
            .x = v1.x / l,
            .y = v1.y / l,
        };
    }

    /// Gives the angle in radians clockwise from the first vector to the second vector.
    /// Assumes that the vectors are normalized.
    pub fn angle_cw(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!v1.is_nan());
        std.debug.assert(!v2.is_nan());
        const dot_product = std.math.clamp(Vector2.dot(v1, v2), -1, 1);
        var a = std.math.acos(dot_product);
        std.debug.assert(!is_nanf(a));
        const winding = Vector2.cross_z(v1, v2);
        std.debug.assert(!is_nanf(winding));
        if (winding < 0) a = TWO_PI - a;
        return a;
    }

    pub fn equals(v1: Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn is_equal(v1: *const Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn is_zero(v1: *const Vector2) bool {
        return v1.x == 0 and v1.y == 0;
    }

    pub fn is_nan(v1: *const Vector2) bool {
        return is_nanf(v1.x) or is_nanf(v1.y);
    }

    pub fn dot(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!is_nanf(v1.x));
        std.debug.assert(!is_nanf(v1.y));
        std.debug.assert(!is_nanf(v2.x));
        std.debug.assert(!is_nanf(v2.y));
        return v1.x * v2.x + v1.y * v2.y;
    }

    /// Returns the z element of the 3d cross product of two vectors.
    /// Used to determine the winding of points.
    pub fn cross_z(v1: Vector2, v2: Vector2) f32 {
        return (v1.x * v2.y) - (v1.y * v2.x);
    }

    pub fn from_int(x: i32, y: i32) Vector2 {
        return Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
    }

    pub fn from_usize(x: usize, y: usize) Vector2 {
        return Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
    }

    /// Returns what value of point p if we have a line v1-v2,
    /// where v1 is 0 and v2 is 1.
    /// It is assumed that p lies along the line.
    pub fn get_fraction(v1: Vector2, v2: Vector2, p: Vector2) f32 {
        const len = Vector2.distance(v1, v2);
        const p_len = Vector2.distance(v1, p);
        return p_len / len;
    }

    pub fn get_perp(v1: Vector2, v2: Vector2) Vector2 {
        const line = Vector2.subtract(v2, v1);
        const perp = Vector2.normalize(Vector2{ .x = line.y, .y = -line.x });
        return perp;
    }

    /// Perhaps it can be done without normalization.
    pub fn reflect(v1: Vector2, surface: Vector2) Vector2 {
        // Since we are reflected from the surface,
        // we first need to find the component v1 perpendicular to the surface.
        // Then we need to reverse this component.
        // Or we can simply subtract twice the negative value of this component from v1.
        const n_surf = Vector2.normalize(surface);
        const v1_par = Vector2.scale(n_surf, Vector2.dot(v1, n_surf));
        const v1_perp = Vector2.subtract(v1, v1_par);
        return Vector2.subtract(v1, Vector2.scale(v1_perp, 2.0));
    }
};

pub const EditableText = struct {
    const Self = @This();
    text: std.ArrayList(u8),
    is_active: bool = false,
    position: Vector2 = .{},
    size: Vector2 = .{ .x = 300 },
    cursor_index: usize = 0,

    pub fn init(allocator: *std.mem.Allocator) Self {
        return Self{
            .text = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.text.deinit();
    }

    pub fn set_text(self: *Self, str: []const u8) void {
        self.text.shrinkRetainingCapacity(0);
        self.text.appendSlice(str) catch unreachable;
        self.cursor_index = str.len;
    }

    pub fn handle_inputs(self: *Self, keys: []u8) void {
        for (keys) |k| {
            switch (k) {
                8 => {
                    if (self.cursor_index > 0) {
                        _ = self.text.orderedRemove(self.cursor_index - 1);
                        self.cursor_index -= 1;
                    }
                },
                127 => {
                    if (self.cursor_index < self.text.items.len) {
                        _ = self.text.orderedRemove(self.cursor_index);
                    }
                },
                128 => {
                    if (self.cursor_index > 0) {
                        self.cursor_index -= 1;
                    }
                },
                129 => {
                    if (self.cursor_index < self.text.items.len) {
                        self.cursor_index += 1;
                    }
                },
                else => {
                    self.text.insert(self.cursor_index, k) catch unreachable;
                    self.cursor_index += 1;
                },
            }
        }
    }
};

pub const Vector2_gl = extern struct {
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
};

pub const Vector3_gl = extern struct {
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
    z: c.GLfloat = 0.0,
};
