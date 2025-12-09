const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Flag = GenericOption(bool);

pub const Option = union(enum) {
    Usize: GenericOption(usize),
};

pub const OptionConf = struct {
    short: []const u8,
    long: []const u8,
    required: bool = false,
};

pub fn GenericOption(comptime T: type) type {
    return struct {
        const Self = @This();

        conf: OptionConf,
        value: T = undefined,

        pub fn init(comptime conf: OptionConf) Self {
            return .{ .conf = conf };
        }

        pub fn initWithDefaultValue(comptime conf: OptionConf, comptime value: T) Self {
            return .{
                .conf = conf,
                .value = value,
            };
        }

        pub fn match(self: *const Self, arg: []const u8) bool {
            const delimiterCount = mem.count(u8, arg, "-");

            const shortKeyMatch = mem.eql(u8, self.conf.short, arg[delimiterCount..]);
            const longKeyMatch = mem.eql(u8, self.conf.long, arg[delimiterCount..]);

            return shortKeyMatch or longKeyMatch;
        }
    };
}

pub fn isFlag(arg: []const u8) bool {
    const startsWithDelimiter = mem.startsWith(u8, arg, "-");
    const doesNotContainSeparator = (mem.indexOfScalar(u8, arg, '=') == null);
    const hasAppropriateAmountOfDelims = mem.count(u8, arg, "-");

    return startsWithDelimiter and
        doesNotContainSeparator and
        ((hasAppropriateAmountOfDelims > 0) and
            (hasAppropriateAmountOfDelims < 3));
}

pub fn isCommand(arg: []const u8) bool {
    return !mem.startsWith(u8, arg, "-");
}
