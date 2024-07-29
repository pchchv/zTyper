const std = @import("std");
const c = @import("c.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }

    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const start_ticks = c.SDL_GetTicks();
    const init_ticks = c.SDL_GetTicks();
    std.debug.print("app init complete in {d} ticks\n", .{init_ticks - start_ticks});
}
