const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Colors = enum { Green, Red };

pub fn color_string(str: []const u8, color: Colors, allocator: Allocator) ![]const u8 {
    switch (color) {
        .Green => {
            return try std.fmt.allocPrint(allocator, "{s}{s}{s}\n", .{ "\x1b[31m", str, "\x1b[0m" });
        },
        else => {
            return "hello";
        },
    }
}
pub fn f32_to_bytes(val: f32) *const [4]u8 {
    const bytes = std.mem.toBytes(val);
    std.log.info("val: {any}, bytes: {any}", .{ val, bytes });
    return &bytes;
}
