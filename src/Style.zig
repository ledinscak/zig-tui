//! Style representation for text rendering.
//!
//! Combines foreground/background colors with text attributes
//! for consistent styling across widgets.

const std = @import("std");
const terminal = @import("terminal");

const Style = @This();

/// RGB color representation
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub const black = Color{ .r = 0, .g = 0, .b = 0 };
    pub const white = Color{ .r = 255, .g = 255, .b = 255 };
    pub const red = Color{ .r = 255, .g = 0, .b = 0 };
    pub const green = Color{ .r = 0, .g = 255, .b = 0 };
    pub const blue = Color{ .r = 0, .g = 0, .b = 255 };
    pub const yellow = Color{ .r = 255, .g = 255, .b = 0 };
    pub const cyan = Color{ .r = 0, .g = 255, .b = 255 };
    pub const magenta = Color{ .r = 255, .g = 0, .b = 255 };
    pub const gray = Color{ .r = 128, .g = 128, .b = 128 };
    pub const dark_gray = Color{ .r = 64, .g = 64, .b = 64 };
    pub const light_gray = Color{ .r = 192, .g = 192, .b = 192 };

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b };
    }

    pub fn eql(self: Color, other: Color) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b;
    }
};

/// Text attributes
pub const Attributes = packed struct {
    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    underline: bool = false,
    blink: bool = false,
    reverse: bool = false,
    strikethrough: bool = false,
    _padding: u1 = 0,

    pub const none = Attributes{};
    pub const bold_only = Attributes{ .bold = true };
    pub const dim_only = Attributes{ .dim = true };
    pub const underline_only = Attributes{ .underline = true };
};

foreground: ?Color = null,
background: ?Color = null,
attrs: Attributes = .{},

pub const default = Style{};

pub fn fg(color: Color) Style {
    return .{ .foreground = color };
}

pub fn bg(color: Color) Style {
    return .{ .background = color };
}

pub fn bold() Style {
    return .{ .attrs = .{ .bold = true } };
}

pub fn dim() Style {
    return .{ .attrs = .{ .dim = true } };
}

pub fn underline() Style {
    return .{ .attrs = .{ .underline = true } };
}

pub fn reverse() Style {
    return .{ .attrs = .{ .reverse = true } };
}

/// Combine two styles (other overrides self where set)
pub fn merge(self: Style, other: Style) Style {
    return .{
        .foreground = other.foreground orelse self.foreground,
        .background = other.background orelse self.background,
        .attrs = .{
            .bold = other.attrs.bold or self.attrs.bold,
            .dim = other.attrs.dim or self.attrs.dim,
            .italic = other.attrs.italic or self.attrs.italic,
            .underline = other.attrs.underline or self.attrs.underline,
            .blink = other.attrs.blink or self.attrs.blink,
            .reverse = other.attrs.reverse or self.attrs.reverse,
            .strikethrough = other.attrs.strikethrough or self.attrs.strikethrough,
        },
    };
}

/// Builder pattern methods
pub fn withFg(self: Style, color: Color) Style {
    var s = self;
    s.foreground = color;
    return s;
}

pub fn withBg(self: Style, color: Color) Style {
    var s = self;
    s.background = color;
    return s;
}

pub fn withBold(self: Style) Style {
    var s = self;
    s.attrs.bold = true;
    return s;
}

pub fn withDim(self: Style) Style {
    var s = self;
    s.attrs.dim = true;
    return s;
}

pub fn withUnderline(self: Style) Style {
    var s = self;
    s.attrs.underline = true;
    return s;
}

pub fn withReverse(self: Style) Style {
    var s = self;
    s.attrs.reverse = true;
    return s;
}

/// Apply this style to the terminal
pub fn apply(self: Style, term: *terminal.Terminal) !void {
    try term.resetStyle();

    if (self.foreground) |color| {
        try term.setFg(color.r, color.g, color.b);
    }
    if (self.background) |color| {
        try term.setBg(color.r, color.g, color.b);
    }
    if (self.attrs.bold) try term.setBold();
    if (self.attrs.dim) try term.setDim();
    if (self.attrs.italic) try term.setItalic();
    if (self.attrs.underline) try term.setUnderline();
    if (self.attrs.blink) try term.setBlink();
    if (self.attrs.reverse) try term.setReverse();
    if (self.attrs.strikethrough) try term.setStrikethrough();
}

pub fn eql(self: Style, other: Style) bool {
    const fg_eq = if (self.foreground) |sfg|
        if (other.foreground) |ofg| sfg.eql(ofg) else false
    else
        other.foreground == null;

    const bg_eq = if (self.background) |sbg|
        if (other.background) |obg| sbg.eql(obg) else false
    else
        other.background == null;

    return fg_eq and bg_eq and
        @as(u8, @bitCast(self.attrs)) == @as(u8, @bitCast(other.attrs));
}
