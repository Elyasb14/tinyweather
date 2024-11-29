const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const prometheus = @import("lib/prometheus.zig");
const handlers = @import("lib/handlers.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

// NOTES: how we will be getting data from sensors and displaying that for prometheus to ingest
// prometheus will make a request to the metrics http endpoint
// we will get the data requested in the client program
// we will update the relevant gauges
// we will respond to the request with the data in prometheus ingestible format
pub fn main() !void {
    // NOTE: this can only happen once
    // if the node dies, the client can't reconnect unless you shut down the program and restart it
    // Initialize the file logger before using it
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
    std.log.info("\x1b[32mTCP Server listening on\x1b[0m: {any}", .{server_address});

    while (true) {
        // NOTE: putting this here makes me connect to the remote node twice.
        // when I move it outside the while loop it works as desired
        // I think we want to move the connection to the remote node to handle_client

        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        // Create a mutable handler
        var handler = handlers.ProxyConnectionHandler.init(conn, &sensors, gauges);

        // Spawn a thread and pass a pointer to the mutable handler
        const thread = std.Thread.spawn(.{}, handlers.ProxyConnectionHandler.handle, .{ &handler, allocator }) catch {
            continue;
        };
        thread.detach();
    }
}
