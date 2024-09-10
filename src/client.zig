const std = @import("std");
const print = std.debug.print;
const net = std.net;
const assert = std.debug.assert;

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    const data = [_]u8{ 1, 0, 0, 0 };

    var buf: [1024]u8 = undefined;
    _ = try stream.write(&data);
    const n = try stream.read(&buf);

    print("Received: {any}\n", .{buf[0..n]});
}
