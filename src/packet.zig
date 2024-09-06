pub const Packet = struct {
    version: u8,
    len: usize,
    data: []const u8,

    const Self = @This();

    pub fn init(data: []const u8) Packet {
        // len is just len of data, no flags
        return Packet{ .version = 1, .len = data.len, .data = data };
    }

    pub fn encode(self: Self, buf: []u8) []u8 {
        buf[0] = self.version;
        @memcpy(buf[1..][0..self.len], self.data);
        return buf[0 .. self.len + 1];
    }
};
