const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const tcp = @import("tcp.zig");

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
            print("\x1b[31mclient wrote a bad packet, err: {any}\x1b[0m\n", .{err});
            return;
        };

        print("data recieved from stream: {any}\n", .{packet});

        switch (packet.type) {
            .SensorRequest => {
                // decode packet.data into SensorRequest struct
                const decoded = tcp.SensorRequest.decode(packet.data, allocator);
                print("decoded SensorRequest packet: {any}\n", .{decoded});
                // create response packet and encode it
                // send to client
            },
            else => {
                print("\x1b[31munexpected packet type: {any}\x1b[0m\n", .{packet.type});
                return;
            },
        }

        const encoded = try packet.encode(allocator);

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
