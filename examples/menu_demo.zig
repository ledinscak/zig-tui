//! Menu demo for zig-tui
//!
//! Demonstrates the Menu widget with keyboard navigation.

const tui = @import("tui");
const std = @import("std");

const State = struct {
    menu: tui.Menu,
    selected_action: ?[]const u8 = null,
};

const menu_items = [_]tui.Menu.Item{
    .{ .label = "New File" },
    .{ .label = "Open File" },
    .{ .label = "Save" },
    .{ .label = "Save As..." },
    .{ .label = "---", .enabled = false },
    .{ .label = "Settings" },
    .{ .label = "---", .enabled = false },
    .{ .label = "Quit" },
};

pub fn main() !void {
    try tui.App.run(setup, .{ .fps = 30 });
}

fn setup(app: *tui.App) !void {
    var state = State{
        .menu = tui.Menu.init(&menu_items)
            .withStyle(tui.Style.fg(tui.Color.white))
            .withSelectedStyle(tui.Style.fg(tui.Color.black).withBg(tui.Color.cyan)),
    };

    app.setUserData(State, &state);
    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    try app.start();
}

fn draw(app: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    const state = app.getUserData(State) orelse return;

    // Draw title
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    const title = "Menu Demo";
    const title_x = (area.width - @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    // Draw menu box
    const menu_width: u16 = 30;
    const menu_height: u16 = @as(u16, @intCast(menu_items.len)) + 2;
    const menu_area = area.center(menu_width, menu_height);

    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    screen.box(menu_area, tui.Screen.BoxChars.single);

    // Draw menu
    const inner = menu_area.shrink(1);
    state.menu.draw(screen, inner);

    // Draw selected action if any
    if (state.selected_action) |action| {
        screen.setStyle(tui.Style.fg(tui.Color.green));
        const msg_y = area.height - 2;
        screen.writeStr(2, msg_y, "Selected: ");
        screen.writeStr(12, msg_y, action);
    }

    // Draw help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Arrow keys/j/k: Navigate | Enter: Select | q/ESC: Quit");
}

fn handleKey(app: *tui.App, key: tui.Key) !bool {
    const state = app.getUserData(State) orelse return false;

    // Handle menu navigation
    const result = state.menu.handleInput(key);
    if (result == .consumed) {
        // Check if Enter was pressed
        if (key == .enter) {
            const selected = state.menu.getSelected();
            if (menu_items[selected].enabled) {
                state.selected_action = menu_items[selected].label;

                // Handle Quit
                if (std.mem.eql(u8, menu_items[selected].label, "Quit")) {
                    return false;
                }
            }
        }
        return true;
    }

    // Handle quit
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
