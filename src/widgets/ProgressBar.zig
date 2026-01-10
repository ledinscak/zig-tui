//! ProgressBar widget - visual progress indicator.
//!
//! Displays a horizontal bar showing completion percentage.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const ProgressBar = @This();

/// Visual style for the progress bar
pub const BarStyle = enum {
    block, // ████░░░░
    ascii, // [####----]
    thin, // ━━━━────

    pub fn chars(self: BarStyle) struct {
        filled: u21,
        empty: u21,
        left_cap: ?u21,
        right_cap: ?u21,
    } {
        return switch (self) {
            .block => .{
                .filled = 0x2588, // █
                .empty = 0x2591, // ░
                .left_cap = null,
                .right_cap = null,
            },
            .ascii => .{
                .filled = '#',
                .empty = '-',
                .left_cap = '[',
                .right_cap = ']',
            },
            .thin => .{
                .filled = 0x2501, // ━
                .empty = 0x2500, // ─
                .left_cap = null,
                .right_cap = null,
            },
        };
    }
};

progress: f32 = 0.0, // 0.0 to 1.0
bar_style: BarStyle = .block,
style: Style = .{},
filled_style: ?Style = null,
show_percentage: bool = true,

pub fn init() ProgressBar {
    return .{};
}

pub fn withProgress(self: ProgressBar, progress: f32) ProgressBar {
    var p = self;
    p.progress = std.math.clamp(progress, 0.0, 1.0);
    return p;
}

pub fn withBarStyle(self: ProgressBar, bar_style: BarStyle) ProgressBar {
    var p = self;
    p.bar_style = bar_style;
    return p;
}

pub fn withStyle(self: ProgressBar, style: Style) ProgressBar {
    var p = self;
    p.style = style;
    return p;
}

pub fn withFilledStyle(self: ProgressBar, style: Style) ProgressBar {
    var p = self;
    p.filled_style = style;
    return p;
}

pub fn withShowPercentage(self: ProgressBar, show: bool) ProgressBar {
    var p = self;
    p.show_percentage = show;
    return p;
}

pub fn draw(self: *ProgressBar, screen: *Screen, area: Rect) void {
    if (area.isEmpty()) return;

    const chars = self.bar_style.chars();
    const filled_style = self.filled_style orelse self.style;

    // Calculate available width for the bar
    var bar_width = area.width;
    var bar_x = area.x;

    // Account for caps
    if (chars.left_cap != null) {
        screen.setStyle(self.style);
        screen.setChar(area.x, area.y, chars.left_cap.?);
        bar_x += 1;
        bar_width -= 1;
    }
    if (chars.right_cap != null) {
        bar_width -= 1;
    }

    // Account for percentage display
    if (self.show_percentage and bar_width > 6) {
        bar_width -= 5; // " 100%"
    }

    // Calculate filled portion
    const filled_width: u16 = @intFromFloat(@as(f32, @floatFromInt(bar_width)) * self.progress);
    const empty_width = bar_width - filled_width;

    // Draw filled portion
    screen.setStyle(filled_style);
    var x: u16 = 0;
    while (x < filled_width) : (x += 1) {
        screen.setChar(bar_x + x, area.y, chars.filled);
    }

    // Draw empty portion
    screen.setStyle(self.style);
    x = 0;
    while (x < empty_width) : (x += 1) {
        screen.setChar(bar_x + filled_width + x, area.y, chars.empty);
    }

    // Draw right cap
    if (chars.right_cap != null) {
        screen.setChar(bar_x + bar_width, area.y, chars.right_cap.?);
    }

    // Draw percentage
    if (self.show_percentage and area.width > 6) {
        const percent: u8 = @intFromFloat(self.progress * 100.0);
        var percent_buf: [5]u8 = undefined;
        const percent_str = std.fmt.bufPrint(&percent_buf, "{d:3}%", .{percent}) catch " ??%";

        const percent_x = area.x + area.width - @as(u16, @intCast(percent_str.len));
        screen.setStyle(self.style);
        screen.writeStr(percent_x, area.y, percent_str);
    }
}

pub fn handleInput(_: *ProgressBar, _: Widget.Key) Widget.HandleResult {
    return .ignored;
}

pub fn minSize(_: *ProgressBar) struct { width: u16, height: u16 } {
    return .{ .width = 10, .height = 1 };
}

pub fn setProgress(self: *ProgressBar, progress: f32) void {
    self.progress = std.math.clamp(progress, 0.0, 1.0);
}

pub fn getProgress(self: *ProgressBar) f32 {
    return self.progress;
}

pub fn increment(self: *ProgressBar, amount: f32) void {
    self.progress = std.math.clamp(self.progress + amount, 0.0, 1.0);
}
