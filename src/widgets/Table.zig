//! Table widget - displays data in columns with headers.
//!
//! Supports column alignment, row selection, and scrolling.

const std = @import("std");
const Screen = @import("../Screen.zig");
const Style = @import("../Style.zig");
const Rect = @import("../Rect.zig");
const Widget = @import("Widget.zig");

const Table = @This();

/// Column alignment
pub const Alignment = enum {
    left,
    center,
    right,
};

/// Column definition
pub const Column = struct {
    header: []const u8,
    width: Width = .{ .auto = {} },
    alignment: Alignment = .left,

    pub const Width = union(enum) {
        fixed: u16,
        auto: void,
        percent: u8, // 0-100
    };
};

columns: []const Column,
rows: []const []const []const u8, // rows[row_idx][col_idx] = cell_text
selected: usize = 0,
scroll_offset: usize = 0,
show_header: bool = true,
show_borders: bool = true,
style: Style = .{},
header_style: Style = Style.bold(),
selected_style: Style = Style.reverse(),
border_style: Style = Style.dim(),

pub fn init(columns: []const Column, rows: []const []const []const u8) Table {
    return .{
        .columns = columns,
        .rows = rows,
    };
}

pub fn withStyle(self: Table, style: Style) Table {
    var t = self;
    t.style = style;
    return t;
}

pub fn withHeaderStyle(self: Table, style: Style) Table {
    var t = self;
    t.header_style = style;
    return t;
}

pub fn withSelectedStyle(self: Table, style: Style) Table {
    var t = self;
    t.selected_style = style;
    return t;
}

pub fn withBorderStyle(self: Table, style: Style) Table {
    var t = self;
    t.border_style = style;
    return t;
}

pub fn withBorders(self: Table, show: bool) Table {
    var t = self;
    t.show_borders = show;
    return t;
}

pub fn withHeader(self: Table, show: bool) Table {
    var t = self;
    t.show_header = show;
    return t;
}

pub fn draw(self: *Table, screen: *Screen, area: Rect) void {
    if (area.isEmpty() or self.columns.len == 0) return;

    // Calculate column widths
    var col_widths: [32]u16 = undefined;
    const num_cols = @min(self.columns.len, 32);
    self.calculateColumnWidths(area.width, col_widths[0..num_cols]);

    var y = area.y;

    // Draw header
    if (self.show_header) {
        if (self.show_borders) {
            self.drawTopBorder(screen, area.x, y, col_widths[0..num_cols]);
            y += 1;
        }

        self.drawHeaderRow(screen, area.x, y, col_widths[0..num_cols]);
        y += 1;

        if (self.show_borders) {
            self.drawSeparator(screen, area.x, y, col_widths[0..num_cols]);
            y += 1;
        }
    } else if (self.show_borders) {
        self.drawTopBorder(screen, area.x, y, col_widths[0..num_cols]);
        y += 1;
    }

    // Calculate visible rows
    const header_height: u16 = if (self.show_header)
        (if (self.show_borders) @as(u16, 3) else @as(u16, 1))
    else
        (if (self.show_borders) @as(u16, 1) else @as(u16, 0));

    const footer_height: u16 = if (self.show_borders) 1 else 0;
    const available_height = area.height -| header_height -| footer_height;

    // Ensure selected row is visible
    if (self.selected < self.scroll_offset) {
        self.scroll_offset = self.selected;
    } else if (self.selected >= self.scroll_offset + available_height) {
        self.scroll_offset = self.selected - available_height + 1;
    }

    // Draw rows
    var row_idx: usize = self.scroll_offset;
    var rows_drawn: u16 = 0;
    while (rows_drawn < available_height and row_idx < self.rows.len) : ({
        row_idx += 1;
        rows_drawn += 1;
    }) {
        const is_selected = row_idx == self.selected;
        self.drawDataRow(screen, area.x, y, col_widths[0..num_cols], row_idx, is_selected);
        y += 1;
    }

    // Fill remaining space
    while (rows_drawn < available_height) : (rows_drawn += 1) {
        self.drawEmptyRow(screen, area.x, y, col_widths[0..num_cols]);
        y += 1;
    }

    // Draw bottom border
    if (self.show_borders) {
        self.drawBottomBorder(screen, area.x, y, col_widths[0..num_cols]);
    }
}

