const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");
const ArrayList = std.ArrayList;

fn handle_client(stream: net.Stream, allocator: std.mem.Allocator) !void {
    defer {
        print("Stream closed: {any}\n", .{stream});
        stream.close();
    }

    var recv_buffer: [1024]u8 = undefined;

    while (true) {
        const bytes_read = try stream.read(&recv_buffer);
        if (bytes_read == 0) break; // Client disconnected

        const received_packet = tcp.Packet.decode(recv_buffer[0..bytes_read]) catch |err| {
            print("\x1b[31mClient wrote a bad packet, error\x1b[0m: {any}\n", .{err});
            return;
        };

        print("\x1b[32mPacket received from stream\x1b[0m: {any}\n", .{received_packet});

        switch (received_packet.type) {
            .SensorRequest => {
                const decoded_request = try tcp.SensorRequest.decode(received_packet.data, allocator);
                print("\x1b[32mDecoded SensorRequest packet\x1b[0m: {any}\n", .{decoded_request});

                const encoded_response = try tcp.SensorResponse.encode(tcp.SensorResponse{ .request = decoded_request }, allocator);
                print("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}\n", .{encoded_response});

                const response_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response);
                print("\x1b[32mPacket response to be sent to stream\x1b[0m: {any}\n", .{response_packet});

                const encoded_response_packet = try response_packet.encode(allocator);
                _ = try stream.write(encoded_response_packet);
            },
            else => {
                print("\x1b[31mUnexpected packet type\x1b[0m: {any}\n", .{received_packet.type});
                return;
            },
        }
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
    });

    defer server.deinit();
    print("Server listening on {}\n", .{server_address});

    while (true) {
        const connection = try server.accept();
        print("Connection established with: {any}\n", .{connection.address});
        const client_stream = connection.stream;

        try handle_client(client_stream, allocator);
    }
}
