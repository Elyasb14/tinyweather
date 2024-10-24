const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const helpers = @import("helpers.zig");
const Allocator = std.mem.Allocator;

pub const PacketType = enum(u8) { SensorRequest, SensorResponse, Error };
pub const SensorType = enum(u8) { Temp, Pres, Hum, Gas };
const TCPError = error{ VersionError, InvalidPacketType, InvalidSensorType };

pub const Packet = struct {
    version: u8,
    type: PacketType,
    data: []const u8,

    const Self = @This();

    pub fn init(version: u8, packet_type: PacketType, data: []const u8) Packet {
        assert(data.len <= 50);

        return Packet{ .version = version, .type = packet_type, .data = data };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) Allocator.Error![]u8 {
        var buf = ArrayList(u8).init(allocator);
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
        const packet_type = @as(PacketType, @enumFromInt(buf[1]));
        return Packet.init(buf[0], packet_type, buf[2..]);
    }
};

pub const SensorRequest = struct {
    sensors: []const SensorType,

    const Self = @This();

    pub fn init(sensors: []const SensorType) SensorRequest {
        return SensorRequest{ .sensors = sensors };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) Allocator.Error![]const u8 {
        var sensors = ArrayList(u8).init(allocator);
        for (self.sensors) |sensor| {
            try sensors.append(@intFromEnum(sensor));
        }
        return try sensors.toOwnedSlice();
    }

    pub fn decode(buf: []const u8, allocator: std.mem.Allocator) Allocator.Error!SensorRequest {
        var sensors = ArrayList(SensorType).init(allocator);
        for (buf) |x| {
            const sensor = @as(SensorType, @enumFromInt(x));
            try sensors.append(sensor);
        }
        return SensorRequest.init(try sensors.toOwnedSlice());
    }
};

pub const SensorData = struct { sensor_type: SensorType, val: f32 };

pub const SensorResponse = struct {
    request: SensorRequest,
    data: []SensorData,

    const Self = @This();

    pub fn init(request: SensorRequest, data: []SensorData) SensorResponse {
        return SensorResponse{
            .request = request,
            .data = data,
        };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) Allocator.Error![]const u8 {
        var buf = ArrayList(u8).init(allocator);
        for (self.request.sensors) |sensor| {
            switch (sensor) {
                .Gas => {
                    try buf.appendSlice(&get_gas());
                },
                .Temp => {
                    try buf.appendSlice(&get_temp());
                },
                .Pres => {
                    try buf.appendSlice(&get_pres());
                },
                .Hum => {
                    try buf.appendSlice(&get_hum());
                },
            }
        }
        return try buf.toOwnedSlice();
    }
    pub fn decode(request: SensorRequest, buf: []const u8, allocator: std.mem.Allocator) Allocator.Error!SensorResponse {
        var dec_buf = ArrayList(SensorData).init(allocator);
        var offset: usize = 0;
        for (request.sensors) |sensor| {
            if (offset + 4 > buf.len) break;
            const chunk = buf[offset .. offset + 4];
            const data = helpers.bytes_to_f32(chunk);
            try dec_buf.append(SensorData{ .sensor_type = sensor, .val = data });
            offset += 4;
        }
        const data = try dec_buf.toOwnedSlice();
        return SensorResponse.init(request, data);
    }
};

fn get_gas() [4]u8 {
    return helpers.f32_to_bytes(172.34);
}

fn get_temp() [4]u8 {
    return helpers.f32_to_bytes(17.2);
}

fn get_hum() [4]u8 {
    return helpers.f32_to_bytes(111.17);
}

fn get_pres() [4]u8 {
    return helpers.f32_to_bytes(1111.4);
}
