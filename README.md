# zig-tui

A terminal user interface (TUI) library for Zig.

## Features

- **Screen buffer** with double-buffering for flicker-free rendering
- **Box drawing** with multiple character sets (single, double, rounded, heavy, dashed, dotted, block, braille)
- **Style system** with colors (16 + 256 + RGB) and attributes (bold, italic, underline, etc.)
- **Widget collection** for building interactive terminal applications

## Widgets

| Widget | Description |
|--------|-------------|
| Modal | Dialog boxes with icons, buttons, and customizable styling |
| Menu | Selectable menu with keyboard navigation |
| Table | Data table with columns and rows |
| List | Scrollable list widget |
| Box | Container with border styles |
| Text | Static text display |
| TextInput | Text input field |
| ProgressBar | Progress indicator |

## Modal Features

- Emoji icons with proper wide character handling (💡 ⚠️ ⛔ ❔ 🎉)
- Button presets: `ok`, `ok_cancel`, `yes_no`, `yes_no_cancel`, `retry_cancel`, `save_discard_cancel`
- Multiple box styles with matching T-connectors for separator lines
- Shadow effect and keyboard navigation

## Dependencies

- [zig-terminal](https://github.com/ledinscak/zig-terminal) - Terminal I/O library

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .zig_tui = .{
        .url = "https://github.com/ledinscak/zig-tui/archive/refs/tags/VERSION.tar.gz",
        .hash = "...", // zig build will provide the correct hash
    },
},
```

Then in `build.zig`:

```zig
const tui = b.dependency("zig_tui", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("tui", tui.module("tui"));
```

## Usage

```zig
const std = @import("std");
const tui = @import("tui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var app = try tui.App.init(gpa.allocator(), .{});
    defer app.deinit();

    // Create a modal dialog
    var modal = tui.Modal.init("Warning", "Are you sure?")
        .withIcon(.warning)
        .withButtons(tui.Modal.Buttons.yes_no)
        .withBoxStyle(tui.Screen.BoxChars.rounded);

    app.setOnDraw(struct {
        fn draw(_: *tui.App, screen: *tui.Screen, area: tui.Rect) !void {
            modal.draw(screen, area);
        }
    }.draw);

    try app.run();
}
```

## Examples

Build and run examples:

```bash
zig build run-hello          # Basic hello world
zig build run-modal_demo     # Modal dialog showcase
zig build run-menu_demo      # Menu widget demo
zig build run-table_demo     # Table widget demo
zig build run-style_demo     # Style and color demo
zig build run-lines_demo     # Line drawing demo
zig build run-boxes_demo     # Box drawing demo
```

## Box Styles

```
single:  ┌──┐    double:  ╔══╗    rounded: ╭──╮
         │  │             ║  ║             │  │
         └──┘             ╚══╝             ╰──╯

heavy:   ┏━━┓    dashed:  ┌┄┄┐    dotted:  ┌┈┈┐
         ┃  ┃             ┆  ┆             ┊  ┊
         ┗━━┛             └┄┄┘             └┈┈┘
```

## License

[MIT](LICENSE)
