const std = @import("std");
const net = std.net;
const packet = @import("packet.zig");

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    const data = [_]u8{ 'h', 'i' };
    const pkt = packet.Packet.init(&data);

    var buf: [1024]u8 = undefined;
    const encoded = pkt.encode(&buf);
    _ = try stream.write(encoded);
}
