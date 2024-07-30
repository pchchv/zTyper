const c = @import("c.zig");
const helpers = @import("helpers.zig");

const NUM_FONTS = @typeInfo(FontType).Enum.fields.len;

const Vector4_gl = helpers.Vector4_gl;
const DEFAULT_FONT: FontType = .debug;

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

pub const FontType = enum {
    /// Font for debug purposes and things.
    debug,
    /// Font for large headers and such. Harder to read. Legible only at larger sizes.
    display,
    /// Font for large amounts of text. Easier to read. Legible at small sizes
    info,
};
