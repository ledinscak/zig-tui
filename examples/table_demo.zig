//! Table demo for zig-tui
//!
//! Demonstrates the Table widget with columns, sorting, and selection.

const tui = @import("tui");

const State = struct {
    table: tui.Table,
};

const columns = [_]tui.Table.Column{
    .{ .header = "ID", .width = .{ .fixed = 6 }, .alignment = .right },
    .{ .header = "Name", .width = .{ .auto = {} }, .alignment = .left },
    .{ .header = "Role", .width = .{ .auto = {} }, .alignment = .left },
    .{ .header = "Status", .width = .{ .fixed = 10 }, .alignment = .center },
    .{ .header = "Score", .width = .{ .fixed = 8 }, .alignment = .right },
};

const rows = [_][]const []const u8{
    &[_][]const u8{ "1", "Alice Johnson", "Developer", "Active", "95" },
    &[_][]const u8{ "2", "Bob Smith", "Designer", "Active", "88" },
    &[_][]const u8{ "3", "Carol White", "Manager", "Away", "92" },
    &[_][]const u8{ "4", "David Brown", "Developer", "Active", "87" },
    &[_][]const u8{ "5", "Eve Davis", "QA Engineer", "Busy", "91" },
    &[_][]const u8{ "6", "Frank Miller", "DevOps", "Active", "89" },
    &[_][]const u8{ "7", "Grace Lee", "Developer", "Away", "94" },
    &[_][]const u8{ "8", "Henry Wilson", "Designer", "Active", "86" },
    &[_][]const u8{ "9", "Ivy Chen", "Manager", "Active", "93" },
    &[_][]const u8{ "10", "Jack Taylor", "Developer", "Busy", "90" },
    &[_][]const u8{ "11", "Kate Adams", "QA Engineer", "Active", "85" },
    &[_][]const u8{ "12", "Leo Garcia", "DevOps", "Away", "88" },
};

pub fn main() !void {
    try tui.App.run(setup, .{ .fps = 30 });
}

fn setup(app: *tui.App) !void {
    var state = State{
        .table = tui.Table.init(&columns, &rows)
            .withStyle(tui.Style.fg(tui.Color.white))
            .withHeaderStyle(tui.Style.fg(tui.Color.cyan).withBold())
            .withSelectedStyle(tui.Style.fg(tui.Color.black).withBg(tui.Color.cyan))
            .withBorderStyle(tui.Style.fg(tui.Color.gray)),
    };

    app.setUserData(State, &state);
    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    try app.start();
}

fn draw(app: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    const state = app.getUserData(State) orelse return;

    // Title
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    const title = "Table Widget Demo";
    const title_x = (area.width - @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    // Draw table
    const table_area = tui.Rect.init(2, 3, area.width - 4, area.height - 6);
    state.table.draw(screen, table_area);

    // Show selected row info
    if (state.table.getSelectedRow()) |row| {
        const info_y = area.height - 2;
        screen.setStyle(tui.Style.fg(tui.Color.green));
        screen.writeStr(2, info_y, "Selected: ");

        screen.setStyle(tui.Style.fg(tui.Color.white));
        var x: u16 = 12;
        for (row, 0..) |cell, i| {
            screen.writeStr(x, info_y, cell);
            x += @as(u16, @intCast(cell.len));
            if (i < row.len - 1) {
                screen.writeStr(x, info_y, " | ");
                x += 3;
            }
        }
    }

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Arrow keys/j/k: Navigate | PgUp/PgDn: Page | Home/End: Jump | q/ESC: Quit");
}

fn handleKey(app: *tui.App, key: tui.Key) !bool {
    const state = app.getUserData(State) orelse return false;

    // Handle table navigation
    const result = state.table.handleInput(key);
    if (result == .consumed) {
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
