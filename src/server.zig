const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const tcp = @import("tcp.zig");

fn handle_client(stream: net.Stream) !void {
    defer {
        print("stream closed: {any}\n", .{stream});
        stream.close();
    }
    var buf: [1024]u8 = undefined;
    var enc_buf: [1024]u8 = undefined;

    while (true) {
        const n = try stream.read(&buf);
        if (n == 0) break; // Client disconnected
        const data = buf[0..n];

        const packet = tcp.Packet.decode(data);

        print("data recieved from stream: {any}\n", .{packet});

        const encoded = packet.encode(&enc_buf);

        _ = try stream.write(encoded);
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
