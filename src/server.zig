const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const packet = @import("packet.zig");

fn handle_client(stream: net.Stream) !void {
    defer {
        print("stream closed: {any}\n", .{stream});
        stream.close();
    }
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try stream.read(&buf);
        if (n == 0) break; // Client disconnected
        const pkt = packet.Packet.init(buf[0..n]);

        print("len: {d}, data: {d}\n", .{ pkt.len, pkt.data });

        // how do I avoid allocating this enc_buf here?
        var enc_buf: [1025]u8 = undefined;
        const encoded = pkt.encode(&enc_buf);

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

test "test encode" {
    const data = [_]u8{ 'h', 'i' };
    var buf: [1024]u8 = undefined;
    const pkt = packet.Packet.init(&data);
    const encoded = pkt.encode(&buf);
    try std.testing.expectEqual(@as(usize, 3), encoded.len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 'h', 'i' }, encoded);
}

test "test buffer overflow" {
    const data = [_]u8{0} ** 1025; // Data larger than 1024
    try std.testing.expectError(error.AssertionError, packet.Packet.init(&data));
}
