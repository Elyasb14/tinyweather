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

    const sensors = &[_]tcp.SensorType{ tcp.SensorType.Gas, tcp.SensorType.Temp };
    const sensor_request = tcp.SensorRequest.init(sensors);
    const sensor_request_encoded = try sensor_request.encode(allocator);
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, sensor_request_encoded);
    const encoded_packet = try packet.encode(allocator);

    var buf: [1024]u8 = undefined;
    print("\x1b[32mPacket Sent\x1b[0m: {any}\n", .{packet});
    _ = try stream.write(encoded_packet);
    const n = try stream.read(&buf);
    const decoded_packet = try tcp.Packet.decode(buf[0..n]);
    const decoded_sensor_response = try tcp.SensorResponse.decode(sensor_request, decoded_packet.data, allocator);

    print("\x1b[32mPacket Received\x1b[0m: {any}\n", .{decoded_sensor_response});
}
