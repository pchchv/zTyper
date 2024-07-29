const std = @import("std");

pub fn lerpf(start: f32, end: f32, t: f32) f32 {
    return (start * (1.0 - t)) + (end * t);
}

pub fn unlerpf(start: f32, end: f32, t: f32) f32 {
    if ((end == t) or (end <= start)) {
        return 1.0;
    }
    return (t - start) / (end - start);
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
