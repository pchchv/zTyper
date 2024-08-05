const std = @import("std");
const c = @import("c.zig");
const App = @import("app.zig").App;

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

    var loading_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    loading_arena.deinit();

    var app = App.new(&gpa.allocator, &loading_arena.allocator);
    try app.init();
    defer app.deinit();

    var event: c.SDL_Event = undefined;
    while (!app.quit) {
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => app.quit = true,
                else => app.handle_inputs(event),
            }
        }
    }
}
