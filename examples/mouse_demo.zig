//! Mouse demo for zig-tui
//!
//! Demonstrates mouse support with a closeable modal window.

const std = @import("std");
const tui = @import("tui");
const terminal = @import("terminal");

const State = struct {
    modal: tui.Modal,
    show_modal: bool = true,
    last_click: ?struct { x: u16, y: u16, button: []const u8 } = null,
    // Track modal bounds for close button hit detection
    modal_x: u16 = 0,
    modal_y: u16 = 0,
    modal_width: u16 = 0,
    modal_height: u16 = 0,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try tui.App.init(allocator, .{ .fps = 30 });
    defer app.deinit();

    var state = State{
        .modal = tui.Modal.init(
            "Closeable Modal",
            "This modal can be closed by clicking\nthe X button on the title bar.\n\nYou can also press Escape or click\nthe Close button below.",
        )
            .withButtons(&[_]tui.Modal.Button{
                .{ .label = "Close", .key = 'c' },
            })
            .withTitleStyle(tui.Style.fg(tui.Color.cyan).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.cyan))
            .withButtonSelectedStyle(tui.Style.fg(tui.Color.cyan).withBold()),
    };

    app.setUserData(State, &state);
    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    // Enable mouse tracking
    try app.term.enableMouse();
    defer app.term.disableMouse() catch {};

    try app.start();
}

fn draw(app: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    const state = app.getUserData(State) orelse return;

    screen.clear();

    // Title
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    const title = "Mouse Support Demo";
    const title_x = (area.width -| @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    // Instructions
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(4, 3, "Mouse tracking is enabled. Click anywhere to see coordinates.");
    screen.writeStr(4, 4, "Click the bomb on the modal title bar to blow it up!");
    screen.writeStr(4, 5, "Press 'o' to re-open the modal.");

    // Show last click info
    if (state.last_click) |click| {
        screen.setStyle(tui.Style.fg(tui.Color.green));
        var buf: [64]u8 = undefined;
        const click_str = std.fmt.bufPrint(&buf, "Last click: ({}, {}) - {s}", .{ click.x, click.y, click.button }) catch "?";
        screen.writeStr(4, 7, click_str);
    }

    // Draw modal if visible
    if (state.show_modal) {
        // Calculate modal bounds for hit detection
        const modal_size = state.modal.calculateSize();
        state.modal_width = modal_size.width;
        state.modal_height = modal_size.height;
        state.modal_x = if (modal_size.width < area.width)
            (area.width - modal_size.width) / 2
        else
            0;
        state.modal_y = if (modal_size.height < area.height)
            (area.height - modal_size.height) / 2
        else
            0;

        // Draw the modal
        var modal = state.modal;
        modal.draw(screen, area);

        // Draw close button on title bar (right side)
        const close_x = state.modal_x + state.modal_width - 3;
        const close_y = state.modal_y;
        screen.setChar(close_x, close_y, 0x1F4A3); // 💣
        screen.setChar(close_x + 1, close_y, 0x200B); // zero-width space for 2nd cell
    } else {
        screen.setStyle(tui.Style.fg(tui.Color.gray));
        screen.writeStr(4, 9, "Modal closed. Press 'o' to open it again.");
    }

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "q: quit | o: open modal | Click bomb or Esc to close");
}

fn handleKey(app: *tui.App, key: tui.Key) !bool {
    const state = app.getUserData(State) orelse return false;

    switch (key) {
        .mouse => |mouse| {
            // Record click info
            const button_name: []const u8 = switch (mouse.button) {
                .left => "Left",
                .right => "Right",
                .middle => "Middle",
                .scroll_up => "Scroll Up",
                .scroll_down => "Scroll Down",
            };
            state.last_click = .{ .x = mouse.col, .y = mouse.row, .button = button_name };

            // Check for left mouse press on close button (bomb emoji)
            if (mouse.button == .left and mouse.pressed and state.show_modal) {
                const close_x = state.modal_x + state.modal_width - 3;
                const close_y = state.modal_y;

                // Hit test: emoji is 2 characters wide
                if (mouse.row == close_y and mouse.col >= close_x and mouse.col < close_x + 2) {
                    state.show_modal = false;
                    return true;
                }
            }
            return true;
        },
        .char => |c| {
            switch (c) {
                'q', 'Q' => return false,
                'o', 'O' => {
                    state.show_modal = true;
                    return true;
                },
                else => {},
            }
        },
        .escape => {
            if (state.show_modal) {
                state.show_modal = false;
                return true;
            }
        },
        .enter => {
            if (state.show_modal) {
                state.show_modal = false;
                return true;
            }
        },
        else => {},
    }

    // Forward to modal if visible
    if (state.show_modal) {
        _ = state.modal.handleInput(key);
    }

    return true;
}
