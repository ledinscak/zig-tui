//! Boxes demo for zig-tui
//!
//! Demonstrates all box drawing styles including custom boxes.

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
    const title = "Box Styles Demo";
    const title_x = (area.width - @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    var y: u16 = 3;
    const x: u16 = 2;
    const box_width: u16 = 14;
    const box_height: u16 = 5;
    var box_x: u16 = x;

    // Row 1: Basic styles
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Basic Styles:");
    y += 1;

    // Single box
    screen.setStyle(tui.Style.fg(tui.Color.green));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.single);
    screen.writeStr(box_x + 2, y + 2, "single");
    box_x += box_width + 1;

    // Double box
    screen.setStyle(tui.Style.fg(tui.Color.blue));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.double);
    screen.writeStr(box_x + 2, y + 2, "double");
    box_x += box_width + 1;

    // Rounded box
    screen.setStyle(tui.Style.fg(tui.Color.magenta));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.rounded);
    screen.writeStr(box_x + 2, y + 2, "rounded");
    box_x += box_width + 1;

    // Heavy box
    screen.setStyle(tui.Style.fg(tui.Color.yellow));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.heavy);
    screen.writeStr(box_x + 2, y + 2, "heavy");
    box_x += box_width + 1;

    // ASCII box
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.ascii);
    screen.writeStr(box_x + 2, y + 2, "ascii");

    y += box_height + 1;

    // Row 2: Dashed and Dotted
    box_x = x;
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Dashed & Dotted:");
    y += 1;

    // Dashed box
    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.dashed);
    screen.writeStr(box_x + 2, y + 2, "dashed");
    box_x += box_width + 1;

    // Dashed heavy box
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.dashed_heavy);
    screen.writeStr(box_x + 1, y + 2, "dashed_hvy");
    box_x += box_width + 1;

    // Dotted box
    screen.setStyle(tui.Style.fg(tui.Color.green));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.dotted);
    screen.writeStr(box_x + 2, y + 2, "dotted");
    box_x += box_width + 1;

    // Dotted heavy box
    screen.setStyle(tui.Style.fg(tui.Color.yellow));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.dotted_heavy);
    screen.writeStr(box_x + 1, y + 2, "dotted_hvy");

    y += box_height + 1;

    // Row 3: Special styles
    box_x = x;
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Special Styles:");
    y += 1;

    // Braille box
    screen.setStyle(tui.Style.fg(tui.Color.magenta));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.braille);
    screen.writeStr(box_x + 2, y + 2, "braille");
    box_x += box_width + 1;

    // Block box (half blocks)
    screen.setStyle(tui.Style.fg(tui.Color.red));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.block);
    screen.writeStr(box_x + 2, y + 2, "block");
    box_x += box_width + 1;

    // Block full box
    screen.setStyle(tui.Style.fg(tui.Color.blue));
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), tui.Screen.BoxChars.block_full);
    screen.writeStr(box_x + 2, y + 2, "block_full");

    y += box_height + 1;

    // Row 4: Custom boxes
    box_x = x;
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Custom Boxes:");
    y += 1;

    // Custom box 1: stars and dashes
    screen.setStyle(tui.Style.fg(tui.Color.yellow));
    const custom1 = tui.Screen.BoxChars.custom(
        '*', '*', '*', '*', // corners
        '-', '-', '|', '|', // top, bottom, left, right
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), custom1);
    screen.writeStr(box_x + 2, y + 2, "stars");
    box_x += box_width + 1;

    // Custom box 2: arrows pointing inward
    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    const custom2 = tui.Screen.BoxChars.custom(
        0x2198, 0x2199, 0x2197, 0x2196, // ↘ ↙ ↗ ↖
        0x2193, 0x2191, 0x2192, 0x2190, // ↓ ↑ → ←
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), custom2);
    screen.writeStr(box_x + 2, y + 2, "arrows");
    box_x += box_width + 1;

    // Custom box 3: uniform
    screen.setStyle(tui.Style.fg(tui.Color.green));
    const custom3 = tui.Screen.BoxChars.uniform('#', '=', '!');
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), custom3);
    screen.writeStr(box_x + 2, y + 2, "uniform");
    box_x += box_width + 1;

    // Custom box 4: fill with dots
    screen.setStyle(tui.Style.fg(tui.Color.magenta));
    const custom4 = tui.Screen.BoxChars.fill(0x2022); // •
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), custom4);
    screen.writeStr(box_x + 2, y + 2, "fill");
    box_x += box_width + 1;

    // Custom box 5: different corners
    screen.setStyle(tui.Style.fg(tui.Color.white));
    const custom5 = tui.Screen.BoxChars.custom(
        '1', '2', '3', '4', // numbered corners
        '~', '_', '[', ']', // wavy top, underscore bottom, brackets sides
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), custom5);
    screen.writeStr(box_x + 2, y + 2, "mixed");

    y += box_height + 1;

    // Row 5: Unicode decorative
    box_x = x;
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(x, y, "Unicode Decorative:");
    y += 1;

    // Hearts box
    screen.setStyle(tui.Style.fg(tui.Color.red));
    const hearts = tui.Screen.BoxChars.custom(
        0x2665, 0x2665, 0x2665, 0x2665, // ♥
        0x2665, 0x2665, 0x2665, 0x2665,
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), hearts);
    screen.writeStr(box_x + 2, y + 2, "hearts");
    box_x += box_width + 1;

    // Stars box
    screen.setStyle(tui.Style.fg(tui.Color.yellow));
    const stars = tui.Screen.BoxChars.custom(
        0x2605, 0x2605, 0x2605, 0x2605, // ★
        0x2606, 0x2606, 0x2606, 0x2606, // ☆
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), stars);
    screen.writeStr(box_x + 2, y + 2, "stars");
    box_x += box_width + 1;

    // Diamonds box
    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    const diamonds = tui.Screen.BoxChars.custom(
        0x25C6, 0x25C6, 0x25C6, 0x25C6, // ◆
        0x25C7, 0x25C7, 0x25C7, 0x25C7, // ◇
    );
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), diamonds);
    screen.writeStr(box_x + 2, y + 2, "diamonds");
    box_x += box_width + 1;

    // Shade box
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    const shade = tui.Screen.BoxChars.fill(0x2592); // ▒
    screen.box(tui.Rect.init(box_x, y, box_width, box_height), shade);
    screen.writeStr(box_x + 2, y + 2, "shade");

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Press q or ESC to quit");
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
