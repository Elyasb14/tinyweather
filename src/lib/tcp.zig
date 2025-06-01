const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const device = @import("device.zig");
const helpers = @import("helpers.zig");
const net = std.net;

pub const PacketType = enum(u8) { SensorRequest, SensorResponse, Error };
pub const Sensors = enum(u8) {
    BME680,
    RG15,
    BFROBOT,
    ERROR,

    pub fn get_len_sensor_values(self: Sensors) u8 {
        switch (self) {
            .BME680 => return 4,
            .RG15 => return 4,
            .BFROBOT => return 2,
            .ERROR => return 0,
        }
    }
};
pub const SensorVals = enum(u8) { BMETemp, BMEPres, BMEHum, BMEGas, RG15RainAcc, RG15RainEventAcc, RG15RainTotalAcc, RG15RainRInt, BFRobotTemp, BFRobotHum, Error };
pub const TCPError = error{ VersionError, InvalidPacketType, InvalidSensor, DeviceError, BadPacket, ConnectionError };

pub const Packet = struct {
    version: u8,
    type: PacketType,
    data: []const u8,

    const Self = @This();

    pub fn init(version: u8, packet_type: PacketType, data: []const u8) Packet {
        assert(data.len >= 0);

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
        const packet_type = std.meta.intToEnum(PacketType, buf[1]) catch PacketType.Error;
        // const packet_type = @as(PacketType, @enumFromInt(buf[1]));
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
            // const sensor = @as(Sensors, @enumFromInt(x));
            const sensor = std.meta.intToEnum(Sensors, x) catch Sensors.ERROR;
            try sensors.append(sensor);
        }
        return SensorRequest.init(try sensors.toOwnedSlice());
    }
};

pub const SensorData = struct {
    sensor_type: Sensors,
    val: []const f32,

    const Self = @This();

    pub fn get_sensor_value_names(self: *Self) []const SensorVals {
        return switch (self.sensor_type) {
            .BME680 => &[_]SensorVals{
                .BMETemp,
                .BMEPres,
                .BMEHum,
                .BMEGas,
            },
            .RG15 => &[_]SensorVals{
                .RG15RainAcc,
                .RG15RainEventAcc,
                .RG15RainTotalAcc,
                .RG15RainRInt,
            },
            .BFROBOT => &[_]SensorVals{
                .BFRobotTemp,
                .BFRobotHum,
            },
            .ERROR => {
                std.log.err("\x1b[33mTried to decode error sensor\x1b[0m", .{});
                return &[_]SensorVals{.Error};
            },
        };
    }
};

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
                    const rain_data: []const f32 = (try device.parse_rg15(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;
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
                    const bfrobot_data: []const f32 = (try device.parse_bfrobot(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 2;
                    for (bfrobot_data) |x| {
                        try buf.appendSlice(&helpers.f32_to_bytes(x));
                    }
                },
                .ERROR => {
                    std.log.err("\x1b[33mTried to decode error sensor\x1b[0m", .{});
                    continue;
                },
            }
        }

        return try buf.toOwnedSlice();
    }
    pub fn decode(request: SensorRequest, buf: []const u8, allocator: std.mem.Allocator) Allocator.Error!SensorResponse {
        var dec_buf = ArrayList(SensorData).init(allocator);

        // TODO: this feels hacky can we do better
        var offset: usize = 0;
        for (request.sensors) |sensor| {
            const len_sensor_values = sensor.get_len_sensor_values();
            const buf_len = len_sensor_values * 4;
            if (offset + buf_len > 4 + buf.len) break;

            var values = try allocator.alloc(f32, len_sensor_values);

            for (0..buf_len / 4) |i| {
                const chunk = buf[offset + (i * 4) .. offset + (i * 4) + 4];
                values[i] = helpers.bytes_to_f32(chunk);
            }

            try dec_buf.append(SensorData{ .sensor_type = sensor, .val = values });
            offset += buf_len;
        }

        const data = try dec_buf.toOwnedSlice();
        return SensorResponse.init(request, data);
    }
};

const testing = std.testing;

test "Packet encoding and decoding" {
    const allocator = testing.allocator;

    const original_packet = Packet.init(1, .SensorRequest, &[_]u8{ 1, 2, 3, 18 });
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

    const original_request = SensorRequest.init(&[_]Sensors{ .RG15, .BME680 });
    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try SensorRequest.decode(encoded_request, allocator);
    defer {
        allocator.free(decoded_request.sensors);
    }

    try testing.expectEqualSlices(Sensors, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}

test "sensor response encoding and decoding" {
    const allocator = testing.allocator;
    const original_request = SensorRequest.init(&[_]Sensors{ .BME680, .RG15 });

    const encoded_request = try original_request.encode(allocator);
    defer allocator.free(encoded_request);

    const decoded_request = try SensorRequest.decode(encoded_request, allocator);
    defer allocator.free(decoded_request.sensors);

    try testing.expectEqualSlices(Sensors, original_request.sensors, decoded_request.sensors);
    try testing.expectEqualDeep(original_request, decoded_request);
}

test "give bad enum number" {
    const allocator = testing.allocator;

    const original_packet = Packet.init(1, .SensorRequest, &[_]u8{ 1, 2, 3, 17 });
    const encoded = try original_packet.encode(allocator);
    defer allocator.free(encoded);

    const decoded = try Packet.decode(encoded);

    try testing.expectEqual(original_packet.version, decoded.version);
    try testing.expectEqual(original_packet.type, decoded.type);
    try testing.expectEqualSlices(u8, original_packet.data, decoded.data);
    try testing.expectEqualDeep(original_packet, decoded);
}
