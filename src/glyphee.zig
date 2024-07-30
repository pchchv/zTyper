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

    fn load_font_data(self: *Self) !void {
        // Loads all fonts into one texture.
        self.texture_data = try self.allocator.alloc(u8, FONT_TEX_SIZE * FONT_TEX_SIZE);
        var row: usize = 0;
        var glyphs_used: usize = 0;
        var i: usize = 0;
        while (i < NUM_FONTS) : (i += 1) {
            const bitmap_index = row * FONT_TEX_SIZE;
            const glyph_index = glyphs_used;
            const num_rows_used = c.stbtt_BakeFontBitmap(FONT_FILES[i], 0, FONT_SIZE, &self.texture_data[bitmap_index], FONT_TEX_SIZE, FONT_TEX_SIZE - @as(c_int, row), 32, 96, &self.glyph_data.glyphs[glyph_index]);
            self.fonts_data[i].type_ = @enumFromInt(@as(u2, i));
            self.fonts_data[i].start_row = row;
            self.fonts_data[i].start_glyph_index = glyph_index;
            row += @as(usize, num_rows_used);
            glyphs_used += 96;
        }
    }
};
