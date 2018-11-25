const std = @import("std");

// https://gist.github.com/daurnimator/039529a207cbdf3c9360e787a6141c4c
pub fn stringToEnum(comptime T: type, str: []const u8) ?T {
    inline for (@typeInfo(T).Enum.fields) |enumField| {
        if (std.mem.eql(u8, str, enumField.name)) {
            return @intToEnum(T, @intCast(@TagType(T), enumField.value));
        }
    }
    return null;
}
