const std = @import("std");
const print = std.debug.print;
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");
const ArrayList = std.ArrayList;

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const req_enc = tcp.SensorRequest{ .sensors = &[_]tcp.SensorType{ tcp.SensorType.Gas, tcp.SensorType.Temp } };
    const data = try req_enc.encode(std.heap.page_allocator);
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, data);
    const encoded = try packet.encode(std.heap.page_allocator);

    var buf: [1024]u8 = undefined;
    print("\x1b[32mPacket Sent\x1b[0m: {any}\n", .{packet});
    _ = try stream.write(encoded);
    const n = try stream.read(&buf);
    const decoded = try tcp.Packet.decode(buf[0..n]);
    const decoded_sensor_response = try tcp.SensorResponse.decode(req_enc, decoded.data, allocator);

    print("\x1b[32mPacket Received\x1b[0m: {any}\n", .{decoded_sensor_response});
}
