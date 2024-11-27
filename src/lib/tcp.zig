const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const device = @import("device.zig");
const helpers = @import("helpers.zig");
const net = std.net;

pub const PacketType = enum(u8) { SensorRequest, SensorResponse };
pub const SensorType = enum(u8) { Temp, Pres, Hum, Gas, RainAcc, RainEventAcc, RainTotalAcc, RainRInt };
pub const TCPError = error{ VersionError, InvalidPacketType, InvalidSensorType, DeviceError, BadPacket, ConnectionError };

pub const ClientHandler = struct {
    stream: net.Stream,

    pub fn init(stream: net.Stream) ClientHandler {
        return .{
            .stream = stream,
        };
    }

    pub fn deinit(self: *ClientHandler) void {
        std.log.info("Stream closed: {any}", .{self.stream});
        self.stream.close();
    }

    pub fn handle_request(self: *ClientHandler, allocator: Allocator) !?void {
        var buf: [50]u8 = undefined;
        const bytes_read = try self.stream.read(&buf);
        if (bytes_read == 0) return null;
        std.log.info("\x1b[32mBytes read by connection\x1b[0m: {any}", .{bytes_read});
        const received_packet = Packet.decode(buf[0..bytes_read]) catch |err| {
            std.log.err("\x1b[31mClient wrote a bad packet, error\x1b[0m: {any}", .{err});
            return TCPError.BadPacket;
        };

        std.log.info("\x1b[32mPacket received from stream\x1b[0m: {any}", .{received_packet});

        switch (received_packet.type) {
            .SensorRequest => {
                const decoded_request = try SensorRequest.decode(received_packet.data, allocator);

                std.log.info("\x1b[32mDecoded Response Packet\x1b[0m: {any}", .{decoded_request});

                const sensor_response = SensorResponse.init(decoded_request, undefined);
                const encoded_response = try sensor_response.encode(allocator);
                std.log.info("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}", .{encoded_response});

                const response_packet = Packet.init(1, PacketType.SensorResponse, encoded_response);
                std.log.info("\x1b[32mPacket response to be sent to stream\x1b[0m: {any}", .{response_packet});

                const encoded_response_packet = try response_packet.encode(allocator);
                _ = try self.stream.write(encoded_response_packet);
            },
            .SensorResponse => {
                std.log.err("\x1b[31mExpected SensorRequest packet, got SensorResponse\x1b[0m: {any}", .{received_packet.type});
                return TCPError.InvalidPacketType;
            },
        }
    }
};

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
        if (buf[0] != 1) return TCPError.VersionError;
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

pub const SensorData = packed struct { sensor_type: SensorType, val: f32 };

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

        // Existing rain data parsing
        const rain_data: []const f32 = (try device.parse_rain(allocator)) orelse &[_]f32{std.math.nan(f32)} ** 4;

        var buf = ArrayList(u8).init(allocator);
        for (self.request.sensors) |sensor| {
            switch (sensor) {
                .Gas => try buf.appendSlice(&device.get_gas()),
                .Temp => try buf.appendSlice(&device.get_temp()),
                .Pres => try buf.appendSlice(&device.get_pres()),
                .Hum => try buf.appendSlice(&device.get_hum()),
                .RainAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[0])),
                .RainEventAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[1])),
                .RainTotalAcc => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[2])),
                .RainRInt => try buf.appendSlice(&helpers.f32_to_bytes(rain_data[3])),
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
