//! zig-tui: A terminal user interface library for Zig
//!
//! Built on top of zig-terminal, provides widgets and layout primitives
//! for building terminal-based applications.

// Re-export terminal for low-level access
pub const terminal = @import("terminal");

// Core types
pub const App = @import("App.zig");
pub const Screen = @import("Screen.zig");
pub const Style = @import("Style.zig");
pub const Rect = @import("Rect.zig");
pub const Color = Style.Color;

// Input
pub const Key = terminal.Key;

// Widgets
pub const widgets = struct {
    pub const Widget = @import("widgets/Widget.zig").Widget;
    pub const HandleResult = @import("widgets/Widget.zig").HandleResult;
    pub const Box = @import("widgets/Box.zig");
    pub const Text = @import("widgets/Text.zig");
    pub const Menu = @import("widgets/Menu.zig");
    pub const List = @import("widgets/List.zig");
    pub const TextInput = @import("widgets/TextInput.zig");
    pub const ProgressBar = @import("widgets/ProgressBar.zig");
    pub const Table = @import("widgets/Table.zig");
    pub const Modal = @import("widgets/Modal.zig");
};

// Convenience re-exports
pub const Box = widgets.Box;
pub const Text = widgets.Text;
pub const Menu = widgets.Menu;
pub const List = widgets.List;
pub const TextInput = widgets.TextInput;
pub const ProgressBar = widgets.ProgressBar;
pub const Table = widgets.Table;
pub const Modal = widgets.Modal;

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
