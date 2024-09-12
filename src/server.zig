const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");
const ArrayList = std.ArrayList;

fn handle_client(stream: net.Stream) !void {
    defer {
        print("stream closed: {any}\n", .{stream});
        stream.close();
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try stream.read(&buf);
        if (n == 0) break; // Client disconnected

        const packet = tcp.Packet.decode(buf[0..n]) catch |err| {
            print("\x1b[31mclient wrote a bad packet, err\x1b[0m: {any}\n", .{err});
            return;
        };

        print("\x1b[32mPacket from stream\x1b[0m: {any}\n", .{packet});

        switch (packet.type) {
            .SensorRequest => {
                // decode packet.data into SensorRequest struct
                const decoded_request = try tcp.SensorRequest.decode(packet.data, allocator);
                print("\x1b[32mDecoded SensorRequest packet\x1b[0m: {any}\n", .{decoded_request});
                // create response packet and encode it
                const encoded_buf = ArrayList(u8).init(allocator);
                const encoded_response = try tcp.SensorResponse.encode(tcp.SensorResponse{ .request = decoded_request, .data = encoded_buf }, allocator);
                print("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}\n", .{encoded_response});
                const response_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response);
                print("\x1b[32mPacket response sent to stream\x1b[0m: {any}\n", .{response_packet});
                const response_encoded_packet = try response_packet.encode(allocator);
                _ = try stream.write(response_encoded_packet);
            },
            else => {
                print("\x1b[31munexpected packet type\x1b[0m: {any}\n", .{packet.type});
                return;
            },
        }
    }
}

pub fn main() !void {
    const address = try net.Address.parseIp("127.0.0.1", 8080);
    var server = try net.Address.listen(address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
    });
    defer server.deinit();
    print("server listening on {}\n", .{address});
    while (true) {
        const conn = try server.accept();
        print("connection by: {any}\n", .{conn.address});
        const stream = conn.stream;

        try handle_client(stream);
    }
}
