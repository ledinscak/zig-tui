//! Widget interface for TUI components.
//!
//! All widgets implement this interface for consistent rendering
//! and input handling.

const terminal = @import("terminal");
const Screen = @import("../Screen.zig");
const Rect = @import("../Rect.zig");

pub const Key = terminal.Key;

/// Result of handling input
pub const HandleResult = enum {
    consumed, // Input was handled, stop propagation
    ignored, // Input was not handled, continue propagation
};

/// Widget interface via tagged union
pub const Widget = union(enum) {
    box: *@import("Box.zig"),
    text: *@import("Text.zig"),
    menu: *@import("Menu.zig"),
    list: *@import("List.zig"),
    text_input: *@import("TextInput.zig"),
    progress_bar: *@import("ProgressBar.zig"),
    table: *@import("Table.zig"),
    modal: *@import("Modal.zig"),

    pub fn draw(self: Widget, screen: *Screen, area: Rect) void {
        switch (self) {
            inline else => |w| w.draw(screen, area),
        }
    }

    pub fn handleInput(self: Widget, key: Key) HandleResult {
        switch (self) {
            inline else => |w| return w.handleInput(key),
        }
    }

    pub fn minSize(self: Widget) struct { width: u16, height: u16 } {
        switch (self) {
            inline else => |w| return w.minSize(),
        }
    }
};
