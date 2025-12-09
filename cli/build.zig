const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cli_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cli_executable = b.addExecutable(.{ .name = "dashwing_cli", .root_module = cli_module });

    b.installArtifact(cli_executable);

    // Run step for cli
    const cli = b.addRunArtifact(cli_executable);

    if (b.args) |args| {
        cli.addArgs(args);
    }

    const run_cli = b.step("cli", "Runs dashwind_cli");
    run_cli.dependOn(&cli.step);
}
