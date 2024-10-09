const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");
const ArrayList = std.ArrayList;
const helpers = @import("helpers.zig");
const serial = @import("serial");

fn handle_client(stream: net.Stream, allocator: std.mem.Allocator) !void {
    defer {
        std.log.debug("Stream closed: {any}", .{stream});
        stream.close();
    }

    var recv_buffer: [1024]u8 = undefined;

    while (true) {
        const bytes_read = try stream.read(&recv_buffer);
        if (bytes_read == 0) break;
        std.log.debug("\x1b[32mBytes read by connection\x1b[0m: {any}", .{bytes_read});
        const received_packet = tcp.Packet.decode(recv_buffer[0..bytes_read]) catch |err| {
            std.log.err("\x1b[31mClient wrote a bad packet, error\x1b[0m: {any}", .{err});
            return;
        };

        std.log.debug("\x1b[32mPacket received from stream\x1b[0m: {any}", .{received_packet});

        switch (received_packet.type) {
            .SensorRequest => {
                const decoded_request = try tcp.SensorRequest.decode(received_packet.data, allocator);

                std.log.debug("\x1b[32mDecoded Response Packet\x1b[0m: {any}", .{decoded_request});

                const sensor_response = tcp.SensorResponse.init(decoded_request, undefined);
                // std.log.debug("\x1b[32mSensorResponse packet\x1b[0m: {any}\n", .{sensor_response});
                const encoded_response = try sensor_response.encode(allocator);
                std.log.debug("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}", .{encoded_response});

                const response_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response);
                std.log.debug("\x1b[32mPacket response to be sent to stream\x1b[0m: {any}", .{response_packet});

                const encoded_response_packet = try response_packet.encode(allocator);
                _ = try stream.write(encoded_response_packet);
            },
            else => {
                std.log.err("\x1b[31mUnexpected packet type\x1b[0m: {any}", .{received_packet.type});
                return;
            },
        }
    }
}

pub fn main() !void {
    if (false) {
        var serial_fd = try std.fs.cwd().openFile("/dev/ttyUSB0", .{ .mode = .read_write });
        defer serial_fd.close();

        try serial.configureSerialPort(serial_fd, serial.SerialConfig{
            .baud_rate = 19200,
            .word_size = serial.WordSize.eight,
            .parity = .none,
            .stop_bits = .one,
            .handshake = .none,
        });
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const server_address = try net.Address.parseIp("127.0.0.1", 8080);
    var server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
    });

    defer server.deinit();
    std.log.debug("\x1b[32mServer listening on {}\x1b[0m", .{server_address});

    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.debug("\x1b[32mConnection established with\x1b[0m: {any}", .{connection.address});
        const client_stream = connection.stream;

        try handle_client(client_stream, allocator);
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
}

test "sensor request encoding and decoding" {
    const allocator = testing.allocator;

    const original_request = tcp.SensorRequest.init(&[_]tcp.SensorType{ tcp.SensorType.Hum, tcp.SensorType.Temp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request); // Free encoded_request

    const decoded_request = try tcp.SensorRequest.decode(encoded_request, allocator);
    defer {
        allocator.free(decoded_request.sensors); // Free decoded_request.sensors
    }

    try testing.expectEqualSlices(tcp.SensorType, original_request.sensors, decoded_request.sensors);
}

test "sensor response encoding and decoding" {
    const allocator = testing.allocator;
    const original_request = tcp.SensorRequest.init(&[_]tcp.SensorType{ tcp.SensorType.Hum, tcp.SensorType.Temp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try tcp.SensorRequest.decode(encoded_request, allocator);
    defer allocator.free(decoded_request.sensors);

    try testing.expectEqualSlices(tcp.SensorType, original_request.sensors, decoded_request.sensors);
}
