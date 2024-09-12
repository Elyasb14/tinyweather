const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

pub const PacketType = enum(u8) {
    SensorRequest,
    SensorResponse,
};

pub const SensorType = enum(u8) {
    Temp,
    Pres,
    Hum,
    Gas,
};

const TCPError = error{
    VersionError,
    InvalidPacketType,
};

pub const Packet = struct {
    version: u8,
    type: PacketType,
    data: []const u8,

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
        assert(buf.len > 0);
        if (buf[0] != 1) {
            return TCPError.VersionError;
        }
        const packet_type = std.meta.intToEnum(PacketType, buf[1]) catch {
            return TCPError.InvalidPacketType;
        };
        return Packet.init(buf[0], packet_type, buf[2..]);
    }
};

pub const SensorRequest = struct {
    sensors: []const SensorType,

    const Self = @This();

    // pub fn init(sensors[

    pub fn encode(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var sensors = ArrayList(u8).init(allocator);
        defer sensors.deinit();
        for (self.sensors) |sensor| {
            try sensors.append(@intFromEnum(sensor));
        }
        return sensors.toOwnedSlice();
    }

    pub fn decode(buf: []const u8, allocator: std.mem.Allocator) !SensorRequest {
        var sensors = ArrayList(SensorType).init(allocator);
        for (buf) |x| {
            const sensor = try std.meta.intToEnum(SensorType, x);
            try sensors.append(sensor);
        }
        return SensorRequest{ .sensors = try sensors.toOwnedSlice() };
    }
};

pub const SensorData = struct { sensor_type: SensorType, val: f32 };

pub const SensorResponse = struct {
    data: ArrayList(u8),
    request: SensorRequest,

    const Self = @This();

    pub fn encode(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var buf = ArrayList(u8).init(allocator);
        for (self.request.sensors) |sensor| {
            switch (sensor) {
                .Gas => {
                    try buf.append(get_gas());
                },
                else => {
                    std.debug.print("failed", .{});
                },
            }
        }
        return buf.toOwnedSlice();
    }
    // pub fn decode(buf: []const u8) SensorResponse {}
};

fn get_gas() u8 {
    return 17;
}
