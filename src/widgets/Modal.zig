//! Modal dialog widget.
//!
//! A centered dialog box with title, content, buttons, and optional icon.
//! Supports keyboard navigation and action callbacks.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const Modal = @This();

/// Icon types for modal dialogs
pub const Icon = union(enum) {
    none,
    info,
    warning,
    @"error",
    question,
    success,
    custom: u21, // Custom unicode character

    /// Get the unicode character for this icon
    pub fn char(self: Icon) ?u21 {
        return switch (self) {
            .none => null,
            .info => 0x1F4A1, // 💡 light bulb
            .warning => 0x26A0, // ⚠ warning sign (use with variation selector for emoji)
            .@"error" => 0x26D4, // ⛔ no entry
            .question => 0x2754, // ❔ white question mark
            .success => 0x1F389, // 🎉 party popper
            .custom => |c| c,
        };
    }

    /// Get the default style color for this icon type
    pub fn defaultStyle(self: Icon) Style {
        return switch (self) {
            .none => .{},
            .info => Style.fg(Style.Color.blue).withBold(),
            .warning => Style.fg(Style.Color.yellow).withBold(),
            .@"error" => Style.fg(Style.Color.red).withBold(),
            .question => Style.fg(Style.Color.cyan).withBold(),
            .success => Style.fg(Style.Color.green).withBold(),
            .custom => Style.bold(),
        };
    }

    /// Check if icon needs variation selector (U+FE0F) for emoji presentation
    pub fn needsVariationSelector(self: Icon) bool {
        return switch (self) {
            .warning => true, // ⚠ needs FE0F for ⚠️
            else => false,
        };
    }

    /// Get display width of icon (1 for narrow, 2 for wide emojis)
    pub fn displayWidth(self: Icon) u16 {
        // Explicit widths for known icon types
        return switch (self) {
            .none => 0,
            .info => 2, // 💡
            .warning => 2, // ⚠️
            .@"error" => 2, // ⛔
            .question => 2, // ❔
            .success => 2, // 🎉
            .custom => |c| {
                // Estimate width for custom icons
                if (c >= 0x1F300) return 2; // Emoji block
                if (c >= 0x2600 and c <= 0x27BF) return 2; // Misc symbols
                return 1;
            },
        };
    }
};

/// Button definition
pub const Button = struct {
    label: []const u8,
    key: ?u8 = null, // Optional hotkey (first letter by default)
};

/// Common button presets
pub const Buttons = struct {
    pub const ok = &[_]Button{.{ .label = "OK", .key = 'o' }};
    pub const ok_cancel = &[_]Button{
        .{ .label = "OK", .key = 'o' },
        .{ .label = "Cancel", .key = 'c' },
    };
    pub const yes_no = &[_]Button{
        .{ .label = "Yes", .key = 'y' },
        .{ .label = "No", .key = 'n' },
    };
    pub const yes_no_cancel = &[_]Button{
        .{ .label = "Yes", .key = 'y' },
        .{ .label = "No", .key = 'n' },
        .{ .label = "Cancel", .key = 'c' },
    };
    pub const retry_cancel = &[_]Button{
        .{ .label = "Retry", .key = 'r' },
        .{ .label = "Cancel", .key = 'c' },
    };
    pub const save_discard_cancel = &[_]Button{
        .{ .label = "Save", .key = 's' },
        .{ .label = "Discard", .key = 'd' },
        .{ .label = "Cancel", .key = 'c' },
    };
};

/// Result of modal action
pub const Result = enum {
    none, // No action taken
    confirmed, // First button pressed (OK/Yes/etc.)
    cancelled, // Escape or Cancel button
    button, // Specific button pressed - check selected_button
};

title: []const u8 = "",
content: []const u8 = "",
buttons: []const Button = Buttons.ok,
selected_button: usize = 0,

// Icon
icon: Icon = .none,
icon_style: ?Style = null, // null means use icon's default style

// Styling
box_style: Screen.BoxChars = Screen.BoxChars.rounded,
title_style: Style = Style.bold(),
content_style: Style = .{},
button_style: Style = .{},
button_selected_style: Style = Style.reverse(),
border_style: Style = .{},
shadow: bool = true,

// Size constraints
min_width: u16 = 20,
max_width: u16 = 60,
padding: u16 = 1,

// Callbacks
on_result: ?*const fn (Result, usize) void = null,

pub fn init(title: []const u8, content: []const u8) Modal {
    return .{
        .title = title,
        .content = content,
    };
}

pub fn withButtons(self: Modal, buttons: []const Button) Modal {
    var m = self;
    m.buttons = buttons;
    return m;
}

pub fn withBoxStyle(self: Modal, box_style: Screen.BoxChars) Modal {
    var m = self;
    m.box_style = box_style;
    return m;
}

pub fn withTitleStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.title_style = style;
    return m;
}

pub fn withContentStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.content_style = style;
    return m;
}

pub fn withButtonStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.button_style = style;
    return m;
}

pub fn withButtonSelectedStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.button_selected_style = style;
    return m;
}

