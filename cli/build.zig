const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cli_executable = b.addExecutable(.{
        .name = "dashwing_cli",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(cli_executable);

    // Run step for cli
    const cli = b.addRunArtifact(cli_executable);

    if (b.args) |args| {
        cli.addArgs(args);
    }

    const cli_step = b.step("cli", "Runs dashwind_cli");
    cli_step.dependOn(&cli.step);

    // TEST
    const cli_test_step = b.step("test_cli", "Run CLI tests");
    const cli_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli/cli.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_cli_test = b.addRunArtifact(cli_test);
    cli_test_step.dependOn(&run_cli_test.step);
}
