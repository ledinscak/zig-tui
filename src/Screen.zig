//! Screen buffer for efficient terminal rendering.
//!
//! Maintains a cell buffer and tracks dirty regions to minimize
//! terminal output. Supports clipping via a viewport stack.

const std = @import("std");
const terminal = @import("terminal");
const Style = @import("Style.zig");
const Rect = @import("Rect.zig");

const Screen = @This();

/// A single character cell on screen
pub const Cell = struct {
    char: u21 = ' ',
    style: Style = .{},

    pub fn eql(self: Cell, other: Cell) bool {
        return self.char == other.char and self.style.eql(other.style);
    }
};

allocator: std.mem.Allocator,
width: u16,
height: u16,
cells: []Cell,
prev_cells: []Cell,
clip_stack: std.ArrayListUnmanaged(Rect),
current_style: Style = .{},

pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !Screen {
    const size = @as(usize, width) * @as(usize, height);
    const cells = try allocator.alloc(Cell, size);
    const prev_cells = try allocator.alloc(Cell, size);

    @memset(cells, Cell{});
    @memset(prev_cells, Cell{ .char = 0 }); // Force full redraw on first render

    var clip_stack: std.ArrayListUnmanaged(Rect) = .empty;
    try clip_stack.append(allocator, Rect.init(0, 0, width, height));

    return .{
        .allocator = allocator,
        .width = width,
        .height = height,
        .cells = cells,
        .prev_cells = prev_cells,
        .clip_stack = clip_stack,
    };
}

pub fn deinit(self: *Screen) void {
    self.clip_stack.deinit(self.allocator);
    self.allocator.free(self.prev_cells);
    self.allocator.free(self.cells);
}

/// Resize the screen buffer
pub fn resize(self: *Screen, width: u16, height: u16) !void {
    if (width == self.width and height == self.height) return;

    const size = @as(usize, width) * @as(usize, height);
    const new_cells = try self.allocator.alloc(Cell, size);
    const new_prev = try self.allocator.alloc(Cell, size);

    @memset(new_cells, Cell{});
    @memset(new_prev, Cell{ .char = 0 });

    self.allocator.free(self.cells);
    self.allocator.free(self.prev_cells);

    self.cells = new_cells;
    self.prev_cells = new_prev;
    self.width = width;
    self.height = height;

    self.clip_stack.clearRetainingCapacity();
    try self.clip_stack.append(self.allocator, Rect.init(0, 0, width, height));
}

/// Get current clipping rect
pub fn clip(self: *Screen) Rect {
    return self.clip_stack.getLast();
}

/// Push a new clipping rect (intersected with current)
pub fn pushClip(self: *Screen, rect: Rect) !void {
    const current = self.clip();
    try self.clip_stack.append(self.allocator, current.intersect(rect));
}

/// Pop the current clipping rect
pub fn popClip(self: *Screen) void {
    if (self.clip_stack.items.len > 1) {
        _ = self.clip_stack.pop();
    }
}

/// Set the current drawing style
pub fn setStyle(self: *Screen, style: Style) void {
    self.current_style = style;
}

/// Get cell at position (respects clipping)
fn cellAt(self: *Screen, x: u16, y: u16) ?*Cell {
    const c = self.clip();
    if (!c.contains(x, y)) return null;
    if (x >= self.width or y >= self.height) return null;
    return &self.cells[@as(usize, y) * self.width + x];
}

/// Set a single character at position
pub fn setChar(self: *Screen, x: u16, y: u16, char: u21) void {
    if (self.cellAt(x, y)) |cell| {
        cell.char = char;
        cell.style = self.current_style;
    }
}

/// Set a cell with explicit style
pub fn setCell(self: *Screen, x: u16, y: u16, char: u21, style: Style) void {
    if (self.cellAt(x, y)) |cell| {
        cell.char = char;
        cell.style = style;
    }
}

/// Write a string at position
pub fn writeStr(self: *Screen, x: u16, y: u16, str: []const u8) void {
    var col = x;
    for (str) |byte| {
        if (col >= self.width) break;
        self.setChar(col, y, byte);
        col += 1;
    }
}

/// Write a string with explicit style
pub fn writeStrStyled(self: *Screen, x: u16, y: u16, str: []const u8, style: Style) void {
    var col = x;
    for (str) |byte| {
        if (col >= self.width) break;
        self.setCell(col, y, byte, style);
        col += 1;
    }
}

/// Fill a rect with a character
pub fn fill(self: *Screen, rect: Rect, char: u21) void {
    const clipped = self.clip().intersect(rect);
    if (clipped.isEmpty()) return;

    var y = clipped.y;
    while (y < clipped.bottom()) : (y += 1) {
        var x = clipped.x;
        while (x < clipped.right()) : (x += 1) {
            self.setChar(x, y, char);
        }
    }
}

