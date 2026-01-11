const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get zig-terminal dependency
    const terminal_dep = b.dependency("zig_terminal", .{
        .target = target,
        .optimize = optimize,
    });
    const terminal_module = terminal_dep.module("terminal");

    // Main library module
    const tui_module = b.addModule("tui", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tui_module.addImport("terminal", terminal_module);

    // Examples: { step_name, source_file }
    const examples = [_]struct { []const u8, []const u8 }{
        .{ "hello", "hello" },
        .{ "menu-demo", "menu_demo" },
        .{ "style-demo", "style_demo" },
        .{ "table-demo", "table_demo" },
        .{ "lines-demo", "lines_demo" },
        .{ "boxes-demo", "boxes_demo" },
        .{ "modal-demo", "modal_demo" },
        .{ "mouse-demo", "mouse_demo" },
    };

    // Step to build all examples at once
    const examples_step = b.step("examples", "Build all examples");

    for (examples) |entry| {
        const step_name, const source_name = entry;
        const example = b.addExecutable(.{
            .name = step_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("examples/{s}.zig", .{source_name})),
                .target = target,
                .optimize = optimize,
            }),
        });
        example.root_module.addImport("tui", tui_module);
        example.root_module.addImport("terminal", terminal_module);

        const install_example = b.addInstallArtifact(example, .{});
        b.step(step_name, b.fmt("Build the {s} example", .{step_name})).dependOn(&install_example.step);

        // Add to examples step
        examples_step.dependOn(&install_example.step);

        const run_example = b.addRunArtifact(example);
        b.step(b.fmt("run-{s}", .{step_name}), b.fmt("Run the {s} example", .{step_name})).dependOn(&run_example.step);
    }

    // Tests
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    lib_tests.root_module.addImport("terminal", terminal_module);

    const run_lib_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_tests.step);
}
