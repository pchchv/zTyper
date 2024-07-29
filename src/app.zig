const std = @import("std");
const helpers = @import("helpers.zig");
const EditableText = helpers.EditableText;
const TYPEROO_LINE_WIDTH = 66;
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

    pub fn init(self: *Self) !void {
        try self.typesetter.init(&self.camera, self.allocator);

        var buf: [TYPEROO_LINE_WIDTH]u8 = undefined;
        var i: usize = 0;
        while (i < TYPEROO_LINE_WIDTH) : (i += 1) buf[i] = 'a';
        self.total_line_width = self.typesetter.get_text_width_font(buf[0..], .debug).x;
        self.print_current_day();
    }

    pub fn deinit(self: *Self) void {
        self.save_note_to_file();
        self.typesetter.deinit();
        self.typed.deinit();
        self.lines.deinit();
    }
};
