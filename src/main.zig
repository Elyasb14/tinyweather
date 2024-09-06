const std = @import("std");
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;

const version = 1;

const Packet = struct {
    version: u8,
    is_request: bool,
    len: usize,
    data: []const u8,

    const Self = @This();

    pub fn new(data: []u8) Packet {
        return data;
    }

    pub fn encode(self: Self, buf: []u8) []u8 {
        buf[0] = self.version;
        buf[1] = @intFromBool(self.is_request);
        // use @memcpy here to copy self.data into buf
        @memcpy(buf[2..][0..self.data.len], self.data);
        return buf;
    }
};

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();

    const addr = std.net.Address.initIp4(.{ 0, 0, 0, 0 }, 3667);
    var server = try addr.listen(.{});

    std.log.info("Server listening on port 3667", .{});

    var client = try server.accept();
    defer client.stream.close();

    const client_reader = client.stream.reader();
    // const client_writer = client.stream.writer();
    while (true) {
        //this is []u8
        const msg = try client_reader.readUntilDelimiterOrEofAlloc(gpa, '\n', 65536) orelse break;
        defer gpa.free(msg);

        const packet = Packet.new(msg);
        var buf: [1024]u8 = undefined;
        const encoded = packet.encode(&buf);
        print("{c}", .{encoded});
    }
}

test "test encode" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
