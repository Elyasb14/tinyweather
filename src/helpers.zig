const std = @import("std");

pub fn f32_to_bytes(val: f32) *const [4]u8 {
    const bytes = std.mem.toBytes(val);
    std.log.info("val: {any}, bytes: {any}", .{ val, bytes });
    return &bytes;
}

const testing = std.testing;

test "u8 to f32 and back" {
    const val: f32 = 10.3;
    const bytes = f32_to_bytes(val);
}