pub fn withBorderStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.border_style = style;
    return m;
}

pub fn withShadow(self: Modal, shadow: bool) Modal {
    var m = self;
    m.shadow = shadow;
    return m;
}

pub fn withMinWidth(self: Modal, width: u16) Modal {
    var m = self;
    m.min_width = width;
    return m;
}

pub fn withMaxWidth(self: Modal, width: u16) Modal {
    var m = self;
    m.max_width = width;
    return m;
}

pub fn withOnResult(self: Modal, callback: *const fn (Result, usize) void) Modal {
    var m = self;
    m.on_result = callback;
    return m;
}

pub fn withIcon(self: Modal, icon: Icon) Modal {
    var m = self;
    m.icon = icon;
    return m;
}

pub fn withIconStyle(self: Modal, style: Style) Modal {
    var m = self;
    m.icon_style = style;
    return m;
}

/// Convenience method to set icon with custom style
pub fn withCustomIcon(self: Modal, char: u21, style: Style) Modal {
    var m = self;
    m.icon = Icon{ .custom = char };
    m.icon_style = style;
    return m;
}

/// Get the width the icon takes (including spacing)
fn iconWidth(self: *Modal) u16 {
    if (self.icon.char() != null) {
        // icon display width + 2 spaces after + 1 space before content
        return self.icon.displayWidth() + 3;
    }
    return 0;
}

/// Calculate the size needed for the modal
pub fn calculateSize(self: *Modal) struct { width: u16, height: u16 } {
    const content_width = self.calculateContentWidth();
    const buttons_width = self.calculateButtonsWidth();
    const icon_w = self.iconWidth();

    // Width is max of title (+ icon space), content, buttons + padding + borders
    var width = @max(content_width, buttons_width);
    // Title with icon needs extra space
    const title_width = @as(u16, @intCast(self.title.len)) + icon_w;
    width = @max(width, title_width);
    width += (self.padding * 2) + 2; // padding on both sides + border
    width = @max(width, self.min_width);
    width = @min(width, self.max_width);

    // Height: border + title + separator + content lines + separator + buttons + border
    const content_lines = self.countContentLines(width - 2 - (self.padding * 2));
    const height: u16 = 1 + // top border
        1 + // title
        1 + // separator
        content_lines + // content
        1 + // space before buttons
        1 + // buttons
        1; // bottom border

    return .{ .width = width, .height = height };
}

fn calculateContentWidth(self: *Modal) u16 {
    // Find longest line in content
    var max_len: usize = 0;
    var iter = std.mem.splitScalar(u8, self.content, '\n');
    while (iter.next()) |line| {
        max_len = @max(max_len, line.len);
    }
    return @intCast(@min(max_len, std.math.maxInt(u16)));
}

fn calculateButtonsWidth(self: *Modal) u16 {
    var total: usize = 0;
    for (self.buttons) |btn| {
        total += btn.label.len + 4; // [ Label ] with spaces
    }
    if (self.buttons.len > 1) {
        total += (self.buttons.len - 1) * 2; // spacing between buttons
    }
    return @intCast(@min(total, std.math.maxInt(u16)));
}

fn countContentLines(self: *Modal, available_width: u16) u16 {
    if (available_width == 0) return 1;

    var lines: u16 = 0;
    var iter = std.mem.splitScalar(u8, self.content, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) {
            lines += 1;
        } else {
            // Word wrap calculation
            const line_count = (line.len + available_width - 1) / available_width;
            lines += @intCast(line_count);
        }
    }
    return @max(lines, 1);
}