/// Clear the entire screen (within clip)
pub fn clear(self: *Screen) void {
    self.fill(self.clip(), ' ');
}

/// Draw a horizontal line
pub fn hline(self: *Screen, x: u16, y: u16, len: u16, char: u21) void {
    var i: u16 = 0;
    while (i < len) : (i += 1) {
        self.setChar(x +| i, y, char);
    }
}

/// Draw a vertical line
pub fn vline(self: *Screen, x: u16, y: u16, len: u16, char: u21) void {
    var i: u16 = 0;
    while (i < len) : (i += 1) {
        self.setChar(x, y +| i, char);
    }
}

/// Line style characters for dashed/dotted lines
pub const LineChars = struct {
    horizontal: u21,
    vertical: u21,

    // Solid lines
    pub const solid = LineChars{ .horizontal = 0x2500, .vertical = 0x2502 }; // ─ │
    pub const solid_heavy = LineChars{ .horizontal = 0x2501, .vertical = 0x2503 }; // ━ ┃

    // Dashed lines (triple dash)
    pub const dashed = LineChars{ .horizontal = 0x2504, .vertical = 0x2506 }; // ┄ ┆
    pub const dashed_heavy = LineChars{ .horizontal = 0x2505, .vertical = 0x2507 }; // ┅ ┇

    // Dotted lines (quadruple dash)
    pub const dotted = LineChars{ .horizontal = 0x2508, .vertical = 0x250A }; // ┈ ┊
    pub const dotted_heavy = LineChars{ .horizontal = 0x2509, .vertical = 0x250B }; // ┉ ┋

    // Double lines
    pub const double = LineChars{ .horizontal = 0x2550, .vertical = 0x2551 }; // ═ ║

    // ASCII fallback
    pub const ascii = LineChars{ .horizontal = '-', .vertical = '|' };
    pub const ascii_dotted = LineChars{ .horizontal = '.', .vertical = ':' };
};

/// Draw a horizontal line with style
pub fn hlineStyled(self: *Screen, x: u16, y: u16, len: u16, line_style: LineChars) void {
    self.hline(x, y, len, line_style.horizontal);
}

/// Draw a vertical line with style
pub fn vlineStyled(self: *Screen, x: u16, y: u16, len: u16, line_style: LineChars) void {
    self.vline(x, y, len, line_style.vertical);
}

/// Draw a dashed horizontal line
pub fn hlineDashed(self: *Screen, x: u16, y: u16, len: u16) void {
    self.hline(x, y, len, LineChars.dashed.horizontal);
}

/// Draw a dashed vertical line
pub fn vlineDashed(self: *Screen, x: u16, y: u16, len: u16) void {
    self.vline(x, y, len, LineChars.dashed.vertical);
}

/// Draw a dotted horizontal line
pub fn hlineDotted(self: *Screen, x: u16, y: u16, len: u16) void {
    self.hline(x, y, len, LineChars.dotted.horizontal);
}

/// Draw a dotted vertical line
pub fn vlineDotted(self: *Screen, x: u16, y: u16, len: u16) void {
    self.vline(x, y, len, LineChars.dotted.vertical);
}