fn calculateColumnWidths(self: *Table, total_width: u16, widths: []u16) void {
    var fixed_width: u16 = 0;
    var auto_count: u16 = 0;
    var percent_total: u16 = 0;

    // Account for borders: | col | col | col |
    const border_overhead: u16 = if (self.show_borders)
        @as(u16, @intCast(self.columns.len)) + 1
    else
        @as(u16, @intCast(self.columns.len)) -| 1; // spaces between columns

    const available = total_width -| border_overhead;

    // First pass: calculate fixed and percent widths
    for (self.columns, 0..) |col, i| {
        switch (col.width) {
            .fixed => |w| {
                widths[i] = w;
                fixed_width += w;
            },
            .auto => {
                widths[i] = 0;
                auto_count += 1;
            },
            .percent => |p| {
                const w = @as(u16, @intCast((@as(u32, available) * p) / 100));
                widths[i] = w;
                percent_total += w;
            },
        }
    }

    // Second pass: distribute remaining space to auto columns
    if (auto_count > 0) {
        const remaining = available -| fixed_width -| percent_total;
        const per_auto = remaining / auto_count;
        var extra = remaining % auto_count;

        for (self.columns, 0..) |col, i| {
            if (col.width == .auto) {
                widths[i] = per_auto + (if (extra > 0) blk: {
                    extra -= 1;
                    break :blk @as(u16, 1);
                } else 0);
            }
        }
    }
}

fn drawTopBorder(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16) void {
    screen.setStyle(self.border_style);
    var col_x = x;

    screen.setChar(col_x, y, 0x250C); // ┌
    col_x += 1;

    for (widths, 0..) |w, i| {
        var j: u16 = 0;
        while (j < w) : (j += 1) {
            screen.setChar(col_x + j, y, 0x2500); // ─
        }
        col_x += w;

        if (i < widths.len - 1) {
            screen.setChar(col_x, y, 0x252C); // ┬
            col_x += 1;
        }
    }

    screen.setChar(col_x, y, 0x2510); // ┐
}

fn drawBottomBorder(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16) void {
    screen.setStyle(self.border_style);
    var col_x = x;

    screen.setChar(col_x, y, 0x2514); // └
    col_x += 1;

    for (widths, 0..) |w, i| {
        var j: u16 = 0;
        while (j < w) : (j += 1) {
            screen.setChar(col_x + j, y, 0x2500); // ─
        }
        col_x += w;

        if (i < widths.len - 1) {
            screen.setChar(col_x, y, 0x2534); // ┴
            col_x += 1;
        }
    }

    screen.setChar(col_x, y, 0x2518); // ┘
}

fn drawSeparator(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16) void {
    screen.setStyle(self.border_style);
    var col_x = x;

    screen.setChar(col_x, y, 0x251C); // ├
    col_x += 1;

    for (widths, 0..) |w, i| {
        var j: u16 = 0;
        while (j < w) : (j += 1) {
            screen.setChar(col_x + j, y, 0x2500); // ─
        }
        col_x += w;

        if (i < widths.len - 1) {
            screen.setChar(col_x, y, 0x253C); // ┼
            col_x += 1;
        }
    }

    screen.setChar(col_x, y, 0x2524); // ┤
}

fn drawHeaderRow(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16) void {
    var col_x = x;

    if (self.show_borders) {
        screen.setStyle(self.border_style);
        screen.setChar(col_x, y, 0x2502); // │
        col_x += 1;
    }

    for (self.columns, 0..) |col, i| {
        const w = widths[i];
        screen.setStyle(self.header_style);
        self.drawCellText(screen, col_x, y, w, col.header, col.alignment);
        col_x += w;

        if (self.show_borders) {
            screen.setStyle(self.border_style);
            screen.setChar(col_x, y, 0x2502); // │
            col_x += 1;
        } else if (i < self.columns.len - 1) {
            screen.setChar(col_x, y, ' ');
            col_x += 1;
        }
    }
}

