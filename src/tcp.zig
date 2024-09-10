const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

pub const Packet = struct {
    version: u8,
    data: []const u8,

    const TCPError = error{
        VersionError,
    };

    const Self = @This();

    fn init(version: u8, data: []const u8) Packet {
        // len is just len of data, no flags
        assert(data.len <= 1024);
        return Packet{ .version = version, .data = data };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var buf = ArrayList(u8).init(allocator);
        defer buf.deinit();
        try buf.append(self.version);
        try buf.appendSlice(self.data);
        return buf.toOwnedSlice();
    }

    // takes encoded buffer ([]u8), constructs a packet
    pub fn decode(buf: []const u8) TCPError!Packet {
        if (buf[0] != 1) {
            return TCPError.VersionError;
        }
        return Packet.init(buf[0], buf[1..]);
    }
};
