const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

pub const PacketType = enum(u8) {
    SensorRequest,
    SensorResponse,
    Error,
};

pub const Packet = struct {
    version: u8,
    type: PacketType,
    data: []const u8,

    const TCPError = error{
        VersionError,
        InvalidPacketType,
    };

    const Self = @This();

    pub fn init(version: u8, packet_type: PacketType, data: []const u8) Packet {
        // len is just len of data, no flags
        assert(data.len <= 1024);

        return Packet{ .version = version, .type = packet_type, .data = data };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var buf = ArrayList(u8).init(allocator);
        defer buf.deinit();
        try buf.append(self.version);
        try buf.append(@intFromEnum(self.type));
        try buf.appendSlice(self.data);
        return buf.toOwnedSlice();
    }

    // takes encoded buffer ([]u8), constructs a packet
    pub fn decode(buf: []const u8) TCPError!Packet {
        if (buf[0] != 1) {
            return TCPError.VersionError;
        }
        const packet_type = std.meta.intToEnum(PacketType, buf[1]) catch {
            return TCPError.InvalidPacketType;
        };
        return Packet.init(buf[0], packet_type, buf[2..]);
    }
};