fn drawDataRow(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16, row_idx: usize, is_selected: bool) void {
    var col_x = x;
    const row = self.rows[row_idx];

    if (self.show_borders) {
        screen.setStyle(self.border_style);
        screen.setChar(col_x, y, 0x2502); // │
        col_x += 1;
    }

    for (self.columns, 0..) |col, i| {
        const w = widths[i];
        const cell_text = if (i < row.len) row[i] else "";

        const cell_style = if (is_selected) self.selected_style else self.style;
        screen.setStyle(cell_style);

        // Fill cell background for selection
        if (is_selected) {
            var j: u16 = 0;
            while (j < w) : (j += 1) {
                screen.setChar(col_x + j, y, ' ');
            }
        }

        self.drawCellText(screen, col_x, y, w, cell_text, col.alignment);
        col_x += w;

        if (self.show_borders) {
            screen.setStyle(self.border_style);
            screen.setChar(col_x, y, 0x2502); // │
            col_x += 1;
        } else if (i < self.columns.len - 1) {
            screen.setChar(col_x, y, ' ');
            col_x += 1;
        }
    }
}

fn drawEmptyRow(self: *Table, screen: *Screen, x: u16, y: u16, widths: []const u16) void {
    var col_x = x;

    if (self.show_borders) {
        screen.setStyle(self.border_style);
        screen.setChar(col_x, y, 0x2502); // │
        col_x += 1;
    }

    screen.setStyle(self.style);

    for (widths, 0..) |w, i| {
        var j: u16 = 0;
        while (j < w) : (j += 1) {
            screen.setChar(col_x + j, y, ' ');
        }
        col_x += w;

        if (self.show_borders) {
            screen.setStyle(self.border_style);
            screen.setChar(col_x, y, 0x2502); // │
            col_x += 1;
        } else if (i < widths.len - 1) {
            screen.setChar(col_x, y, ' ');
            col_x += 1;
        }
    }
}

fn drawCellText(_: *Table, screen: *Screen, x: u16, y: u16, width: u16, text: []const u8, alignment: Alignment) void {
    if (width == 0) return;

    const text_len: u16 = @intCast(@min(text.len, width));
    const padding = width -| text_len;

    const text_x = switch (alignment) {
        .left => x,
        .center => x + padding / 2,
        .right => x + padding,
    };

    screen.writeStr(text_x, y, text[0..text_len]);
}

pub fn handleInput(self: *Table, key: Widget.Key) Widget.HandleResult {
    switch (key) {
        .arrow_up => {
            if (self.selected > 0) {
                self.selected -= 1;
            }
            return .consumed;
        },
        .arrow_down => {
            if (self.selected + 1 < self.rows.len) {
                self.selected += 1;
            }
            return .consumed;
        },
        .page_up => {
            if (self.selected > 10) {
                self.selected -= 10;
            } else {
                self.selected = 0;
            }
            return .consumed;
        },
        .page_down => {
            self.selected = @min(self.selected + 10, self.rows.len -| 1);
            return .consumed;
        },
        .home => {
            self.selected = 0;
            return .consumed;
        },
        .end => {
            if (self.rows.len > 0) {
                self.selected = self.rows.len - 1;
            }
            return .consumed;
        },
        .char => |c| {
            if (c == 'k' or c == 'K') {
                if (self.selected > 0) {
                    self.selected -= 1;
                }
                return .consumed;
            } else if (c == 'j' or c == 'J') {
                if (self.selected + 1 < self.rows.len) {
                    self.selected += 1;
                }
                return .consumed;
            }
            return .ignored;
        },
        else => return .ignored,
    }
}

pub fn minSize(self: *Table) struct { width: u16, height: u16 } {
    var width: u16 = 0;

    for (self.columns) |col| {
        width += switch (col.width) {
            .fixed => |w| w,
            .auto => @as(u16, @intCast(col.header.len)),
            .percent => 10, // minimum for percent columns
        };
    }

    if (self.show_borders) {
        width += @as(u16, @intCast(self.columns.len)) + 1;
    }

    var height: u16 = @intCast(@min(self.rows.len, 10));
    if (self.show_header) height += 1;
    if (self.show_borders) height += 2; // top and bottom borders
    if (self.show_borders and self.show_header) height += 1; // separator

    return .{ .width = width, .height = height };
}

pub fn getSelected(self: *Table) usize {
    return self.selected;
}

pub fn getSelectedRow(self: *Table) ?[]const []const u8 {
    if (self.selected < self.rows.len) {
        return self.rows[self.selected];
    }
    return null;
}

pub fn setSelected(self: *Table, index: usize) void {
    if (index < self.rows.len) {
        self.selected = index;
    }
}