/// Box drawing characters
pub const BoxChars = struct {
    top_left: u21,
    top_right: u21,
    bottom_left: u21,
    bottom_right: u21,
    horizontal: u21,
    vertical: u21,
    // Optional: separate characters for each side (for braille, etc.)
    horizontal_top: ?u21 = null, // If set, used for top line instead of horizontal
    horizontal_bottom: ?u21 = null, // If set, used for bottom line instead of horizontal
    vertical_left: ?u21 = null, // If set, used for left line instead of vertical
    vertical_right: ?u21 = null, // If set, used for right line instead of vertical
    // T-connectors for separator lines
    tee_left: ?u21 = null, // ├ style connector
    tee_right: ?u21 = null, // ┤ style connector

    /// Get the character for top horizontal line
    pub fn top(self: BoxChars) u21 {
        return self.horizontal_top orelse self.horizontal;
    }

    /// Get the character for bottom horizontal line
    pub fn bottom(self: BoxChars) u21 {
        return self.horizontal_bottom orelse self.horizontal;
    }

    /// Get the character for left vertical line
    pub fn left(self: BoxChars) u21 {
        return self.vertical_left orelse self.vertical;
    }

    /// Get the character for right vertical line
    pub fn right(self: BoxChars) u21 {
        return self.vertical_right orelse self.vertical;
    }

    /// Get the character for left T-connector (├)
    pub fn teeLeft(self: BoxChars) u21 {
        return self.tee_left orelse 0x251C; // default single ├
    }

    /// Get the character for right T-connector (┤)
    pub fn teeRight(self: BoxChars) u21 {
        return self.tee_right orelse 0x2524; // default single ┤
    }

    /// Create a custom box with all 8 characters specified
    /// Parameters: corners (top_left, top_right, bottom_left, bottom_right)
    ///             lines (top, bottom, left, right)
    pub fn custom(
        corner_tl: u21,
        corner_tr: u21,
        corner_bl: u21,
        corner_br: u21,
        line_top: u21,
        line_bottom: u21,
        line_left: u21,
        line_right: u21,
    ) BoxChars {
        return .{
            .top_left = corner_tl,
            .top_right = corner_tr,
            .bottom_left = corner_bl,
            .bottom_right = corner_br,
            .horizontal = line_top,
            .vertical = line_left,
            .horizontal_top = line_top,
            .horizontal_bottom = line_bottom,
            .vertical_left = line_left,
            .vertical_right = line_right,
        };
    }

    /// Create a custom box with same character for all corners and lines
    pub fn uniform(corner: u21, horizontal_char: u21, vertical_char: u21) BoxChars {
        return .{
            .top_left = corner,
            .top_right = corner,
            .bottom_left = corner,
            .bottom_right = corner,
            .horizontal = horizontal_char,
            .vertical = vertical_char,
        };
    }

    /// Create a custom box with same character for everything
    pub fn fill(char: u21) BoxChars {
        return .{
            .top_left = char,
            .top_right = char,
            .bottom_left = char,
            .bottom_right = char,
            .horizontal = char,
            .vertical = char,
        };
    }

    pub const single = BoxChars{
        .top_left = 0x250C, // ┌
        .top_right = 0x2510, // ┐
        .bottom_left = 0x2514, // └
        .bottom_right = 0x2518, // ┘
        .horizontal = 0x2500, // ─
        .vertical = 0x2502, // │
    };

    pub const double = BoxChars{
        .top_left = 0x2554, // ╔
        .top_right = 0x2557, // ╗
        .bottom_left = 0x255A, // ╚
        .bottom_right = 0x255D, // ╝
        .horizontal = 0x2550, // ═
        .vertical = 0x2551, // ║
        .tee_left = 0x2560, // ╠
        .tee_right = 0x2563, // ╣
    };

    pub const rounded = BoxChars{
        .top_left = 0x256D, // ╭
        .top_right = 0x256E, // ╮
        .bottom_left = 0x2570, // ╰
        .bottom_right = 0x256F, // ╯
        .horizontal = 0x2500, // ─
        .vertical = 0x2502, // │
    };

    pub const heavy = BoxChars{
        .top_left = 0x250F, // ┏
        .top_right = 0x2513, // ┓
        .bottom_left = 0x2517, // ┗
        .bottom_right = 0x251B, // ┛
        .horizontal = 0x2501, // ━
        .vertical = 0x2503, // ┃
        .tee_left = 0x2523, // ┣
        .tee_right = 0x252B, // ┫
    };

    pub const dashed = BoxChars{
        .top_left = 0x250C, // ┌
        .top_right = 0x2510, // ┐
        .bottom_left = 0x2514, // └
        .bottom_right = 0x2518, // ┘
        .horizontal = 0x2504, // ┄
        .vertical = 0x2506, // ┆
    };

    pub const dashed_heavy = BoxChars{
        .top_left = 0x250F, // ┏
        .top_right = 0x2513, // ┓
        .bottom_left = 0x2517, // ┗
        .bottom_right = 0x251B, // ┛
        .horizontal = 0x2505, // ┅
        .vertical = 0x2507, // ┇
    };

    pub const dotted = BoxChars{
        .top_left = 0x250C, // ┌
        .top_right = 0x2510, // ┐
        .bottom_left = 0x2514, // └
        .bottom_right = 0x2518, // ┘
        .horizontal = 0x2508, // ┈
        .vertical = 0x250A, // ┊
    };

    pub const dotted_heavy = BoxChars{
        .top_left = 0x250F, // ┏
        .top_right = 0x2513, // ┓
        .bottom_left = 0x2517, // ┗
        .bottom_right = 0x251B, // ┛
        .horizontal = 0x2509, // ┉
        .vertical = 0x250B, // ┋
    };

    // Block box: uses half-block characters for a solid chunky appearance
    // Uses quadrant characters for proper corner connections
    pub const block = BoxChars{
        .top_left = 0x259B, // ▛ (quadrant upper left + upper right + lower left)
        .top_right = 0x259C, // ▜ (quadrant upper left + upper right + lower right)
        .bottom_left = 0x2599, // ▙ (quadrant upper left + lower left + lower right)
        .bottom_right = 0x259F, // ▟ (quadrant upper right + lower left + lower right)
        .horizontal = 0x2580, // ▀ upper half block (default)
        .vertical = 0x258C, // ▌ left half block (default)
        .horizontal_top = 0x2580, // ▀ upper half block
        .horizontal_bottom = 0x2584, // ▄ lower half block
        .vertical_left = 0x258C, // ▌ left half block
        .vertical_right = 0x2590, // ▐ right half block
    };

    // Block box with full blocks (thicker appearance)
    pub const block_full = BoxChars{
        .top_left = 0x2588, // █ full block
        .top_right = 0x2588, // █ full block
        .bottom_left = 0x2588, // █ full block
        .bottom_right = 0x2588, // █ full block
        .horizontal = 0x2588, // █ full block
        .vertical = 0x2588, // █ full block
    };

    // Braille box: uses braille dots for a dotted appearance
    // Dot layout:  1 4
    //              2 5
    //              3 6
    //              7 8
    // Top line: upper 2 dots (1,4), Bottom line: lower 2 dots (7,8)
    // Left line: left 4 dots (1,2,3,7), Right line: right 4 dots (4,5,6,8)
    // Corners connect the adjacent lines
    pub const braille = BoxChars{
        .top_left = 0x284F, // ⡏ (dots 1,2,3,4,7)
        .top_right = 0x28B9, // ⢹ (dots 1,4,5,6,8)
        .bottom_left = 0x28C7, // ⣇ (dots 1,2,3,7,8)
        .bottom_right = 0x28F8, // ⣸ (dots 4,5,6,7,8)
        .horizontal = 0x2809, // ⠉ (dots 1,4) - top two dots (default)
        .vertical = 0x2847, // ⡇ (dots 1,2,3,7) - left four dots (default)
        .horizontal_top = 0x2809, // ⠉ (dots 1,4) - top two dots
        .horizontal_bottom = 0x28C0, // ⣀ (dots 7,8) - bottom two dots
        .vertical_left = 0x2847, // ⡇ (dots 1,2,3,7) - left four dots
        .vertical_right = 0x28B8, // ⢸ (dots 4,5,6,8) - right four dots
    };

    pub const ascii = BoxChars{
        .top_left = '+',
        .top_right = '+',
        .bottom_left = '+',
        .bottom_right = '+',
        .horizontal = '-',
        .vertical = '|',
    };
};

