//! Text widget - displays static or dynamic text.
//!
//! Supports text alignment and styling.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const Text = @This();

pub const Alignment = enum {
    left,
    center,
    right,
};

content: []const u8,
style: Style = .{},
alignment: Alignment = .left,

pub fn init(content: []const u8) Text {
    return .{ .content = content };
}

pub fn withStyle(self: Text, style: Style) Text {
    var t = self;
    t.style = style;
    return t;
}

pub fn withAlignment(self: Text, alignment: Alignment) Text {
    var t = self;
    t.alignment = alignment;
    return t;
}

pub fn centered(content: []const u8) Text {
    return Text{
        .content = content,
        .alignment = .center,
    };
}

pub fn draw(self: *Text, screen: *Screen, area: Rect) void {
    if (area.isEmpty()) return;

    screen.setStyle(self.style);

    // Split content into lines
    var lines = std.mem.splitScalar(u8, self.content, '\n');
    var y = area.y;

    while (lines.next()) |line| {
        if (y >= area.bottom()) break;

        const display_len: u16 = @intCast(@min(line.len, area.width));
        const x = switch (self.alignment) {
            .left => area.x,
            .center => area.x + (area.width -| display_len) / 2,
            .right => area.x + area.width -| display_len,
        };

        screen.writeStr(x, y, line[0..display_len]);
        y += 1;
    }
}

pub fn handleInput(_: *Text, _: Widget.Key) Widget.HandleResult {
    return .ignored;
}

pub fn minSize(self: *Text) struct { width: u16, height: u16 } {
    var max_width: usize = 0;
    var height: usize = 0;

    var lines = std.mem.splitScalar(u8, self.content, '\n');
    while (lines.next()) |line| {
        max_width = @max(max_width, line.len);
        height += 1;
    }

    return .{
        .width = @intCast(@min(max_width, std.math.maxInt(u16))),
        .height = @intCast(@min(height, std.math.maxInt(u16))),
    };
}
