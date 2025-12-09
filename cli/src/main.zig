const std = @import("std");
const cli = @import("cli/cli.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const root_cmd = cli.Command{ .name = "Dashwing", .version = "0.0.1", .description = "Dashwing CLI", .flags = &.{
        cli.Argument.Flag.init(.{ .long = "test", .short = "t" }),
    }, .sub_commands = &.{
        cli.Command{
            .name = "source",
            .version = "0.0.1",
            .description = "use this source",
            .flags = &.{
                cli.Argument.Flag.init(.{ .long = "test", .short = "t" }),
            },
            .sub_commands = &.{
                cli.Command{
                    .name = "test",
                    .version = "0.0.1",
                    .description = "use this test",
                    .sub_commands = &.{
                        cli.Command{
                            .name = "source",
                            .version = "0.0.2",
                            .description = "use this source",
                            .sub_commands = &.{
                                cli.Command{
                                    .name = "test",
                                    .version = "0.0.2",
                                    .description = "use this test",
                                    .sub_commands = &.{},
                                },
                            },
                        },
                    },
                },
            },
        },
        cli.Command{
            .name = "test",
            .version = "0.1.0",
            .description = "use this test",
            .flags = &.{
                cli.Argument.Flag.init(.{ .long = "source", .short = "s" }),
            },
            .sub_commands = &.{
                cli.Command{
                    .name = "source",
                    .version = "0.1.0",
                    .description = "use this source",
                    .sub_commands = &.{
                        cli.Command{
                            .name = "test",
                            .version = "0.2.0",
                            .description = "use this test",
                            .sub_commands = &.{
                                cli.Command{
                                    .name = "source",
                                    .version = "0.2.0",
                                    .description = "use this source",
                                    .sub_commands = &.{},
                                },
                            },
                        },
                    },
                },
            },
        },
    } };

    var argIter = try std.process.argsWithAllocator(alloc);
    defer argIter.deinit();

    const result = try cli.ArgumentParser.parseWithIterator(alloc, &root_cmd, &argIter);
    defer result.deinit();

    for (result.flags) |flag| {
        std.debug.print("Parsed command {s} with Flag {s} and value {any}", .{ result.cmd.name, flag.conf.long, flag.value });
    }
}
