//! Application framework for TUI programs.
//!
//! Manages the terminal lifecycle, event loop, and rendering.

const std = @import("std");
const terminal = @import("terminal");
const Screen = @import("Screen.zig");
const Style = @import("Style.zig");
const Rect = @import("Rect.zig");
const Widget = @import("widgets/Widget.zig");

const App = @This();

pub const Key = terminal.Key;

/// Application configuration
pub const Config = struct {
    /// Target frames per second (0 = render only on input)
    fps: u32 = 30,
    /// Show cursor
    show_cursor: bool = false,
};

allocator: std.mem.Allocator,
term: terminal.Terminal,
screen: Screen,
config: Config,
running: bool = false,
term_buffer: []u8,

/// User-provided callbacks
on_init: ?*const fn (*App) anyerror!void = null,
on_draw: ?*const fn (*App, *Screen, Rect) anyerror!void = null,
on_key: ?*const fn (*App, Key) anyerror!bool = null,
on_resize: ?*const fn (*App, u16, u16) anyerror!void = null,

/// User data pointer for custom state
user_data: ?*anyopaque = null,

pub fn init(allocator: std.mem.Allocator, config: Config) !App {
    // Allocate terminal buffer
    const term_buffer = try allocator.alloc(u8, 16384);
    var term = terminal.Terminal.init(term_buffer);

    // Get initial terminal size
    const term_size = try term.getSize();

    // Create screen buffer
    const screen = try Screen.init(allocator, term_size.width, term_size.height);

    return .{
        .allocator = allocator,
        .term = term,
        .screen = screen,
        .config = config,
        .term_buffer = term_buffer,
    };
}

pub fn deinit(self: *App) void {
    self.screen.deinit();
    self.allocator.free(self.term_buffer);
}

/// Convenience function to run an app with managed allocator.
///
/// This handles allocator setup, app initialization, and cleanup.
/// The setup function should set callbacks and call `app.start()`.
///
/// Example:
/// ```zig
/// pub fn main() !void {
///     try tui.App.run(setup, .{ .fps = 30 });
/// }
///
/// fn setup(app: *tui.App) !void {
///     app.setOnDraw(draw);
///     app.setOnKey(handleKey);
///     try app.start();
/// }
/// ```
pub fn run(comptime setup: fn (*App) anyerror!void, config: Config) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try App.init(allocator, config);
    defer app.deinit();

    try setup(&app);
}

/// Set the init callback
pub fn setOnInit(self: *App, callback: *const fn (*App) anyerror!void) void {
    self.on_init = callback;
}

/// Set the draw callback
pub fn setOnDraw(self: *App, callback: *const fn (*App, *Screen, Rect) anyerror!void) void {
    self.on_draw = callback;
}

/// Set the key handler callback (return true to continue, false to quit)
pub fn setOnKey(self: *App, callback: *const fn (*App, Key) anyerror!bool) void {
    self.on_key = callback;
}

/// Set the resize callback
pub fn setOnResize(self: *App, callback: *const fn (*App, u16, u16) anyerror!void) void {
    self.on_resize = callback;
}

/// Start the application main loop
pub fn start(self: *App) !void {
    try self.term.open();
    defer self.term.close();

    if (self.config.show_cursor) {
        try self.term.showCursor();
    }

    self.running = true;

    // Call init callback
    if (self.on_init) |init_cb| {
        try init_cb(self);
    }

    // Calculate frame timing
    const frame_ns: u64 = if (self.config.fps > 0)
        std.time.ns_per_s / self.config.fps
    else
        0;

    var last_frame = std.time.nanoTimestamp();

    while (self.running) {
        // Check for terminal resize
        if (self.term.getSize()) |new_size| {
            if (new_size.width != self.screen.width or new_size.height != self.screen.height) {
                try self.screen.resize(new_size.width, new_size.height);
                self.screen.invalidate();
                if (self.on_resize) |resize_cb| {
                    try resize_cb(self, new_size.width, new_size.height);
                }
            }
        } else |_| {}

        // Process input
        while (self.term.pollKey()) |key| {
            // Check for quit keys
            if (key == .escape) {
                self.running = false;
                break;
            }

            // Call user key handler
            if (self.on_key) |key_cb| {
                const should_continue = try key_cb(self, key);
                if (!should_continue) {
                    self.running = false;
                    break;
                }
            }
        }

        if (!self.running) break;

        // Draw
        const area = Rect.init(0, 0, self.screen.width, self.screen.height);
        self.screen.setStyle(.{});
        self.screen.clear();

        if (self.on_draw) |draw_cb| {
            try draw_cb(self, &self.screen, area);
        }

        try self.screen.render(&self.term);

        // Frame rate limiting
        if (frame_ns > 0) {
            const now = std.time.nanoTimestamp();
            const elapsed = now - last_frame;
            if (elapsed < frame_ns) {
                std.Thread.sleep(@intCast(frame_ns - @as(u64, @intCast(elapsed))));
            }
            last_frame = std.time.nanoTimestamp();
        } else {
            // If fps=0, just sleep a bit to avoid busy waiting
            std.Thread.sleep(16 * std.time.ns_per_ms);
        }
    }
}

/// Request application exit
pub fn quit(self: *App) void {
    self.running = false;
}

/// Get current screen dimensions
pub fn size(self: *App) struct { width: u16, height: u16 } {
    return .{ .width = self.screen.width, .height = self.screen.height };
}

/// Get typed user data
pub fn getUserData(self: *App, comptime T: type) ?*T {
    if (self.user_data) |ptr| {
        return @ptrCast(@alignCast(ptr));
    }
    return null;
}

/// Set user data
pub fn setUserData(self: *App, comptime T: type, data: *T) void {
    self.user_data = data;
}
