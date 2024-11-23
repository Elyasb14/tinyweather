const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");

pub fn get_data(allocator: std.mem.Allocator, sensors: []const tcp.SensorType, stream: std.net.Stream) ![]tcp.SensorData {
    const sensor_request = tcp.SensorRequest.init(sensors);
    const sensor_request_encoded = try sensor_request.encode(allocator);
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, sensor_request_encoded);
    const encoded_packet = try packet.encode(allocator);

    var buf: [50]u8 = undefined;
    std.log.info("\x1b[32mPacket Sent\x1b[0m: {any}", .{packet});
    _ = try stream.write(encoded_packet);
    const n = try stream.read(&buf);
    std.log.info("\x1b[32mBytes read by stream\x1b[0m: {any}", .{n});
    const decoded_packet = try tcp.Packet.decode(buf[0..n]);
    switch (decoded_packet.type) {
        .SensorResponse => {
            const decoded_sensor_response = try tcp.SensorResponse.decode(sensor_request, decoded_packet.data, allocator);
            std.log.info("\x1b[32mSensor Response Packet Received\x1b[0m: {any}", .{decoded_sensor_response});
            const sensor_data = decoded_sensor_response.data;
            return sensor_data;
        },
        .SensorRequest => {
            std.log.err("Expected SensorResponse, got SensorRequest: {any}", .{decoded_packet});
            return tcp.TCPError.InvalidPacketType;
        },
    }
}

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = net.tcpConnectToAddress(address) catch |err| {
        std.log.err("Can't connect to address: {any}... error: {any}", .{ address, err });
        return error.ConnectionRefused;
    };
    std.log.info("\x1b[32mClient initializing communication with: {any}....\x1b[0m", .{address});
    defer stream.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sensors = [_]tcp.SensorType{ tcp.SensorType.RainTotalAcc, tcp.SensorType.Temp };
    const sensor_data = try get_data(allocator, &sensors, stream);
    std.debug.print("DATA RECEIVED\n\n", .{});
    for (sensor_data) |sensor| {
        std.debug.print("Sensor: {any}, Val: {d}\n", .{ sensor.sensor_type, sensor.val });
    }
}
