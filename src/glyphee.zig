// All information about the text, etc. is stored here.
const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");

const Camera = helpers.Camera;
const Vector4_gl = helpers.Vector4_gl;

const NUM_FONTS = @typeInfo(FontType).Enum.fields.len;

const DEFAULT_FONT: FontType = .debug;

const GLYPH_CAPACITY = 2048;

const Glyph = struct {
    char: u8,
    font: FontType,
    color: Vector4_gl,
    quad: c.stbtt_aligned_quad,
    z: f32,
};

const GlyphData = struct {
    glyphs: [96 * NUM_FONTS]c.stbtt_bakedchar = undefined,
};

const FontData = struct {
    type_: FontType = DEFAULT_FONT,
    start_glyph_index: usize = 0,
    start_row: usize = 0,
    num_rows: usize = 0,
};

pub const FontType = enum {
    /// Font for debug purposes and things.
    debug,
    /// Font for large headers and such. Harder to read. Legible only at larger sizes.
    display,
    /// Font for large amounts of text. Easier to read. Legible at small sizes
    info,
};

pub const TypeSetter = struct {
    const Self = @This();
    glyph_data: GlyphData = .{},
    texture_data: []u8 = undefined,
    allocator: *std.mem.Allocator,
    glyphs: std.ArrayList(Glyph),
    camera: *const Camera,
    fonts_data: [NUM_FONTS]FontData = undefined,

    pub fn init(self: *Self, camera: *const Camera, allocator: *std.mem.Allocator) !void {
        self.allocator = allocator;
        self.camera = camera;
        self.glyphs = std.ArrayList(Glyph).initCapacity(self.allocator, GLYPH_CAPACITY) catch unreachable;
        try self.load_font_data();
    }

    pub fn deinit(self: *Self) void {
        self.glyphs.deinit();
    }

    pub fn reset(self: *Self) void {
        self.glyphs.shrinkRetainingCapacity(0);
    }
};
