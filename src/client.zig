const std = @import("std");
const print = std.debug.print;
const net = std.net;
const packet = @import("packet.zig");
const assert = std.debug.assert;

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    const data = [_]u8{0} ** 3;
    const pkt = packet.Packet.init(&data);

    var enc_buf: [1025]u8 = undefined;
    const encoded = pkt.encode(&enc_buf);
    _ = try stream.write(encoded);
    const n = try stream.read(&enc_buf);

    const rec_packet = packet.Packet.decode(enc_buf[0..n]);

    print("Received: {any}\n", .{rec_packet});
}
