const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const packet = @import("packet.zig");

fn handle_client(stream: net.Stream) !void {
    defer stream.close();
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try stream.read(&buf);
        if (n == 0) break; // Client disconnected
        const data = buf[0 .. n - 1]; // subtract 1 to not include new line
        const pkt = packet.Packet.init(data);

        print("len: {d}, data: {d}\n", .{ pkt.len, pkt.data });

        _ = try stream.write(buf[0..n]);
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
        const stream = conn.stream;

        try handle_client(stream);
    }
}

test "test encode" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
