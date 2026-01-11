//! Modal demo for zig-tui
//!
//! Demonstrates the Modal widget with various configurations.

const std = @import("std");
const tui = @import("tui");

const State = struct {
    modal: tui.Modal,
    show_modal: bool = true,
    last_result: ?struct { result: tui.Modal.Result, button: usize } = null,
    modal_type: ModalType = .confirm,
};

const ModalType = enum {
    confirm,
    yes_no,
    save_discard,
    custom,
    info,
    warning,
    err,
    success,
};

pub fn main() !void {
    try tui.App.run(setup, .{ .fps = 30 });
}

fn setup(app: *tui.App) !void {
    var state = State{
        .modal = createModal(.confirm),
    };

    app.setUserData(State, &state);
    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    try app.start();
}

fn createModal(modal_type: ModalType) tui.Modal {
    return switch (modal_type) {
        .confirm => tui.Modal.init(
            "Confirmation",
            "Are you sure you want to proceed?\n\nThis action cannot be undone.",
        )
            .withButtons(tui.Modal.Buttons.ok_cancel)
            .withTitleStyle(tui.Style.fg(tui.Color.yellow).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.cyan))
            .withButtonSelectedStyle(tui.Style.fg(tui.Color.black).withBg(tui.Color.cyan)),

        .yes_no => tui.Modal.init(
            "Question",
            "Do you want to save changes before exiting?",
        )
            .withButtons(tui.Modal.Buttons.yes_no)
            .withBoxStyle(tui.Screen.BoxChars.double)
            .withTitleStyle(tui.Style.fg(tui.Color.green).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.green)),

        .save_discard => tui.Modal.init(
            "Unsaved Changes",
            "You have unsaved changes.\n\nWhat would you like to do?",
        )
            .withButtons(tui.Modal.Buttons.save_discard_cancel)
            .withBoxStyle(tui.Screen.BoxChars.heavy)
            .withTitleStyle(tui.Style.fg(tui.Color.red).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.red)),

        .custom => tui.Modal.init(
            "Custom Buttons",
            "This modal has custom buttons defined.",
        )
            .withButtons(&[_]tui.Modal.Button{
                .{ .label = "Apple", .key = 'a' },
                .{ .label = "Banana", .key = 'b' },
                .{ .label = "Cherry", .key = 'c' },
            })
            .withBoxStyle(tui.Screen.BoxChars.rounded)
            .withTitleStyle(tui.Style.fg(tui.Color.magenta).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.magenta)),

        .info => tui.Modal.init(
            "Information",
            "This is an informational dialog.\n\nPress OK or Enter to dismiss.",
        )
            .withIcon(.info)
            .withIconStyle(tui.Style.fg(tui.Color.white).withBold())
            .withButtons(tui.Modal.Buttons.ok)
            .withTitleStyle(tui.Style.fg(tui.Color.white).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.blue)),

        .warning => tui.Modal.init(
            "Warning",
            "This action may have unintended\nconsequences. Please proceed\nwith caution.",
        )
            .withIcon(.warning)
            .withIconStyle(tui.Style.fg(tui.Color.white).withBold())
            .withButtons(tui.Modal.Buttons.ok_cancel)
            .withBoxStyle(tui.Screen.BoxChars.heavy)
            .withTitleStyle(tui.Style.fg(tui.Color.white).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.yellow)),

        .err => tui.Modal.init(
            "Error",
            "An error has occurred!\n\nUnable to complete the requested\noperation.",
        )
            .withIcon(.@"error")
            .withIconStyle(tui.Style.fg(tui.Color.white).withBold())
            .withButtons(tui.Modal.Buttons.retry_cancel)
            .withBoxStyle(tui.Screen.BoxChars.double)
            .withTitleStyle(tui.Style.fg(tui.Color.white).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.red)),

        .success => tui.Modal.init(
            "Success",
            "Operation completed successfully!\n\nAll changes have been saved.",
        )
            .withIcon(.success)
            .withIconStyle(tui.Style.fg(tui.Color.white).withBold())
            .withButtons(tui.Modal.Buttons.ok)
            .withTitleStyle(tui.Style.fg(tui.Color.white).withBold())
            .withBorderStyle(tui.Style.fg(tui.Color.green)),
    };
}

