//! Style demo for zig-tui
//!
//! Demonstrates text styling, colors, and widgets.

const std = @import("std");
const tui = @import("tui");

const State = struct {
    progress: f32 = 0.0,
    progress_bar: tui.ProgressBar,
    input_buffer: [64]u8 = undefined,
    text_input: tui.TextInput,
    list: tui.List,
};

const list_items = [_][]const u8{
    "Item 1: First entry",
    "Item 2: Second entry",
    "Item 3: Third entry",
    "Item 4: Fourth entry",
    "Item 5: Fifth entry",
    "Item 6: Sixth entry",
    "Item 7: Seventh entry",
    "Item 8: Eighth entry",
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try tui.App.init(allocator, .{ .fps = 30 });
    defer app.deinit();

    var state = State{
        .progress_bar = tui.ProgressBar.init()
            .withBarStyle(.block)
            .withStyle(tui.Style.fg(tui.Color.gray))
            .withFilledStyle(tui.Style.fg(tui.Color.green)),
        .text_input = undefined,
        .list = tui.List.init(&list_items)
            .withStyle(tui.Style.fg(tui.Color.white))
            .withSelectedStyle(tui.Style.fg(tui.Color.black).withBg(tui.Color.yellow)),
    };
    state.text_input = tui.TextInput.init(&state.input_buffer)
        .withPlaceholder("Type something...")
        .withStyle(tui.Style.fg(tui.Color.white));

    app.setUserData(State, &state);
    app.setOnDraw(draw);
    app.setOnKey(handleKey);

    try app.run();
}

fn draw(app: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
    const state = app.getUserData(State) orelse return;

    var y: u16 = 1;

    // Title
    screen.setStyle(tui.Style.fg(tui.Color.cyan).withBold());
    screen.writeStr(2, y, "zig-tui Style Demo");
    y += 2;

    // Text styles section
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(2, y, "Text Styles:");
    y += 1;

    screen.setStyle(tui.Style.fg(tui.Color.white).withBold());
    screen.writeStr(4, y, "Bold text");
    y += 1;

    screen.setStyle(tui.Style.fg(tui.Color.white).withDim());
    screen.writeStr(4, y, "Dim text");
    y += 1;

    screen.setStyle(tui.Style.fg(tui.Color.white).withUnderline());
    screen.writeStr(4, y, "Underlined text");
    y += 1;

    screen.setStyle(tui.Style.reverse());
    screen.writeStr(4, y, "Reversed text");
    y += 2;

    // Colors section
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(2, y, "Colors:");
    y += 1;

    const colors = [_]struct { name: []const u8, color: tui.Color }{
        .{ .name = "Red", .color = tui.Color.red },
        .{ .name = "Green", .color = tui.Color.green },
        .{ .name = "Blue", .color = tui.Color.blue },
        .{ .name = "Yellow", .color = tui.Color.yellow },
        .{ .name = "Cyan", .color = tui.Color.cyan },
        .{ .name = "Magenta", .color = tui.Color.magenta },
    };

    var x: u16 = 4;
    for (colors) |c| {
        screen.setStyle(tui.Style.fg(c.color));
        screen.writeStr(x, y, c.name);
        x += @as(u16, @intCast(c.name.len)) + 2;
    }
    y += 2;

    // Box styles section
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(2, y, "Box Styles:");
    y += 1;

    // Draw different box styles
    const box_styles = [_]struct { name: []const u8, chars: tui.Screen.BoxChars }{
        .{ .name = "Single", .chars = tui.Screen.BoxChars.single },
        .{ .name = "Double", .chars = tui.Screen.BoxChars.double },
        .{ .name = "Rounded", .chars = tui.Screen.BoxChars.rounded },
        .{ .name = "Heavy", .chars = tui.Screen.BoxChars.heavy },
    };

    x = 4;
    for (box_styles) |style| {
        screen.setStyle(tui.Style.fg(tui.Color.cyan));
        screen.box(tui.Rect.init(x, y, 12, 4), style.chars);
        screen.setStyle(tui.Style.fg(tui.Color.white));
        screen.writeStr(x + 1, y + 1, style.name);
        x += 14;
    }
    y += 5;

    // Progress bar section
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(2, y, "Progress Bar:");
    y += 1;

    state.progress_bar.setProgress(state.progress);
    state.progress_bar.draw(screen, tui.Rect.init(4, y, 40, 1));
    y += 2;

    // Text input section
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(2, y, "Text Input:");
    y += 1;

    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.box(tui.Rect.init(4, y, 42, 3), tui.Screen.BoxChars.single);
    state.text_input.draw(screen, tui.Rect.init(5, y + 1, 40, 1));
    y += 4;

    // List section (on the right side)
    const list_x: u16 = 60;
    screen.setStyle(tui.Style.fg(tui.Color.yellow).withUnderline());
    screen.writeStr(list_x, 3, "List:");

    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.box(tui.Rect.init(list_x, 4, 30, 7), tui.Screen.BoxChars.single);
    state.list.draw(screen, tui.Rect.init(list_x + 1, 5, 28, 5));

    // Help
    screen.setStyle(tui.Style.fg(tui.Color.gray));
    screen.writeStr(2, area.height - 1, "Tab: Cycle focus | +/-: Progress | Arrow keys: Navigate | q/ESC: Quit");
}

fn handleKey(app: *tui.App, key: tui.Key) !bool {
    const state = app.getUserData(State) orelse return false;

    // Handle text input
    if (state.text_input.focused) {
        const result = state.text_input.handleInput(key);
        if (result == .consumed) return true;
    }

    switch (key) {
        .char => |c| {
            if (c == 'q' or c == 'Q') {
                return false;
            } else if (c == '+' or c == '=') {
                state.progress = @min(state.progress + 0.1, 1.0);
            } else if (c == '-' or c == '_') {
                state.progress = @max(state.progress - 0.1, 0.0);
            }
        },
        .tab => {
            state.text_input.setFocused(!state.text_input.focused);
        },
        .arrow_up, .arrow_down => {
            _ = state.list.handleInput(key);
        },
        else => {},
    }

    return true;
}
