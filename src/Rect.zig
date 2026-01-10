//! Rectangle representation for layout and positioning.
//!
//! A Rect defines a rectangular area with position and dimensions.

const Rect = @This();

x: u16,
y: u16,
width: u16,
height: u16,

pub fn init(x: u16, y: u16, width: u16, height: u16) Rect {
    return .{ .x = x, .y = y, .width = width, .height = height };
}

/// Create a rect at origin with given dimensions
pub fn sized(width: u16, height: u16) Rect {
    return .{ .x = 0, .y = 0, .width = width, .height = height };
}

/// Right edge (exclusive)
pub fn right(self: Rect) u16 {
    return self.x +| self.width;
}

/// Bottom edge (exclusive)
pub fn bottom(self: Rect) u16 {
    return self.y +| self.height;
}

/// Area of the rectangle
pub fn area(self: Rect) u32 {
    return @as(u32, self.width) * @as(u32, self.height);
}

/// Check if rect has zero area
pub fn isEmpty(self: Rect) bool {
    return self.width == 0 or self.height == 0;
}

/// Check if a point is inside the rect
pub fn contains(self: Rect, x: u16, y: u16) bool {
    return x >= self.x and x < self.right() and
        y >= self.y and y < self.bottom();
}

/// Create a new rect with padding removed from all sides
pub fn shrink(self: Rect, amount: u16) Rect {
    const double = amount *| 2;
    return .{
        .x = self.x +| amount,
        .y = self.y +| amount,
        .width = if (self.width > double) self.width - double else 0,
        .height = if (self.height > double) self.height - double else 0,
    };
}

/// Create a new rect with different padding on each side
pub fn inset(self: Rect, top: u16, right_pad: u16, bottom_pad: u16, left: u16) Rect {
    return .{
        .x = self.x +| left,
        .y = self.y +| top,
        .width = if (self.width > left +| right_pad) self.width - left - right_pad else 0,
        .height = if (self.height > top +| bottom_pad) self.height - top - bottom_pad else 0,
    };
}

/// Intersection of two rects
pub fn intersect(self: Rect, other: Rect) Rect {
    const x1 = @max(self.x, other.x);
    const y1 = @max(self.y, other.y);
    const x2 = @min(self.right(), other.right());
    const y2 = @min(self.bottom(), other.bottom());

    if (x2 <= x1 or y2 <= y1) {
        return .{ .x = 0, .y = 0, .width = 0, .height = 0 };
    }

    return .{
        .x = x1,
        .y = y1,
        .width = x2 - x1,
        .height = y2 - y1,
    };
}

/// Split horizontally at a given height from top
pub fn splitHorizontal(self: Rect, at: u16) struct { top: Rect, bottom: Rect } {
    const split_at = @min(at, self.height);
    return .{
        .top = .{
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = split_at,
        },
        .bottom = .{
            .x = self.x,
            .y = self.y +| split_at,
            .width = self.width,
            .height = self.height -| split_at,
        },
    };
}

/// Split vertically at a given width from left
pub fn splitVertical(self: Rect, at: u16) struct { left: Rect, right: Rect } {
    const split_at = @min(at, self.width);
    return .{
        .left = .{
            .x = self.x,
            .y = self.y,
            .width = split_at,
            .height = self.height,
        },
        .right = .{
            .x = self.x +| split_at,
            .y = self.y,
            .width = self.width -| split_at,
            .height = self.height,
        },
    };
}

/// Center a smaller rect within this rect
pub fn center(self: Rect, inner_width: u16, inner_height: u16) Rect {
    const w = @min(inner_width, self.width);
    const h = @min(inner_height, self.height);
    return .{
        .x = self.x +| (self.width -| w) / 2,
        .y = self.y +| (self.height -| h) / 2,
        .width = w,
        .height = h,
    };
}
