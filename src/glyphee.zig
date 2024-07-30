// All information about the text, etc. is stored here.
const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");

const Camera = helpers.Camera;
const Vector2 = helpers.Vector2;
const Vector4_gl = helpers.Vector4_gl;

const NUM_FONTS = @typeInfo(FontType).Enum.fields.len;
const DISPLAY_FONT_FILE = @embedFile("../data/fonts/Leander/Leander.ttf");
const INFO_FONT_FILE = @embedFile("../data/fonts/Goudy/goudy_bookletter_1911.otf");
const DEBUG_FONT_FILE = @embedFile("../data/fonts/JetBrainsMono/ttf/JetBrainsMono-Light.ttf");

const DEFAULT_FONT: FontType = .debug;
const BLACK: Vector4_gl = .{ .x = 24.0 / 255.0, .y = 24.0 / 255.0, .z = 24.0 / 255.0, .w = 1.0 };

const GLYPH_CAPACITY = 2048;

pub const FONT_TEX_SIZE = 512;
pub const FONT_SIZE = 24.0;

const FONT_FILES = [NUM_FONTS][:0]const u8{
    DEBUG_FONT_FILE,
    DISPLAY_FONT_FILE,
    INFO_FONT_FILE,
};

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

    pub fn get_char_offset(self: *Self, char: u8) Vector2 {
        return self.get_char_offset_font(char, DEFAULT_FONT);
    }

    pub fn get_char_offset_font(self: *Self, char: u8, font: FontType) Vector2 {
        const glyph = self.get_char_glyph(char, font);
        return Vector2{ .x = glyph.xadvance };
    }

    pub fn draw_char_world(self: *Self, pos: Vector2, char: u8) Vector2 {
        return self.draw_char(self.camera.world_pos_to_screen(pos), char, self.camera);
    }

    pub fn draw_char(self: *Self, pos: Vector2, char: u8, camera: *const Camera) Vector2 {
        return self.draw_char_color(pos, char, 0.9, camera, BLACK);
    }

    pub fn draw_char_color(self: *Self, pos: Vector2, char: u8, z: f32, camera: *const Camera, color: Vector4_gl) Vector2 {
        return self.draw_char_color_font(pos, char, z, camera, color, DEFAULT_FONT);
    }

    pub fn draw_char_color_font(self: *Self, pos: Vector2, char: u8, z: f32, camera: *const Camera, color: Vector4_gl, font: FontType) Vector2 {
        _ = camera;
        const font_data = self.fonts_data[@intFromEnum(font)];
        const glyph = self.get_char_glyph(char, font);
        const inv_tex_width = 1.0 / @as(f32, FONT_TEX_SIZE);
        const inv_tex_height = 1.0 / @as(f32, FONT_TEX_SIZE - font_data.start_row);
        const round_x = @floor((pos.x + glyph.xoff) + 0.5);
        const round_y = @floor((pos.y + glyph.yoff) + 0.5);
        var quad: c.stbtt_aligned_quad = .{
            .x0 = round_x,
            .y0 = round_y,
            .x1 = round_x + @as(f32, glyph.x1 - glyph.x0),
            .y1 = round_y + @as(f32, glyph.y1 - glyph.y0),
            .s0 = @as(f32, glyph.x0) * inv_tex_width,
            .t0 = @as(f32, glyph.y0) * inv_tex_height,
            .s1 = @as(f32, glyph.x1) * inv_tex_width,
            .t1 = @as(f32, glyph.y1) * inv_tex_height,
        };
        quad.t0 = helpers.tex_remap(quad.t0, (FONT_TEX_SIZE - font_data.start_row), font_data.start_row);
        quad.t1 = helpers.tex_remap(quad.t1, (FONT_TEX_SIZE - font_data.start_row), font_data.start_row);
        const new_glyph = Glyph{
            .char = char,
            .color = color,
            .font = font,
            .quad = quad,
            .z = z,
        };
        self.glyphs.append(new_glyph) catch unreachable;
        return Vector2{ .x = glyph.xadvance };
    }

    pub fn draw_text_world(self: *Self, pos: Vector2, text: []const u8) void {
        self.draw_text_world_font(pos, text, DEFAULT_FONT);
    }

    pub fn draw_text_world_font(self: *Self, pos: Vector2, text: []const u8, font: FontType) void {
        self.draw_text_width_font(self.camera.world_pos_to_screen(pos), text, self.camera, 1000000.0, font);
    }

    pub fn draw_text_world_font_color(self: *Self, pos: Vector2, text: []const u8, font: FontType, color: Vector4_gl) void {
        self.draw_text_width_color_font(pos, text, self.camera, 1000000.0, color, font);
    }

    pub fn draw_text_world_centered(self: *Self, pos: Vector2, text: []const u8) void {
        self.draw_text_world_centered_font(pos, text, DEFAULT_FONT);
    }

    pub fn draw_text_world_centered_font(self: *Self, pos: Vector2, text: []const u8, font: FontType) void {
        self.draw_text_world_centered_font_color(pos, text, font, BLACK);
    }

    pub fn draw_text_width_world(self: *Self, pos: Vector2, text: []const u8, width: f32) void {
        self.draw_text_width(self.camera.world_pos_to_screen(pos), text, self.camera, width);
    }

    pub fn draw_text_width_camera(self: *Self, pos: Vector2, text: []const u8, width: f32, camera: *const Camera) void {
        self.draw_text_width(camera.world_pos_to_screen(pos), text, camera, width);
    }

    pub fn draw_text_width_world_color(self: *Self, pos: Vector2, text: []const u8, width: f32, color: Vector4_gl) void {
        self.draw_text_width_color(self.camera.world_pos_to_screen(pos), text, self.camera, width, color);
    }

    pub fn draw_text(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera) void {
        self.draw_text_width(pos, text, camera, 1000000.0);
    }

    pub fn draw_text_width(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32) void {
        self.draw_text_width_font(pos, text, camera, width, DEFAULT_FONT);
    }

    pub fn draw_text_width_font_world(self: *Self, pos: Vector2, text: []const u8, width: f32, font: FontType) void {
        self.draw_text_width_color_font(self.camera.world_pos_to_screen(pos), text, self.camera, width, BLACK, font);
    }

    pub fn draw_text_width_font(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, font: FontType) void {
        self.draw_text_width_color_font(pos, text, camera, width, BLACK, font);
    }

    pub fn draw_text_width_color(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, color: Vector4_gl) void {
        self.draw_text_width_color_font(pos, text, camera, width, color, DEFAULT_FONT);
    }

    pub fn draw_text_world_centered_font_color(self: *Self, pos: Vector2, text: []const u8, font: FontType, color: Vector4_gl) void {
        const width = self.get_text_width_font(text, font);
        const c_pos = Vector2.subtract(pos, width.scaled(0.5));
        self.draw_text_world_font_color(c_pos, text, font, color);
    }

    pub fn draw_text_width_color_font(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, color: Vector4_gl, font: FontType) void {
        var offsets = Vector2{};
        var new_line = false;
        for (text) |char| {
            const char_offset = self.draw_char_color_font(Vector2.add(pos, offsets), char, 1, camera, color, font);
            offsets = Vector2.add(offsets, char_offset);
            if (offsets.x > width) new_line = true;
            if (new_line and char == ' ') {
                offsets.x = 0.0;
                offsets.y += FONT_SIZE * 1.2;
                new_line = false;
            }
        }
    }
};
