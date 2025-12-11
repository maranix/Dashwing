const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const ascii = std.ascii;

const DELIMITER = "-";
const MAX_DELIMITER_COUNT = 2;
const MIN_DELIMITER_COUNT = 1;

pub const Flag = GenericOption(bool);

pub const Option = union(enum) {
    Usize: GenericOption(usize),
};

pub const OptionError = error{
    invalidLongOption,
    invalidShortOption,
    invalidDelimiterCount,
    mustContainOnlyAlphaNumChar,
};

pub const OptionConf = struct {
    const Self = @This();

    short: []const u8,
    long: []const u8,
    required: bool = false,

    fn validate(self: *const Self) OptionError!void {
        if (self.short.len > 1) {
            return OptionError.invalidShortOption;
        }

        if (self.long.len < 2) {
            return OptionError.invalidLongOption;
        }

        if (!ascii.isAlphanumeric(self.short[0])) {
            return OptionError.mustContainOnlyAlphaNumChar;
        }

        for (self.long) |char| {
            if (!ascii.isAlphanumeric(char)) {
                return OptionError.mustContainOnlyAlphaNumChar;
            }
        }
    }
};

pub fn GenericOption(comptime T: type) type {
    return struct {
        const Self = @This();

        conf: OptionConf,
        value: T = undefined,

        pub fn init(comptime conf: OptionConf) OptionError!Self {
            try conf.validate();

            return .{ .conf = conf };
        }

        pub fn initWithDefaultValue(comptime conf: OptionConf, comptime value: T) OptionError!Self {
            try conf.validate();

            return .{
                .conf = conf,
                .value = value,
            };
        }

        pub fn match(self: *const Self, arg: []const u8) OptionError!bool {
            const delimiterCount = mem.count(u8, arg, "-");

            const key = arg[delimiterCount..];

            if (delimiterCount == MIN_DELIMITER_COUNT) {
                return mem.eql(u8, self.conf.short, key);
            }

            if (delimiterCount == MAX_DELIMITER_COUNT) {
                return mem.eql(u8, self.conf.long, key);
            }

            return OptionError.invalidDelimiterCount;
        }
    };
}

pub fn isFlag(arg: []const u8) bool {
    const startsWithDelimiter = mem.startsWith(u8, arg, "-");
    const doesNotContainSeparator = (mem.indexOfScalar(u8, arg, '=') == null);

    return startsWithDelimiter and
        doesNotContainSeparator;
}

pub fn isCommand(arg: []const u8) bool {
    return !mem.startsWith(u8, arg, "-");
}

test "isCommand properly recognizes arg as Command" {
    try testing.expect(!isCommand("--test"));
    try testing.expect(isCommand("test"));
    try testing.expect(!isCommand("-test"));
}

test "isFlag properly recognizes arg as Flag" {
    try testing.expect(!isFlag("test"));
    try testing.expect(isFlag("--test"));
    try testing.expect(isFlag("-test"));
}

test "GenericOption properly matches with arg" {
    // Validation Tests
    try testing.expectError(OptionError.invalidShortOption, Flag.init(
        .{ .long = "test", .short = "test" },
    ));
    try testing.expectError(OptionError.invalidShortOption, Flag.initWithDefaultValue(
        .{ .long = "source", .short = "so" },
        false,
    ));
    try testing.expectError(OptionError.invalidLongOption, Flag.init(
        .{ .long = "t", .short = "t" },
    ));
    try testing.expectError(OptionError.mustContainOnlyAlphaNumChar, Flag.init(
        .{ .long = ".@", .short = "t" },
    ));
    try testing.expectError(OptionError.mustContainOnlyAlphaNumChar, Flag.init(
        .{ .long = "test.123", .short = "t" },
    ));
    try testing.expectError(OptionError.mustContainOnlyAlphaNumChar, Flag.init(
        .{ .long = "123@test", .short = "t" },
    ));
    try testing.expectError(OptionError.mustContainOnlyAlphaNumChar, Flag.init(
        .{ .long = "123", .short = "@" },
    ));

    var validationFlag =
        try Flag.init(.{ .long = "123", .short = "1" });

    try testing.expectEqualStrings(validationFlag.conf.long, "123");
    try testing.expectEqualStrings(validationFlag.conf.short, "1");

    validationFlag =
        try Flag.init(.{ .long = "test123", .short = "1" });
    try testing.expectEqualStrings(validationFlag.conf.long, "test123");
    try testing.expectEqualStrings(validationFlag.conf.short, "1");

    validationFlag =
        try Flag.init(.{ .long = "test", .short = "1" });
    try testing.expectEqualStrings(validationFlag.conf.long, "test");
    try testing.expectEqualStrings(validationFlag.conf.short, "1");

    // Usage Tests
    const option = try Flag.initWithDefaultValue(
        .{ .long = "test", .short = "t" },
        false,
    );

    try testing.expect(try option.match("--test"));
    try testing.expect(try option.match("-t"));

    try testing.expect(!try option.match("-test"));
    try testing.expect(!try option.match("--t"));

    try testing.expectError(OptionError.invalidDelimiterCount, option.match("---test"));
    try testing.expectError(OptionError.invalidDelimiterCount, option.match("---t"));
}
