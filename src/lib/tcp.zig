const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const device = @import("device.zig");
const helpers = @import("helpers.zig");
const net = std.net;

pub const PacketType = enum(u8) { SensorRequest, SensorResponse };
pub const Sensors = enum(u8) { BME680, RG15, BFROBOT };
pub const SensorVals = enum(u8) { BMETempemp, BMEPresres, BMEHumHum, BMEGasGas, RG15RainAccnAcc, RG15RainEventAcctAcc, RG15RainTotalAcclAcc, RG15RainRInt };
pub const TCPError = error{ VersionError, InvalidPacketType, InvalidSensor, DeviceError, BadPacket, ConnectionError };

pub const Packet = struct {
    version: u8,
    type: PacketType,
    data: []const u8,

    const Self = @This();

    pub fn init(version: u8, packet_type: PacketType, data: []const u8) Packet {
        assert(data.len <= 50);

        if (data.len == 0) {
            std.log.warn("\x1b[33mTrying to construct a packet with no data, did you forget http headers? Why would we be trying to do this?\x1b[0m", .{});
        }

        return Packet{ .version = version, .type = packet_type, .data = data };
    }

    pub fn encode(self: Self, allocator: std.mem.Allocator) Allocator.Error![]u8 {
        var buf = ArrayList(u8).init(allocator);
        try buf.append(self.version);
        try buf.append(@intFromEnum(self.type));
        try buf.appendSlice(self.data);
        return buf.toOwnedSlice();
    }

    /// takes encoded buffer ([]const u8), constructs a packet
    pub fn decode(buf: []const u8) TCPError!Packet {
        assert(buf.len > 0);
        if (buf[0] != 1) return TCPError.VersionError;
        const packet_type = @as(PacketType, @enumFromInt(buf[1]));
        return Packet.init(buf[0], packet_type, buf[2..]);
    }
};

pub const SensorRequest = struct {
    sensors: []const Sensors,

    const Self = @This();

    pub fn init(sensors: []const Sensors) SensorRequest {
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
        var sensors = ArrayList(Sensors).init(allocator);
        for (buf) |x| {
            const sensor = @as(Sensors, @enumFromInt(x));
            try sensors.append(sensor);
        }
        return SensorRequest.init(try sensors.toOwnedSlice());
    }
};

pub const SensorData = struct { sensor_type: Sensors, val: f32 };

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

    pub fn encode(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        var buf = ArrayList(u8).init(allocator);

        for (self.request.sensors) |sensor| {
            switch (sensor) {
                .RG15 => {
                    const rain_data: []const f32 = (try device.parse_rain(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;
                    for (rain_data) |x| {
                        try buf.appendSlice(&helpers.f32_to_bytes(x));
                    }
                },
                .BME680 => {
                    const bme_data: []const f32 = (try device.parse_bme(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;
                    for (bme_data) |x| {
                        try buf.appendSlice(&helpers.f32_to_bytes(x));
                    }
                },
                .BFROBOT => {
                    const bfrobot_data: []const f32 = (try device.parse_bme(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;
                    for (bfrobot_data) |x| {
                        try buf.appendSlice(&helpers.f32_to_bytes(x));
                    }

                    try buf.appendSlice(&helpers.f32_to_bytes(std.math.nan(f32)));
                    try buf.appendSlice(&helpers.f32_to_bytes(std.math.nan(f32)));
                },
            }
        }

        // const rain_data: []const f32 = (try device.parse_rain(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;
        // const bme_data: []const f32 = (try device.parse_bme(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;

        // var buf = ArrayList(u8).init(allocator);

        // for (self.request.sensors) |sensor| {
        //     switch (sensor) {
        //         .BMEGas => try buf.appendSlice(&helpers.f32_to_bytes(bme_data[3])),
        //         .BMETemp => try buf.appendSlice(&helpers.f32_to_bytes(bme_data[0])),
        //         .BMEPres => try buf.appendSlice(&helpers.f32_to_bytes(bme_data[1])),
        //         .BMEHum => try buf.appendSlice(&helpers.f32_to_bytes(bme_data[2])),
        //         .RG15RainAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[0])),
        //         .RG15RainEventAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[1])),
        //         .RG15RainTotalAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[2])),
        //         .RG15RainRInt => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[3])),
        //     }
        // }
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

const testing = std.testing;

test "Packet encoding and decoding" {
    const allocator = testing.allocator;

    const original_packet = Packet.init(1, .SensorRequest, &[_]u8{ 1, 2, 3 });
    const encoded = try original_packet.encode(allocator);
    defer allocator.free(encoded);

    const decoded = try Packet.decode(encoded);

    try testing.expectEqual(original_packet.version, decoded.version);
    try testing.expectEqual(original_packet.type, decoded.type);
    try testing.expectEqualSlices(u8, original_packet.data, decoded.data);
    try testing.expectEqualDeep(original_packet, decoded);
}

test "sensor request encoding and decoding" {
    const allocator = testing.allocator;

    const original_request = SensorRequest.init(&[_]SensorVals{ SensorVals.BMEHum, SensorVals.BMETemp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try SensorRequest.decode(encoded_request, allocator);
    defer {
        allocator.free(decoded_request.sensors);
    }

    try testing.expectEqualSlices(SensorVals, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}

test "sensor response encoding and decoding" {
    const allocator = testing.allocator;
    const original_request = SensorRequest.init(&[_]SensorVals{ SensorVals.BMEHum, SensorVals.BMETemp });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try SensorRequest.decode(encoded_request, allocator);
    defer allocator.free(decoded_request.sensors);

    try testing.expectEqualSlices(SensorVals, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}
