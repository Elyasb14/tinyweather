const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const Packet = struct {
    version: u8,
    len: usize,
    packet_type: PktType,
    data: []const u8,

    const PktType = enum {
        request,
        response,
    };

    const Self = @This();

    pub fn init(data: []u8, pkt_type: PktType) Packet {
        return Packet{ .version = 1, .len = data.len + 1, .packet_type = pkt_type, .data = data };
    }

    // pub fn encode(self: Self, buf: []u8) []u8 {
    //     buf[0] = self.version;
    //     buf[1] = @intFromBool(self.is_request);
    //     // use @memcpy here to copy self.data into buf
    //     @memcpy(buf[2..][0..self.data.len], self.data);
    //     return buf;
    // }
};

fn handle_client(stream: net.Stream) !void {
    defer stream.close();
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try stream.read(&buf);
        if (n == 0) break; // Client disconnected
        const data = buf[0..n];
        const packet = Packet.init(data, Packet.PktType.request);
        print("len: {}, data: {c}", .{ packet.len, packet.data });

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
