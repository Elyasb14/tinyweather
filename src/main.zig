const std = @import("std");
const net = std.net;
const print = std.debug.print;

const version = 1;

const Packet = struct {
    version: u8,
    is_request: bool,
    data: []const u8,

    const Self = @This();

    pub fn new(data: []u8, is_request: bool) Packet {
        return Packet{ .version = version, .data = data, .is_request = is_request };
    }

    pub fn encode(self: Self, buf: []u8) []u8 {
        std.debug.assert(self.version == 1);

        buf[0] = self.version;
        buf[1] = @intFromBool(self.is_request);
        // use @memcpy here to copy self.data into buf
    }
};

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa_alloc.deinit() == .ok);
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

        const packet = Packet.new(msg, true).encode();

        for (packet.data) |byte| {
            print("{c}\n", .{byte});
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
