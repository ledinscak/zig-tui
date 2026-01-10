//! Lines demo for zig-tui
//!
//! Demonstrates all line drawing styles.

const std = @import("std");
const tui = @import("tui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try tui.App.init(allocator, .{ .fps = 30 });
    defer app.deinit();

    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    try app.run();
}

fn draw(_: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    // Title
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    const title = "Line Styles Demo";
    const title_x = (area.width - @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    var y: u16 = 3;
    const x: u16 = 4;
    const line_len: u16 = 30;
    const label_x: u16 = x + line_len + 3;

    // Section: Horizontal Lines
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Horizontal Lines:");
    y += 2;

    screen.setStyle(tui.Style.fg(tui.Color.white));

    // Solid
    screen.hlineStyled(x, y, line_len, tui.Screen.LineChars.solid);
    screen.writeStr(label_x, y, "solid");
    y += 1;

    // Solid heavy
    screen.hlineStyled(x, y, line_len, tui.Screen.LineChars.solid_heavy);
    screen.writeStr(label_x, y, "solid_heavy");
    y += 1;

    // Dashed
    screen.hlineDashed(x, y, line_len);
    screen.writeStr(label_x, y, "dashed");
    y += 1;

    // Dashed heavy
    screen.hlineStyled(x, y, line_len, tui.Screen.LineChars.dashed_heavy);
    screen.writeStr(label_x, y, "dashed_heavy");
    y += 1;

    // Dotted
    screen.hlineDotted(x, y, line_len);
    screen.writeStr(label_x, y, "dotted");
    y += 1;

    // Dotted heavy
    screen.hlineStyled(x, y, line_len, tui.Screen.LineChars.dotted_heavy);
    screen.writeStr(label_x, y, "dotted_heavy");
    y += 1;

    // Double
    screen.hlineStyled(x, y, line_len, tui.Screen.LineChars.double);
    screen.writeStr(label_x, y, "double");
    y += 2;

    // Section: Vertical Lines
    const vline_x: u16 = 50;
    const vline_y: u16 = 5;
    const vline_len: u16 = 8;
    const vline_spacing: u16 = 4;

    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(vline_x, 3, "Vertical Lines:");

    screen.setStyle(tui.Style.fg(tui.Color.white));

    // Draw vertical lines side by side
    var vx = vline_x;

    screen.vlineStyled(vx, vline_y, vline_len, tui.Screen.LineChars.solid);
    screen.writeStr(vx, vline_y + vline_len, "sol");
    vx += vline_spacing;

    screen.vlineStyled(vx, vline_y, vline_len, tui.Screen.LineChars.solid_heavy);
    screen.writeStr(vx, vline_y + vline_len, "hvy");
    vx += vline_spacing;

    screen.vlineDashed(vx, vline_y, vline_len);
    screen.writeStr(vx, vline_y + vline_len, "dsh");
    vx += vline_spacing;

    screen.vlineDotted(vx, vline_y, vline_len);
    screen.writeStr(vx, vline_y + vline_len, "dot");
    vx += vline_spacing;

    screen.vlineStyled(vx, vline_y, vline_len, tui.Screen.LineChars.double);
    screen.writeStr(vx, vline_y + vline_len, "dbl");

    // Section: Combined example with separators
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Usage Example - Panel with Separators:");
    y += 1;

    // Draw a panel with different separator styles
    const panel_rect = tui.Rect.init(x, y, 50, 12);
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.box(panel_rect, tui.Screen.BoxChars.rounded);

    // Title area
    screen.writeStr(x + 2, y + 1, "Panel Title");

    // Dashed separator after title
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.hlineDashed(x + 1, y + 2, 48);

    // Content section 1
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(x + 2, y + 3, "Section 1: Some content here");

    // Dotted separator
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.hlineDotted(x + 1, y + 4, 48);

    // Content section 2
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(x + 2, y + 5, "Section 2: More content");

    // Double separator
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.hlineStyled(x + 1, y + 6, 48, tui.Screen.LineChars.double);

    // Content section 3
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(x + 2, y + 7, "Section 3: Important stuff");

    // Solid heavy separator
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.hlineStyled(x + 1, y + 8, 48, tui.Screen.LineChars.solid_heavy);

    // Footer
    screen.setStyle(tui.Style.fg(tui.Color.dark_gray));
    screen.writeStr(x + 2, y + 10, "Footer text");

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Press q or ESC to quit | See also: boxes_demo");
}

fn handleKey(_: *tui.App, key: tui.Key) !bool {
    switch (key) {
        .char => |c| {
            if (c == 'q' or c == 'Q') {
                return false;
            }
        },
        else => {},
    }
    return true;
}