/// Draw a box border
pub fn box(self: *Screen, rect: Rect, chars: BoxChars) void {
    if (rect.width < 2 or rect.height < 2) return;

    // Corners
    self.setChar(rect.x, rect.y, chars.top_left);
    self.setChar(rect.right() -| 1, rect.y, chars.top_right);
    self.setChar(rect.x, rect.bottom() -| 1, chars.bottom_left);
    self.setChar(rect.right() -| 1, rect.bottom() -| 1, chars.bottom_right);

    // Horizontal lines (top and bottom can be different)
    self.hline(rect.x + 1, rect.y, rect.width -| 2, chars.top());
    self.hline(rect.x + 1, rect.bottom() -| 1, rect.width -| 2, chars.bottom());

    // Vertical lines (left and right can be different)
    self.vline(rect.x, rect.y + 1, rect.height -| 2, chars.left());
    self.vline(rect.right() -| 1, rect.y + 1, rect.height -| 2, chars.right());
}

/// Render changes to terminal
pub fn render(self: *Screen, term: *terminal.Terminal) !void {
    var last_style: ?Style = null;
    var last_x: ?u16 = null;
    var last_y: ?u16 = null;

    var y: u16 = 0;
    while (y < self.height) : (y += 1) {
        var x: u16 = 0;
        while (x < self.width) : (x += 1) {
            const idx = @as(usize, y) * self.width + x;
            const cell = self.cells[idx];
            const prev = self.prev_cells[idx];

            if (!cell.eql(prev)) {
                // Move cursor if not sequential
                if (last_y != y or last_x == null or last_x.? + 1 != x) {
                    try term.moveTo(y, x);
                }

                // Apply style if changed
                if (last_style == null or !last_style.?.eql(cell.style)) {
                    try cell.style.apply(term);
                    last_style = cell.style;
                }

                // Write character (handle Unicode)
                var buf: [4]u8 = undefined;
                const len = std.unicode.utf8Encode(cell.char, &buf) catch 1;
                if (len == 1 and cell.char > 127) {
                    try term.write(" ");
                } else {
                    try term.write(buf[0..len]);
                }

                last_x = x;
                last_y = y;

                // Update prev buffer
                self.prev_cells[idx] = cell;
            }
        }
    }

    try term.resetStyle();
    try term.render();
}

/// Force full redraw on next render
pub fn invalidate(self: *Screen) void {
    @memset(self.prev_cells, Cell{ .char = 0 });
}
