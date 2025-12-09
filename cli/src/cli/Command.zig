const std = @import("std");
const Argument = @import("Argument.zig");

const Flag = Argument.Flag;
const Option = Argument.Option;

const Self = @This();

name: []const u8,
version: []const u8,
description: []const u8,
flags: []const Flag = &.{},
options: []const Option = &.{},
sub_commands: []const Self = &.{},

pub fn hasFlag(self: *Self) bool {
    return self.flags.len > 0;
}

pub fn hasOption(self: *Self) bool {
    return self.options.len > 0;
}

pub fn hasSubCommand(self: *Self) bool {
    return self.sub_commands.len > 0;
}
