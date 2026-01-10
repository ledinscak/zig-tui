//! Menu widget - selectable list of options.
//!
//! Supports keyboard navigation and selection callbacks.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const Menu = @This();

pub const Item = struct {
    label: []const u8,
    enabled: bool = true,
};

items: []const Item,
selected: usize = 0,
style: Style = .{},
selected_style: Style = Style.reverse(),
disabled_style: Style = Style.dim(),
on_select: ?*const fn (usize) void = null,

pub fn init(items: []const Item) Menu {
    return .{ .items = items };
}

pub fn withStyle(self: Menu, style: Style) Menu {
    var m = self;
    m.style = style;
    return m;
}

pub fn withSelectedStyle(self: Menu, style: Style) Menu {
    var m = self;
    m.selected_style = style;
    return m;
}

pub fn withOnSelect(self: Menu, callback: *const fn (usize) void) Menu {
    var m = self;
    m.on_select = callback;
    return m;
}

pub fn draw(self: *Menu, screen: *Screen, area: Rect) void {
    if (area.isEmpty() or self.items.len == 0) return;

    var y = area.y;
    for (self.items, 0..) |item, i| {
        if (y >= area.bottom()) break;

        const is_selected = i == self.selected;
        const style = if (!item.enabled)
            self.disabled_style
        else if (is_selected)
            self.selected_style
        else
            self.style;

        screen.setStyle(style);

        // Draw selection indicator
        const indicator: []const u8 = if (is_selected) "> " else "  ";
        screen.writeStr(area.x, y, indicator);

        // Draw label
        const label_x = area.x + 2;
        const max_len = if (area.width > 2) area.width - 2 else 0;
        const display_len = @min(item.label.len, max_len);
        screen.writeStr(label_x, y, item.label[0..display_len]);

        // Fill rest of line for full highlight
        if (is_selected and area.width > 2 + display_len) {
            var fill_x = label_x + @as(u16, @intCast(display_len));
            while (fill_x < area.right()) : (fill_x += 1) {
                screen.setChar(fill_x, y, ' ');
            }
        }

        y += 1;
    }
}

pub fn handleInput(self: *Menu, key: Widget.Key) Widget.HandleResult {
    switch (key) {
        .arrow_up => {
            self.moveUp();
            return .consumed;
        },
        .arrow_down => {
            self.moveDown();
            return .consumed;
        },
        .enter => {
            if (self.on_select) |callback| {
                if (self.items[self.selected].enabled) {
                    callback(self.selected);
                }
            }
            return .consumed;
        },
        .char => |c| {
            if (c == 'k' or c == 'K') {
                self.moveUp();
                return .consumed;
            } else if (c == 'j' or c == 'J') {
                self.moveDown();
                return .consumed;
            }
            return .ignored;
        },
        else => return .ignored,
    }
}

fn moveUp(self: *Menu) void {
    if (self.items.len == 0) return;

    // Find previous enabled item
    var i = self.selected;
    while (i > 0) {
        i -= 1;
        if (self.items[i].enabled) {
            self.selected = i;
            return;
        }
    }
}

fn moveDown(self: *Menu) void {
    if (self.items.len == 0) return;

    // Find next enabled item
    var i = self.selected + 1;
    while (i < self.items.len) : (i += 1) {
        if (self.items[i].enabled) {
            self.selected = i;
            return;
        }
    }
}

pub fn minSize(self: *Menu) struct { width: u16, height: u16 } {
    var max_width: usize = 0;
    for (self.items) |item| {
        max_width = @max(max_width, item.label.len + 2); // +2 for "> "
    }
    return .{
        .width = @intCast(@min(max_width, std.math.maxInt(u16))),
        .height = @intCast(@min(self.items.len, std.math.maxInt(u16))),
    };
}

pub fn getSelected(self: *Menu) usize {
    return self.selected;
}

pub fn setSelected(self: *Menu, index: usize) void {
    if (index < self.items.len and self.items[index].enabled) {
        self.selected = index;
    }
}
