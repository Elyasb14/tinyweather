// this file can only import from the zig standard library
// no dependencies on tinyweather internals

const std = @import("std");

const Allocator = std.mem.Allocator;
pub fn f32_to_bytes(value: f32) [4]u8 {
    return std.mem.toBytes(value);
}

pub fn bytes_to_f32(bytes: []const u8) f32 {
    return std.mem.bytesToValue(f32, bytes);
}

const testing = std.testing;
test "test type safety" {
    const val: f32 = 10.4;
    const bytes = f32_to_bytes(val);
    const casted_f32 = bytes_to_f32(&bytes);
    try testing.expectEqual(@TypeOf(val), @TypeOf(casted_f32));
    try testing.expectEqual(@TypeOf(bytes), [4]u8);
}

test "convert f32 to bytes and back" {
    const val1 = 10.32;
    const val2 = 10.22223435;
    const val3 = -1000.32;
    const val4 = 1000000.33;

    const bytes1 = f32_to_bytes(val1);
    const bytes2 = f32_to_bytes(val2);
    const bytes3 = f32_to_bytes(val3);
    const bytes4 = f32_to_bytes(val4);

    try testing.expectEqual(bytes_to_f32(&bytes1), val1);
    try testing.expectEqual(bytes_to_f32(&bytes2), val2);
    try testing.expectEqual(bytes_to_f32(&bytes3), val3);
    try testing.expectEqual(bytes_to_f32(&bytes4), val4);
}
