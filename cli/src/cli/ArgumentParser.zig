/// Semi-Based on The Open Group Base Specifications Issue 8 (IEEE Std 1003.1-2024)
///
/// https://pubs.opengroup.org/onlinepubs/9799919799/
///
///
/// Note: not fully complaint with the standard
///
const std = @import("std");
const Argument = @import("Argument.zig");
const mem = std.mem;
const testing = std.testing;

const Command = @import("Command.zig");
const ArgIterator = std.process.ArgIterator;
const Allocator = mem.Allocator;
const Flag = Argument.Flag;

pub const ParserError = error{ CommandNotFound, FlagNotFound } || Allocator.Error;

pub const ParserResult = struct {
    const Self = @This();

    alloc: Allocator,
    rawArgs: [][]const u8,
    cmd: *const Command,
    flags: []const Flag,

    pub fn deinit(self: *const Self) void {
        self.alloc.free(self.rawArgs);
    }
};

// TODO: Complete this implementation
pub fn parse(alloc: Allocator, root_cmd: *const Command, args: [][]const u8) ParserError!ParserResult {
    return .{ .alloc = alloc, .cmd = root_cmd, .rawArgs = args, .flags = &.{} };
}

pub fn parseWithIterator(alloc: Allocator, root_cmd: *const Command, iter: *ArgIterator) ParserError!ParserResult {
    var argCollection = std.ArrayList([]const u8).empty;
    defer argCollection.deinit(alloc);

    var flagCollection = std.ArrayList(Argument.Flag).empty;
    defer flagCollection.deinit(alloc);

    // Skip the first one since its the binary
    _ = iter.skip();

    var cmd = root_cmd;
    var terminateOptionParsing = false;

    argLoop: while (iter.next()) |arg| {
        try argCollection.append(alloc, arg);

        if (mem.eql(u8, arg, "--")) {
            terminateOptionParsing = true;
            continue;
        }

        if (Argument.isCommand(arg)) {
            for (cmd.sub_commands) |*sub_cmd| {
                if (mem.eql(u8, sub_cmd.name, arg)) {
                    cmd = sub_cmd;
                    continue :argLoop;
                }
            }

            return ParserError.CommandNotFound;
        }

        if (Argument.isFlag(arg)) {
            // TODO: Prone to order based errors (This assumes that commands are provided first)
            //
            // In case commands are alternated with flags, this will fail.
            try flagCollection.appendSlice(alloc, cmd.flags);

            for (flagCollection.items) |*flag| {
                if (flag.match(arg)) {
                    flag.value = true;
                    continue :argLoop;
                }
            }

            return ParserError.FlagNotFound;
        }
        // If this is not a Flag then it is an Option.
        //
        // TODO: Implement Option Parsing
        else {}

        // These are positional options
        //
        // TODO: Parse these as well
        if (terminateOptionParsing) {}
    }

    const args = try argCollection.toOwnedSlice(alloc);
    const flags = try flagCollection.toOwnedSlice(alloc);

    return .{ .alloc = alloc, .rawArgs = args, .cmd = cmd, .flags = flags };
}
