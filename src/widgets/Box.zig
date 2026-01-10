//! Box widget - a bordered container.
//!
//! Draws a border around content with optional title.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const Box = @This();

/// Border style
pub const BorderStyle = enum {
    none,
    single,
    double,
    rounded,
    heavy,
    ascii,

    pub fn chars(self: BorderStyle) ?Screen.BoxChars {
        return switch (self) {
            .none => null,
            .single => Screen.BoxChars.single,
            .double => Screen.BoxChars.double,
            .rounded => Screen.BoxChars.rounded,
            .heavy => Screen.BoxChars.heavy,
            .ascii => Screen.BoxChars.ascii,
        };
    }
};

title: ?[]const u8 = null,
border: BorderStyle = .single,
style: Style = .{},
title_style: ?Style = null,
fill_char: u21 = ' ',
child: ?Widget.Widget = null,

pub fn init() Box {
    return .{};
}

pub fn withTitle(self: Box, title: []const u8) Box {
    var b = self;
    b.title = title;
    return b;
}

pub fn withBorder(self: Box, border: BorderStyle) Box {
    var b = self;
    b.border = border;
    return b;
}

pub fn withStyle(self: Box, style: Style) Box {
    var b = self;
    b.style = style;
    return b;
}

pub fn withTitleStyle(self: Box, style: Style) Box {
    var b = self;
    b.title_style = style;
    return b;
}

pub fn withChild(self: Box, child: Widget.Widget) Box {
    var b = self;
    b.child = child;
    return b;
}

pub fn draw(self: *Box, screen: *Screen, area: Rect) void {
    if (area.isEmpty()) return;

    // Fill background
    screen.setStyle(self.style);
    screen.fill(area, self.fill_char);

    // Draw border
    if (self.border.chars()) |chars| {
        screen.box(area, chars);

        // Draw title if present
        if (self.title) |title| {
            if (area.width > 4) {
                const title_style = self.title_style orelse self.style.withBold();
                const max_len = area.width - 4;
                const display_len = @min(title.len, max_len);
                const title_x = area.x + 2;

                screen.setStyle(title_style);
                screen.writeStr(title_x, area.y, title[0..display_len]);
                screen.setStyle(self.style);
            }
        }
    }

    // Draw child in inner area
    if (self.child) |child| {
        const inner = if (self.border != .none)
            area.shrink(1)
        else
            area;
        child.draw(screen, inner);
    }
}

pub fn handleInput(self: *Box, key: Widget.Key) Widget.HandleResult {
    if (self.child) |child| {
        return child.handleInput(key);
    }
    return .ignored;
}

pub fn minSize(self: *Box) struct { width: u16, height: u16 } {
    const border_size: u16 = if (self.border != .none) 2 else 0;
    if (self.child) |child| {
        const child_size = child.minSize();
        return .{
            .width = child_size.width + border_size,
            .height = child_size.height + border_size,
        };
    }
    return .{ .width = border_size, .height = border_size };
}