fn draw(app: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    const state = app.getUserData(State) orelse return;

    // Clear screen to avoid leftover artifacts from previous modal
    screen.clear();

    // Draw background content
    screen.setStyle(tui.Style.fg(tui.Color.gray));

    // Title
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withBold());
    const title = "Modal Widget Demo";
    const title_x = (area.width - @as(u16, @intCast(title.len))) / 2;
    screen.writeStr(title_x, 1, title);

    // Instructions
    screen.setStyle(tui.Style.fg(tui.Color.white));
    screen.writeStr(4, 3, "Press number keys to show different modal types:");
    screen.setStyle(tui.Style.fg(tui.Color.cyan));
    screen.writeStr(4, 5, "1 - OK/Cancel confirmation");
    screen.writeStr(4, 6, "2 - Yes/No question");
    screen.writeStr(4, 7, "3 - Save/Discard/Cancel");
    screen.writeStr(4, 8, "4 - Custom buttons");
    screen.writeStr(4, 9, "5 - Information (with icon)");
    screen.writeStr(4, 10, "6 - Warning (with icon)");
    screen.writeStr(4, 11, "7 - Error (with icon)");
    screen.writeStr(4, 12, "8 - Success (with icon)");

    // Show last result
    if (state.last_result) |result| {
        screen.setStyle(tui.Style.fg(tui.Color.green));
        screen.writeStr(4, 15, "Last result:");
        screen.setStyle(tui.Style.fg(tui.Color.white));

        const result_str = switch (result.result) {
            .confirmed => "Confirmed",
            .cancelled => "Cancelled",
            .button => "Button pressed",
            .none => "None",
        };
        screen.writeStr(17, 15, result_str);

        var buf: [32]u8 = undefined;
        const button_str = std.fmt.bufPrint(&buf, "(button index: {})", .{result.button}) catch "?";
        screen.writeStr(30, 15, button_str);
    }

    // Draw modal if visible
    if (state.show_modal) {
        var modal = state.modal;
        modal.draw(screen, area);
    } else {
        screen.setStyle(tui.Style.fg(tui.Color.yellow));
        screen.writeStr(4, 17, "Modal closed. Press 1-8 to open a new one.");
    }

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Arrow keys/Tab: Navigate buttons | Enter: Confirm | Esc: Cancel | q: Quit");
}

fn handleKey(app: *tui.App, key: tui.Key) !bool {
    const state = app.getUserData(State) orelse return false;

    // Handle modal input first if visible
    if (state.show_modal) {
        const result = state.modal.handleInput(key);

        // Check if modal was dismissed
        switch (key) {
            .enter => {
                const modal_result: tui.Modal.Result = if (state.modal.selected_button == 0) .confirmed else .button;
                state.last_result = .{ .result = modal_result, .button = state.modal.selected_button };
                state.show_modal = false;
                return true;
            },
            .escape => {
                state.last_result = .{ .result = .cancelled, .button = state.modal.selected_button };
                state.show_modal = false;
                return true;
            },
            .char => |c| {
                // Check for hotkey match
                for (state.modal.buttons, 0..) |btn, i| {
                    const hotkey = btn.key orelse (if (btn.label.len > 0) btn.label[0] else null);
                    if (hotkey) |h| {
                        if (std.ascii.toLower(c) == std.ascii.toLower(h)) {
                            const modal_result: tui.Modal.Result = if (i == 0) .confirmed else .button;
                            state.last_result = .{ .result = modal_result, .button = i };
                            state.show_modal = false;
                            return true;
                        }
                    }
                }
            },
            else => {},
        }

        if (result == .consumed) {
            return true;
        }
    }

    // Handle global keys
    switch (key) {
        .char => |c| {
            switch (c) {
                'q', 'Q' => return false,
                '1' => {
                    state.modal_type = .confirm;
                    state.modal = createModal(.confirm);
                    state.show_modal = true;
                },
                '2' => {
                    state.modal_type = .yes_no;
                    state.modal = createModal(.yes_no);
                    state.show_modal = true;
                },
                '3' => {
                    state.modal_type = .save_discard;
                    state.modal = createModal(.save_discard);
                    state.show_modal = true;
                },
                '4' => {
                    state.modal_type = .custom;
                    state.modal = createModal(.custom);
                    state.show_modal = true;
                },
                '5' => {
                    state.modal_type = .info;
                    state.modal = createModal(.info);
                    state.show_modal = true;
                },
                '6' => {
                    state.modal_type = .warning;
                    state.modal = createModal(.warning);
                    state.show_modal = true;
                },
                '7' => {
                    state.modal_type = .err;
                    state.modal = createModal(.err);
                    state.show_modal = true;
                },
                '8' => {
                    state.modal_type = .success;
                    state.modal = createModal(.success);
                    state.show_modal = true;
                },
                else => {},
            }
        },
        else => {},
    }

    return true;
}
