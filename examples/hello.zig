//! Hello World example for zig-tui
//!
//! Demonstrates basic screen drawing and keyboard input.

const tui = @import("tui");

pub fn main() !void {
    try tui.App.run(setup, .{ .fps = 30 });
}

fn setup(app: *tui.App) !void {
    app.setOnDraw(draw);
    app.setOnKey(handleKey);
    try app.start();
}

fn draw(_: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    // Draw a centered box
    const box_width: u16 = 40;
    const box_height: u16 = 10;
    const box_area = area.center(box_width, box_height);

    // Draw the box border
    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    screen.box(box_area, tui.Screen.BoxChars.rounded);

    // Draw title
    const title = "Hello, zig-tui!";
    const title_x = box_area.x + (box_area.width - @as(u16, @intCast(title.len))) / 2;
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    screen.writeStr(title_x, box_area.y, title);

    // Draw content
    const inner = box_area.shrink(1);

    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(inner.x + 2, inner.y + 2, "Welcome to zig-tui!");
    screen.writeStr(inner.x + 2, inner.y + 4, "A terminal UI library for Zig.");

    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(inner.x + 2, inner.y + 6, "Press 'q' or ESC to quit.");
}

fn handleKey(_: *tui.App, key: tui.Key) !bool {
    switch (key) {
        .char => |c| {
            if (c == 'q' or c == 'Q') {
                return false; // Quit
            }
        },
        else => {},
    }
    return true; // Continue
}
