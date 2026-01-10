//! List widget - scrollable list with selection.
//!
//! Displays a list of items with automatic scrolling
//! to keep the selected item visible.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const List = @This();

items: []const []const u8,
selected: usize = 0,
scroll_offset: usize = 0,
style: Style = .{},
selected_style: Style = Style.reverse(),
show_scrollbar: bool = true,

pub fn init(items: []const []const u8) List {
    return .{ .items = items };
}

pub fn withStyle(self: List, style: Style) List {
    var l = self;
    l.style = style;
    return l;
}

pub fn withSelectedStyle(self: List, style: Style) List {
    var l = self;
    l.selected_style = style;
    return l;
}

pub fn withScrollbar(self: List, show: bool) List {
    var l = self;
    l.show_scrollbar = show;
    return l;
}

pub fn draw(self: *List, screen: *Screen, area: Rect) void {
    if (area.isEmpty() or self.items.len == 0) return;

    const visible_height = area.height;
    const content_width = if (self.show_scrollbar and self.items.len > visible_height)
        area.width -| 1
    else
        area.width;

    // Draw items
    var y: u16 = 0;
    while (y < visible_height) : (y += 1) {
        const item_idx = self.scroll_offset + y;
        if (item_idx >= self.items.len) break;

        const is_selected = item_idx == self.selected;
        const style = if (is_selected) self.selected_style else self.style;

        screen.setStyle(style);

        const item = self.items[item_idx];
        const display_len = @min(item.len, content_width);
        screen.writeStr(area.x, area.y + y, item[0..display_len]);

        // Fill rest of line for full highlight
        if (is_selected) {
            var fill_x = area.x + @as(u16, @intCast(display_len));
            while (fill_x < area.x + content_width) : (fill_x += 1) {
                screen.setChar(fill_x, area.y + y, ' ');
            }
        }
    }

    // Draw scrollbar
    if (self.show_scrollbar and self.items.len > visible_height) {
        self.drawScrollbar(screen, area);
    }
}

fn drawScrollbar(self: *List, screen: *Screen, area: Rect) void {
    const scrollbar_x = area.right() - 1;
    const total_items = self.items.len;
    const visible = area.height;

    // Calculate thumb position and size
    const thumb_size = @max(1, (visible * visible) / @as(u16, @intCast(total_items)));
    const max_scroll = total_items - visible;
    const thumb_pos = if (max_scroll > 0)
        (self.scroll_offset * (visible - thumb_size)) / max_scroll
    else
        0;

    screen.setStyle(Style.dim());

    // Draw track
    var y: u16 = 0;
    while (y < area.height) : (y += 1) {
        const in_thumb = y >= thumb_pos and y < thumb_pos + thumb_size;
        const char: u21 = if (in_thumb) 0x2588 else 0x2591; // █ or ░
        screen.setChar(scrollbar_x, area.y + y, char);
    }
}

pub fn handleInput(self: *List, key: Widget.Key) Widget.HandleResult {
    switch (key) {
        .arrow_up => {
            if (self.selected > 0) {
                self.selected -= 1;
                self.ensureVisible();
            }
            return .consumed;
        },
        .arrow_down => {
            if (self.selected + 1 < self.items.len) {
                self.selected += 1;
                self.ensureVisible();
            }
            return .consumed;
        },
        .page_up => {
            if (self.selected > 10) {
                self.selected -= 10;
            } else {
                self.selected = 0;
            }
            self.ensureVisible();
            return .consumed;
        },
        .page_down => {
            self.selected = @min(self.selected + 10, self.items.len -| 1);
            self.ensureVisible();
            return .consumed;
        },
        .home => {
            self.selected = 0;
            self.ensureVisible();
            return .consumed;
        },
        .end => {
            if (self.items.len > 0) {
                self.selected = self.items.len - 1;
                self.ensureVisible();
            }
            return .consumed;
        },
        .char => |c| {
            if (c == 'k' or c == 'K') {
                if (self.selected > 0) {
                    self.selected -= 1;
                    self.ensureVisible();
                }
                return .consumed;
            } else if (c == 'j' or c == 'J') {
                if (self.selected + 1 < self.items.len) {
                    self.selected += 1;
                    self.ensureVisible();
                }
                return .consumed;
            }
            return .ignored;
        },
        else => return .ignored,
    }
}

fn ensureVisible(self: *List) void {
    // Assuming a default visible height of 10 for now
    // In practice, this would be set during draw
    const visible: usize = 10;

    if (self.selected < self.scroll_offset) {
        self.scroll_offset = self.selected;
    } else if (self.selected >= self.scroll_offset + visible) {
        self.scroll_offset = self.selected - visible + 1;
    }
}

pub fn minSize(self: *List) struct { width: u16, height: u16 } {
    var max_width: usize = 0;
    for (self.items) |item| {
        max_width = @max(max_width, item.len);
    }
    return .{
        .width = @intCast(@min(max_width + 1, std.math.maxInt(u16))), // +1 for scrollbar
        .height = @intCast(@min(self.items.len, 10)), // Default to max 10 visible
    };
}

pub fn getSelected(self: *List) usize {
    return self.selected;
}

pub fn getSelectedItem(self: *List) ?[]const u8 {
    if (self.selected < self.items.len) {
        return self.items[self.selected];
    }
    return null;
}

pub fn setSelected(self: *List, index: usize) void {
    if (index < self.items.len) {
        self.selected = index;
        self.ensureVisible();
    }
}