/// Draw the modal centered in the given area
pub fn draw(self: *Modal, screen: *Screen, area: Rect) void {
    const size = self.calculateSize();

    // Center the modal
    const x = if (size.width < area.width)
        area.x + (area.width - size.width) / 2
    else
        area.x;

    const y = if (size.height < area.height)
        area.y + (area.height - size.height) / 2
    else
        area.y;

    const modal_rect = Rect.init(x, y, size.width, size.height);

    // Draw shadow first (offset by 1,1)
    if (self.shadow and size.width + 1 <= area.width and size.height + 1 <= area.height) {
        screen.setStyle(Style.fg(Style.Color.dark_gray));
        const shadow_y = y + 1;
        const shadow_x = x + 2;

        // Shadow bottom
        var sx = shadow_x;
        while (sx < x + size.width + 2 and sx < area.right()) : (sx += 1) {
            screen.setChar(sx, y + size.height, 0x2592); // ▒
        }

        // Shadow right
        var sy = shadow_y;
        while (sy < y + size.height and sy < area.bottom()) : (sy += 1) {
            screen.setChar(x + size.width, sy, 0x2592);
            screen.setChar(x + size.width + 1, sy, 0x2592);
        }
    }

    // Clear modal background
    screen.setStyle(.{});
    var cy = y;
    while (cy < y + size.height and cy < area.bottom()) : (cy += 1) {
        var cx = x;
        while (cx < x + size.width and cx < area.right()) : (cx += 1) {
            screen.setChar(cx, cy, ' ');
        }
    }

    // Draw box border
    screen.setStyle(self.border_style);
    screen.box(modal_rect, self.box_style);

    // Draw icon if present (in title bar, left side)
    if (self.icon.char()) |icon_char| {
        const icon_style = self.icon_style orelse self.icon.defaultStyle();
        screen.setStyle(icon_style);

        const icon_x = x + 2; // one space from left border
        const icon_y = y; // same line as title

        screen.setChar(icon_x, icon_y, icon_char);
        // Wide emojis take 2 visual columns - use zero-width char to blank next cell
        if (self.icon.displayWidth() > 1) {
            // Use variation selector or zero-width space to not add visual width
            const blank_char: u21 = if (self.icon.needsVariationSelector()) 0xFE0F else 0x200B;
            screen.setChar(icon_x + 1, icon_y, blank_char);
        }
    }

    // Draw title
    if (self.title.len > 0) {
        screen.setStyle(self.title_style);
        const title_x = x + (size.width - @as(u16, @intCast(@min(self.title.len, size.width - 2)))) / 2;
        const max_title_len = size.width - 2;
        screen.writeStr(title_x, y, self.title[0..@min(self.title.len, max_title_len)]);

        // Draw separator line under title
        screen.setStyle(self.border_style);
        // Left T-connector
        screen.setChar(x, y + 1, self.box_style.teeLeft());
        // Horizontal line
        const inner_width = if (size.width >= 2) size.width - 2 else 0;
        screen.hline(x + 1, y + 1, inner_width, self.box_style.horizontal);
        // Right T-connector
        if (size.width >= 1) {
            screen.setChar(x + size.width - 1, y + 1, self.box_style.teeRight());
        }
    }

    // Draw content
    screen.setStyle(self.content_style);
    const content_x = x + 1 + self.padding;
    var content_y = y + 2;
    const content_width = size.width - 2 - (self.padding * 2);

    var iter = std.mem.splitScalar(u8, self.content, '\n');
    while (iter.next()) |line| {
        if (content_y >= y + size.height - 2) break;

        // Simple word wrap
        var remaining = line;
        while (remaining.len > 0 and content_y < y + size.height - 2) {
            const write_len = @min(remaining.len, content_width);
            screen.writeStr(content_x, content_y, remaining[0..write_len]);
            remaining = remaining[write_len..];
            content_y += 1;
        }

        if (remaining.len == 0 and line.len == 0) {
            content_y += 1; // Empty line
        }
    }

    // Draw buttons
    const buttons_y = y + size.height - 2;
    const buttons_total_width = self.calculateButtonsWidth();
    var btn_x = x + (size.width - buttons_total_width) / 2;

    for (self.buttons, 0..) |btn, i| {
        const is_selected = i == self.selected_button;
        const style = if (is_selected) self.button_selected_style else self.button_style;

        screen.setStyle(style);
        screen.writeStr(btn_x, buttons_y, "[ ");
        btn_x += 2;
        screen.writeStr(btn_x, buttons_y, btn.label);
        btn_x += @intCast(btn.label.len);
        screen.writeStr(btn_x, buttons_y, " ]");
        btn_x += 4; // "] " + spacing
    }
}

pub fn handleInput(self: *Modal, key: Widget.Key) Widget.HandleResult {
    switch (key) {
        .arrow_left, .tab => {
            if (self.buttons.len > 1) {
                self.selected_button = if (self.selected_button == 0)
                    self.buttons.len - 1
                else
                    self.selected_button - 1;
            }
            return .consumed;
        },
        .arrow_right => {
            if (self.buttons.len > 1) {
                self.selected_button = (self.selected_button + 1) % self.buttons.len;
            }
            return .consumed;
        },
        .enter => {
            const result: Result = if (self.selected_button == 0) .confirmed else .button;
            if (self.on_result) |callback| {
                callback(result, self.selected_button);
            }
            return .consumed;
        },
        .escape => {
            if (self.on_result) |callback| {
                callback(.cancelled, self.selected_button);
            }
            return .consumed;
        },
        .char => |c| {
            // Check for button hotkeys
            for (self.buttons, 0..) |btn, i| {
                const hotkey = btn.key orelse (if (btn.label.len > 0) btn.label[0] else null);
                if (hotkey) |h| {
                    if (std.ascii.toLower(c) == std.ascii.toLower(h)) {
                        self.selected_button = i;
                        const result: Result = if (i == 0) .confirmed else .button;
                        if (self.on_result) |callback| {
                            callback(result, i);
                        }
                        return .consumed;
                    }
                }
            }
            return .ignored;
        },
        else => return .ignored,
    }
}

pub fn minSize(self: *Modal) struct { width: u16, height: u16 } {
    return self.calculateSize();
}

/// Get the currently selected button index
pub fn getSelectedButton(self: *Modal) usize {
    return self.selected_button;
}

/// Set the selected button
pub fn setSelectedButton(self: *Modal, index: usize) void {
    if (index < self.buttons.len) {
        self.selected_button = index;
    }
}

/// Reset modal state
pub fn reset(self: *Modal) void {
    self.selected_button = 0;
}
