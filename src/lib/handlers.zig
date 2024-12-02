const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const tcp = @import("tcp.zig");
const prometheus = @import("prometheus.zig");

pub const NodeConnectionHandler = struct {
    stream: net.Stream,

    pub fn init(stream: net.Stream) NodeConnectionHandler {
        return .{
            .stream = stream,
        };
    }

    pub fn deinit(self: *NodeConnectionHandler) void {
        std.log.info("\x1b[32mStream closed\x1b[0m: {any}", .{self.stream});
        self.stream.close();
    }

    pub fn handle(self: *NodeConnectionHandler, allocator: Allocator) !?void {
        var buf: [50]u8 = undefined;
        const bytes_read = try self.stream.read(&buf);
        if (bytes_read == 0) return null;
        std.log.info("\x1b[32mBytes read by connection\x1b[0m: {any}", .{bytes_read});
        const received_packet = tcp.Packet.decode(buf[0..bytes_read]) catch |err| {
            std.log.err("\x1b[31mClient wrote a bad packet, error\x1b[0m: {any}", .{err});
            return tcp.TCPError.BadPacket;
        };

        std.log.info("\x1b[32mPacket received from stream\x1b[0m: {any}", .{received_packet});

        switch (received_packet.type) {
            .SensorRequest => {
                const decoded_request = try tcp.SensorRequest.decode(received_packet.data, allocator);

                std.log.info("\x1b[32mDecoded Response Packet\x1b[0m: {any}", .{decoded_request});

                const sensor_response = tcp.SensorResponse.init(decoded_request, undefined);
                const encoded_response = try sensor_response.encode(allocator);
                std.log.info("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}", .{encoded_response});

                const response_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response);
                std.log.info("\x1b[32mPacket response to be sent to stream\x1b[0m: {any}", .{response_packet});

                const encoded_response_packet = try response_packet.encode(allocator);
                _ = try self.stream.write(encoded_response_packet);
            },
            .SensorResponse => {
                std.log.err("\x1b[31mExpected SensorRequest packet, got SensorResponse\x1b[0m: {any}", .{received_packet.type});
                return tcp.TCPError.InvalidPacketType;
            },
        }
    }
};

pub const ProxyConnectionHandler = struct {
    conn: net.Server.Connection,

    pub fn init(conn: net.Server.Connection) ProxyConnectionHandler {
        return .{ .conn = conn };
    }

    fn get_data(allocator: std.mem.Allocator, stream: net.Stream, sensors: []const tcp.SensorType) ![]tcp.SensorData {
        const sensor_request = tcp.SensorRequest.init(sensors);
        const sensor_request_encoded = try sensor_request.encode(allocator);
        const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, sensor_request_encoded);
        const encoded_packet = try packet.encode(allocator);

        var buf: [50]u8 = undefined;
        std.log.info("\x1b[32mPacket Sent\x1b[0m: {any}", .{packet});
        _ = stream.write(encoded_packet) catch |err| {
            std.log.warn("\x1b[33mCan't write to the node\x1b[0m: {s}", .{@errorName(err)});
            return err;
        };
        const n = try stream.read(&buf);
        if (n == 0) {
            return tcp.TCPError.BadPacket;
        }
        std.log.info("\x1b[32mBytes read by stream\x1b[0m: {any}", .{n});
        const decoded_packet = try tcp.Packet.decode(buf[0..n]);
        switch (decoded_packet.type) {
            .SensorResponse => {
                const decoded_sensor_response = try tcp.SensorResponse.decode(sensor_request, decoded_packet.data, allocator);
                const sensor_data = decoded_sensor_response.data;
                return sensor_data;
            },
            .SensorRequest => {
                std.log.err("\x1b[31mExpected SensorResponse, got SensorRequest\x1b[0m: {any}", .{decoded_packet});
                return tcp.TCPError.InvalidPacketType;
            },
        }
    }

    pub fn handle(self: *ProxyConnectionHandler, allocator: std.mem.Allocator) !void {
        const node_address = try net.Address.parseIp4("127.0.0.1", 8080);
        const node_stream = net.tcpConnectToAddress(node_address) catch {
            std.log.warn("\x1b[33mCan't connect to address\x1b[0m: {any}", .{node_address});
            return;
        };
        std.log.info("\x1b[32mProxy initializing communication with remote address\x1b[0m: {any}", .{node_address});
        defer node_stream.close();
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{self.conn.address});
        defer self.conn.stream.close();

        var prom_string = std.ArrayList([]const u8).init(allocator);

        var buf: [1024]u8 = undefined;

        var http_server = std.http.Server.init(self.conn, &buf);
        while (http_server.state == .ready) {
            var request = http_server.receiveHead() catch |err| {
                if (err != error.HttpConnectionClosing) {
                    std.log.warn("\x1b[33mConnection error\x1b[0m: {s}\n", .{@errorName(err)});
                }
                continue;
            };

            const target = request.head.target;
            if (std.mem.eql(u8, target, "/metrics")) {
                var sensors = std.ArrayList(tcp.SensorType).init(allocator);
                defer sensors.deinit();

                var iter = request.iterateHeaders();
                while (iter.next()) |h| {
                    if (std.mem.eql(u8, "sensor", h.name)) {
                        try sensors.append(std.meta.stringToEnum(tcp.SensorType, h.value) orelse {
                            std.log.warn("\x1b[33mIs someone sending wrong headers?\x1b[0m: {s}", .{h.value});
                            continue;
                        });
                    } else continue;
                }

                var gauges = std.ArrayList(prometheus.Gauge).init(allocator);

                for (sensors.items) |sensor| {
                    const gauge = prometheus.Gauge.init(@tagName(sensor), @tagName(sensor), std.Thread.Mutex{});
                    try gauges.append(gauge);
                }

                const data = get_data(allocator, node_stream, sensors.items) catch |err| {
                    std.log.warn("\x1b[33mFailed to get data\x1b[0m: {s}", .{@errorName(err)});
                    continue;
                };

                for (data, gauges.items) |x, *gauge| {
                    gauge.set(x.val);
                    try prom_string.append(try gauge.to_prometheus(allocator));
                }

                const ret = try std.mem.join(allocator, "\n", try prom_string.toOwnedSlice());
                try request.respond(ret, .{ .reason = "GET", .extra_headers = &.{.{ .name = "Content-Type", .value = "text/plain; version=0.0.4" }} });

                std.log.info("\x1b[32mPrometeus string being sent\x1b[0m:\n\x1b[36m{s}\x1b[0m", .{ret});
            } else {
                try request.respond("404 content not found", .{ .status = .not_found });
            }
        }
    }
};
