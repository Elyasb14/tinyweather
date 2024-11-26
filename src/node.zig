const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const ArrayList = std.ArrayList;

fn handle_client(connection: net.Server.Connection, allocator: std.mem.Allocator) !void {
    var handler = tcp.ClientHandler.init(connection.stream);
    defer handler.deinit();
    while (true) {
        try handler.handle_request(allocator) orelse break;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const server_address = try net.Address.parseIp("127.0.0.1", 8080);
    var server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer server.deinit();
    std.log.info("\x1b[32mTCP Server listening on {}\x1b[0m", .{server_address});

    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{connection.address});

        // try handle_client(client_stream, allocator);
        const thread = try std.Thread.spawn(.{}, handle_client, .{ connection, allocator });
        thread.detach();
    }
}

const testing = std.testing;

test "Packet encoding and decoding" {
    const allocator = testing.allocator;

    const original_packet = tcp.Packet.init(1, .SensorRequest, &[_]u8{ 1, 2, 3 });
    const encoded = try original_packet.encode(allocator);
    defer allocator.free(encoded);

    const decoded = try tcp.Packet.decode(encoded);

    try testing.expectEqual(original_packet.version, decoded.version);
    try testing.expectEqual(original_packet.type, decoded.type);
    try testing.expectEqualSlices(u8, original_packet.data, decoded.data);
    try testing.expectEqualDeep(original_packet, decoded);
}

test "sensor request encoding and decoding" {
    const allocator = testing.allocator;

    const original_request = tcp.SensorRequest.init(&[_]tcp.SensorType{ tcp.SensorType.Hum, tcp.SensorType.Temp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try tcp.SensorRequest.decode(encoded_request, allocator);
    defer {
        allocator.free(decoded_request.sensors);
    }

    try testing.expectEqualSlices(tcp.SensorType, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}

test "sensor response encoding and decoding" {
    const allocator = testing.allocator;
    const original_request = tcp.SensorRequest.init(&[_]tcp.SensorType{ tcp.SensorType.Hum, tcp.SensorType.Temp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try tcp.SensorRequest.decode(encoded_request, allocator);
    defer allocator.free(decoded_request.sensors);

    try testing.expectEqualSlices(tcp.SensorType, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}

test "end to end" {
    const allocator = testing.allocator;
    const sensors = &[_]tcp.SensorType{ tcp.SensorType.Gas, tcp.SensorType.Temp };
    const sensor_request = tcp.SensorRequest.init(sensors);
    const encoded_sensor_request = try sensor_request.encode(allocator);
    defer allocator.free(encoded_sensor_request);
    try testing.expectEqualSlices(u8, encoded_sensor_request, &[_]u8{ 3, 0 });
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, encoded_sensor_request);
    const encoded_packet = try packet.encode(allocator);
    defer allocator.free(encoded_packet);
    const decoded_packet = try tcp.Packet.decode(encoded_packet);
    switch (decoded_packet.type) {
        .SensorRequest => {
            const decoded_request_packet = try tcp.SensorRequest.decode(decoded_packet.data, allocator);
            defer allocator.free(decoded_request_packet.sensors);
            try testing.expectEqualDeep(decoded_request_packet, sensor_request);
            const response_packet = tcp.SensorResponse.init(decoded_request_packet, undefined);
            const encoded_response_packet = try response_packet.encode(allocator);
            defer allocator.free(encoded_response_packet);
            const new_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response_packet);
            const new_packet_encoded = try new_packet.encode(allocator);
            defer allocator.free(new_packet_encoded);
            const new_packet_decoded = tcp.Packet.decode(new_packet_encoded);
            try testing.expectEqualDeep(new_packet, new_packet_decoded);
        },
        else => {},
    }
    try testing.expectEqualDeep(packet, decoded_packet);
}
