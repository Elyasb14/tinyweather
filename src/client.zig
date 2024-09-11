const std = @import("std");
const print = std.debug.print;
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    const data = [_]u8{ 1, 0, 0, 0 };
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, &data);
    const encoded = try packet.encode(std.heap.page_allocator);

    var buf: [1024]u8 = undefined;
    _ = try stream.write(encoded);
    const n = try stream.read(&buf);

    print("Received: {any}\n", .{buf[0..n]});
}
