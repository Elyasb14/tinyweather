const std = @import("std");
const assert = std.debug.assert;

pub const Packet = struct {
    version: u8,
    data: []const u8,

    const Self = @This();

    fn init(version: u8, data: []const u8) Packet {
        // len is just len of data, no flags
        assert(data.len <= 1024);
        return Packet{ .version = version, .data = data };
    }

    pub fn encode(self: Self) []u8 {
        buf[0] = self.version;
        buf.a
    }

    // takes encoded buffer ([]u8), constructs a packet
    pub fn decode(buf: []const u8) Packet {
        assert(buf[0] == 1);
        return Packet.init(buf[0], buf[1..]);
    }
};
