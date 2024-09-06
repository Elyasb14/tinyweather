pub const Packet = struct {
    version: u8,
    len: usize,
    data: []const u8,

    const Self = @This();

    pub fn init(data: []u8) Packet {
        // len is just len of data, no flags
        return Packet{ .version = 1, .len = data.len, .data = data };
    }

    // pub fn encode(self: Self, buf: []u8) []u8 {
    //     buf[0] = self.version;
    //     buf[1] = @intFromBool(self.is_request);
    //     // use @memcpy here to copy self.data into buf
    //     @memcpy(buf[2..][0..self.data.len], self.data);
    //     return buf;
    // }
};
