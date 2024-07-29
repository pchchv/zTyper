const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");

const EditableText = helpers.EditableText;

const TYPEROO_LINE_WIDTH = 66;
const TYPEROO_NUM_BACKSPACE = 8;

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

    fn backspace_allowed(self: *Self) bool {
        return self.backspace_used < TYPEROO_NUM_BACKSPACE;
    }

    fn check_backspace(self: *Self, event: c.SDL_Event) bool {
        if (!self.backspace_allowed()) return false;
        const name = c.SDL_GetKeyName(event.key.keysym.sym);
        var len: usize = 0;
        while (name[len] != 0) : (len += 1) {}
        if (len == 0) return false;
        if (std.mem.eql(u8, name[0..len], "Backspace")) {
            return true;
        }
        return false;
    }

    fn print_current_day(self: *Self) void {
        _ = self;
        const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(u64) };
        const epoch_day = epoch_seconds.getEpochDay();
        const year_day = epoch_day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();
        std.debug.print("Year: {d}, Month: {d}, Day: {d}\n", .{ year_day.year, @intFromEnum(month_day.month), month_day.day_index + 1 });
    }
};
