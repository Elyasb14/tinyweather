const tcp = @import("tcp");
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const original_packet = tcp.Packet.init(1, .SensorRequest, &[_]u8{ 1, 2, 3 });
    const encoded = try original_packet.encode(allocator);
    const decoded = try tcp.Packet.decode(encoded);
    std.debug.print("{any}\n", .{decoded});
}
