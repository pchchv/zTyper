const std = @import("std");
const helpers = @import("helpers.zig");
const EditableText = helpers.EditableText;
const Line = struct {
    start: usize = 0,
    end: usize = 0,
};

pub const App = struct {
    const Self = @This();
    typed: EditableText,

    pub fn new(allocator: *std.mem.Allocator, arena: *std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .arena = arena,
            .typed = EditableText.init(allocator),
            .lines = std.ArrayList(Line).init(allocator),
        };
    }
};
