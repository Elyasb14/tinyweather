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

pub fn handle_client(allocator: std.mem.Allocator, conn: std.net.Server.Connection, sensors: []const tcp.SensorType, gauges: std.ArrayList(prometheus.Gauge)) !void {
    const remote_address = try net.Address.parseIp4("127.0.0.1", 8080);
    const remote_stream = net.tcpConnectToAddress(remote_address) catch |err| {
        std.log.err("Can't connect to address: {any}... error: {any}", .{ remote_address, err });
        return tcp.TCPError.ConnectionError;
    };
    std.log.info("\x1b[32mClient initializing communication with remote address: {any}....\x1b[0m", .{remote_address});
    defer remote_stream.close();
    std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{conn.address});
    defer conn.stream.close();

    var prom_string = std.ArrayList([]const u8).init(allocator);

    var buf: [1024]u8 = undefined;

    var http_server = std.http.Server.init(conn, &buf);
    while (http_server.state == .ready) {
        var request = http_server.receiveHead() catch |err| {
            if (err != error.HttpConnectionClosing) {
                std.log.warn("\x1b[33mConnection error\x1b[0m: {s}\n", .{@errorName(err)});
            }
            continue;
        };

        const target = request.head.target;
        if (std.mem.eql(u8, target, "/metrics")) {
            const data = get_data(allocator, remote_stream, sensors) catch |err| {
                std.log.warn("\x1b[33mFailed to get data\x1b[0m: {s}", .{@errorName(err)});
                continue;
            };

            for (data, gauges.items) |x, *gauge| {
                gauge.set(x.val);
                try prom_string.append(try gauge.to_prometheus(allocator));
            }

            const ret = try std.mem.join(allocator, "\n", try prom_string.toOwnedSlice());
            try request.respond(ret, .{ .reason = "GET", .extra_headers = &.{.{ .name = "Content-Type", .value = "text/plain; version=0.0.4" }} });

            std.log.info("Prometeus string being sent:\n{s}", .{ret});
        } else {
            try request.respond("404 content not found", .{ .status = .not_found });
        }
    }
}

// NOTES: how we will be getting data from sensors and displaying that for prometheus to ingest
// prometheus will make a request to the metrics http endpoint
// we will get the data requested in the client program
// we will update the relevant gauges
// we will respond to the request with the data in prometheus ingestible format
pub fn main() !void {
    // NOTE: this can only happen once
    // if the node dies, the client can't reconnect unless you shut down the program and restart it

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sensors = [_]tcp.SensorType{
        tcp.SensorType.RainAcc,
        tcp.SensorType.RainTotalAcc,
        tcp.SensorType.RainEventAcc,
    };

    var gauges = std.ArrayList(prometheus.Gauge).init(allocator);

    for (sensors) |sensor| {
        const gauge = prometheus.Gauge.init(@tagName(sensor), @tagName(sensor), std.Thread.Mutex{});
        try gauges.append(gauge);
    }

    const server_address = try net.Address.parseIp("127.0.0.1", 8081);
    var tcp_server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer tcp_server.deinit();
    std.log.info("\x1b[32mHTTP Server listening on {any}\x1b[0m", .{server_address});

    while (true) {
        // NOTE: putting this here makes me connect to the remote node twice.
        // when I move it outside the while loop it works as desired
        // I think we want to move the connection to the remote node to handle_client

        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        const thread = try std.Thread.spawn(.{}, handle_client, .{ allocator, conn, &sensors, gauges });
        thread.detach();
    }
}
