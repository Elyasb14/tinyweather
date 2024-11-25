const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const prometheus = @import("lib/prometheus/gauge.zig");

pub fn get_data(allocator: std.mem.Allocator, stream: net.Stream, sensors: []const tcp.SensorType) ![]tcp.SensorData {
    const sensor_request = tcp.SensorRequest.init(sensors);
    const sensor_request_encoded = try sensor_request.encode(allocator);
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, sensor_request_encoded);
    const encoded_packet = try packet.encode(allocator);

    var buf: [50]u8 = undefined;
    std.log.info("\x1b[32mPacket Sent\x1b[0m: {any}", .{packet});
    _ = try stream.write(encoded_packet);
    const n = try stream.read(&buf);
    std.log.info("\x1b[32mBytes read by stream\x1b[0m: {any}", .{n});
    const decoded_packet = try tcp.Packet.decode(buf[0..n]);
    switch (decoded_packet.type) {
        .SensorResponse => {
            const decoded_sensor_response = try tcp.SensorResponse.decode(sensor_request, decoded_packet.data, allocator);
            // std.log.info("\x1b[32mSensor Response Packet Received\x1b[0m: {any}", .{decoded_sensor_response});
            const sensor_data = decoded_sensor_response.data;
            return sensor_data;
        },
        .SensorRequest => {
            std.log.err("Expected SensorResponse, got SensorRequest: {any}", .{decoded_packet});
            return tcp.TCPError.InvalidPacketType;
        },
    }
}

// NOTES: how we will be getting data from sensors and displaying that for prometheus to ingest
// prometheus will make a request to the metrics http endpoint
// we will get the data requested in the client program
// we will update the relevant gauges
// we will respond to the request with the data in prometheus ingestible format

pub fn main() !void {
    const remote_address = try net.Address.parseIp4("127.0.0.1", 8080);
    const remote_stream = net.tcpConnectToAddress(remote_address) catch |err| {
        std.log.err("Can't connect to address: {any}... error: {any}", .{ remote_address, err });
        return error.ConnectionRefused;
    };
    std.log.info("\x1b[32mClient initializing communication with remote address: {any}....\x1b[0m", .{remote_address});
    defer remote_stream.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sensors = [_]tcp.SensorType{
        tcp.SensorType.RainAcc,
        tcp.SensorType.RainTotalAcc,
        tcp.SensorType.RainEventAcc,
    };

    const server_address = try net.Address.parseIp("127.0.0.1", 8081);
    var tcp_server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer tcp_server.deinit();
    std.log.info("\x1b[32mHTTP Server listening on {any}\x1b[0m", .{server_address});

    var gauge = prometheus.Gauge.init("room_temperature_celsius", "Current room temperature in Celsius");
    gauge.set(17.1);
    const prom_string = try gauge.to_prometheus(allocator);

    while (true) {
        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        const thread = try std.Thread.spawn(.{}, handle_client, .{ allocator, conn, remote_stream, prom_string, &sensors });
        thread.detach();
    }
}
pub fn handle_client(allocator: std.mem.Allocator, conn: std.net.Server.Connection, remote_stream: std.net.Stream, prom_string: []const u8, sensors: []const tcp.SensorType) !void {
    std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{conn.address});
    defer conn.stream.close();

    var buf: [1024]u8 = undefined;

    var http_server = std.http.Server.init(conn, &buf);
    while (http_server.state == .ready) {
        var request = http_server.receiveHead() catch |err| {
            if (err != error.HttpConnectionClosing) {
                std.log.debug("connection error: {s}\n", .{@errorName(err)});
            }
            continue;
        };

        const target = request.head.target;
        if (std.mem.eql(u8, target, "/metrics")) {
            const data = try get_data(allocator, remote_stream, sensors);
            for (data) |x| {
                std.debug.print("Sensor: {any}, Val: {d}\n", .{ x.sensor_type, x.val });
            }
            std.log.info("Prometeus string being sent:\n{s}", .{prom_string});

            try request.respond(prom_string, .{ .reason = "GET", .extra_headers = &.{.{ .name = "Content-Type", .value = "text/plain; version=0.0.4" }} });
        } else {
            try request.respond("404 content not found", .{ .status = .not_found });
        }
    }
}
