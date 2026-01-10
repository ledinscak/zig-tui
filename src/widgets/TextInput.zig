//! TextInput widget - single-line text input field.
//!
//! Supports cursor movement, character insertion/deletion,
//! and basic editing operations.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const TextInput = @This();

buffer: []u8,
len: usize = 0,
cursor: usize = 0,
scroll_offset: usize = 0,
style: Style = .{},
cursor_style: Style = Style.reverse(),
placeholder: ?[]const u8 = null,
placeholder_style: Style = Style.dim(),
focused: bool = true,
max_len: usize,

pub fn init(buffer: []u8) TextInput {
    return .{
        .buffer = buffer,
        .max_len = buffer.len,
    };
}

pub fn withStyle(self: TextInput, style: Style) TextInput {
    var t = self;
    t.style = style;
    return t;
}

pub fn withPlaceholder(self: TextInput, placeholder: []const u8) TextInput {
    var t = self;
    t.placeholder = placeholder;
    return t;
}

pub fn withFocused(self: TextInput, focused: bool) TextInput {
    var t = self;
    t.focused = focused;
    return t;
}

pub fn draw(self: *TextInput, screen: *Screen, area: Rect) void {
    if (area.isEmpty()) return;

    const width = area.width;

    // Adjust scroll to keep cursor visible
    if (self.cursor < self.scroll_offset) {
        self.scroll_offset = self.cursor;
    } else if (self.cursor >= self.scroll_offset + width) {
        self.scroll_offset = self.cursor - width + 1;
    }

    // Draw content or placeholder
    if (self.len == 0 and self.placeholder != null and !self.focused) {
        screen.setStyle(self.placeholder_style);
        const display_len = @min(self.placeholder.?.len, width);
        screen.writeStr(area.x, area.y, self.placeholder.?[0..display_len]);
    } else {
        screen.setStyle(self.style);

        // Draw visible portion of text
        const visible_start = self.scroll_offset;
        const visible_end = @min(self.len, self.scroll_offset + width);

        if (visible_end > visible_start) {
            screen.writeStr(area.x, area.y, self.buffer[visible_start..visible_end]);
        }

        // Draw cursor
        if (self.focused) {
            const cursor_screen_pos = self.cursor - self.scroll_offset;
            if (cursor_screen_pos < width) {
                screen.setStyle(self.cursor_style);
                const cursor_char: u21 = if (self.cursor < self.len)
                    self.buffer[self.cursor]
                else
                    ' ';
                screen.setChar(area.x + @as(u16, @intCast(cursor_screen_pos)), area.y, cursor_char);
            }
        }
    }
}

pub fn handleInput(self: *TextInput, key: Widget.Key) Widget.HandleResult {
    if (!self.focused) return .ignored;

    switch (key) {
        .char => |c| {
            if (c >= 32 and c < 127) { // Printable ASCII
                self.insertChar(c);
                return .consumed;
            }
            return .ignored;
        },
        .backspace => {
            self.deleteBackward();
            return .consumed;
        },
        .delete => {
            self.deleteForward();
            return .consumed;
        },
        .arrow_left => {
            if (self.cursor > 0) {
                self.cursor -= 1;
            }
            return .consumed;
        },
        .arrow_right => {
            if (self.cursor < self.len) {
                self.cursor += 1;
            }
            return .consumed;
        },
        .home => {
            self.cursor = 0;
            return .consumed;
        },
        .end => {
            self.cursor = self.len;
            return .consumed;
        },
        else => return .ignored,
    }
}

fn insertChar(self: *TextInput, c: u8) void {
    if (self.len >= self.max_len) return;

    // Shift characters right
    var i = self.len;
    while (i > self.cursor) : (i -= 1) {
        self.buffer[i] = self.buffer[i - 1];
    }

    self.buffer[self.cursor] = c;
    self.len += 1;
    self.cursor += 1;
}

fn deleteBackward(self: *TextInput) void {
    if (self.cursor == 0) return;

    // Shift characters left
    var i = self.cursor - 1;
    while (i < self.len - 1) : (i += 1) {
        self.buffer[i] = self.buffer[i + 1];
    }

    self.len -= 1;
    self.cursor -= 1;
}

fn deleteForward(self: *TextInput) void {
    if (self.cursor >= self.len) return;

    // Shift characters left
    var i = self.cursor;
    while (i < self.len - 1) : (i += 1) {
        self.buffer[i] = self.buffer[i + 1];
    }

    self.len -= 1;
}

pub fn minSize(_: *TextInput) struct { width: u16, height: u16 } {
    return .{ .width = 10, .height = 1 };
}

pub fn getText(self: *TextInput) []const u8 {
    return self.buffer[0..self.len];
}

pub fn setText(self: *TextInput, text: []const u8) void {
    const copy_len = @min(text.len, self.max_len);
    @memcpy(self.buffer[0..copy_len], text[0..copy_len]);
    self.len = copy_len;
    self.cursor = copy_len;
}

pub fn clear(self: *TextInput) void {
    self.len = 0;
    self.cursor = 0;
    self.scroll_offset = 0;
}

pub fn setFocused(self: *TextInput, focused: bool) void {
    self.focused = focused;
}
