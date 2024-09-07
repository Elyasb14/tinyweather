const std = @import("std");
const assert = std.debug.assert;

pub const Packet = struct {
    version: u8,
    len: usize,
    data: []const u8,

    const Self = @This();

    pub fn init(data: []const u8) Packet {
        // len is just len of data, no flags
        assert(data.len <= 1024);
        return Packet{ .version = 1, .len = data.len, .data = data };
    }

    pub fn encode(self: Self, buf: []u8) []u8 {
        buf[0] = self.version;
        @memcpy(buf[1..][0..self.len], self.data);
        return buf[0 .. self.len + 1];
    }

    // takes encoded buffer ([]u8), constructs a packet
    pub fn decode(enc_buf: []u8) Packet {
        assert(enc_buf[0] == 1);
        return Packet.init(enc_buf[1..]);
    }
};
