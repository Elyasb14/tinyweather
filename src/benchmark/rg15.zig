const device = @import("../device.zig");
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const data = device.parse_rain(allocator);
    std.debug.print("{any}", .{data});
}
