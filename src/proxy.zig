const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const handlers = @import("lib/handlers.zig");
const Args = @import("lib/Args.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

// Modify handle_connection to return void instead of error
fn handle_connection(connection: net.Server.Connection, allocator: std.mem.Allocator) void {
    var handler = handlers.ProxyConnectionHandler.init(connection);
    defer handler.deinit();

    handler.handle(allocator) catch |e| {
        std.log.warn("\x1b[33mError handling client connection:\x1b[0m {s}", .{@errorName(e)});
        connection.stream.close();
    };
}

const ServerContext = struct {
    server: *std.net.Server,
    pool: *std.Thread.Pool,
    allocator: std.mem.Allocator,
};

// Modify connection_handler to return void and handle errors internally
fn connection_handler(context: ServerContext) void {
    const conn = context.server.accept() catch |err| {
        std.log.err("\x1b[31mProxy Server failed to connect to client:\x1b[0m {any}", .{err});
        return;
    };

    // Now spawning a void function
    context.pool.spawn(handle_connection, .{ conn, context.allocator }) catch |err| {
        std.log.err("Failed to spawn connection handler: {any}", .{err});
        conn.stream.close();
    };
}

// Modify listen to return void
fn listen(server_context: ServerContext) void {
    while (true) {
        connection_handler(server_context);
        // Add a small delay to prevent tight loop on repeated errors
        std.time.sleep(std.time.ns_per_ms * 10);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = try Args.parse(allocator);
    defer args.deinit();

    const server_address = try net.Address.parseIp(args.address, args.port);
    var tcp_server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });
    defer tcp_server.deinit();

    std.log.info("\x1b[32mProxy TCP Server listening on\x1b[0m: {any}", .{server_address});

    var pool: std.Thread.Pool = undefined;
    try pool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = @min(5, try std.Thread.getCpuCount()) });
    defer pool.deinit();

    const context = ServerContext{
        .server = &tcp_server,
        .pool = &pool,
        .allocator = allocator,
    };

    // Start multiple listener threads
    const listener_count = 2;
    var i: usize = 0;
    while (i < listener_count) : (i += 1) {
        // Handle spawn error
        pool.spawn(listen, .{context}) catch |err| {
            std.log.err("Failed to spawn listener: {any}", .{err});
            continue;
        };
    }

    // Wait indefinitely
    while (true) {
        std.time.sleep(std.time.ns_per_s);
    }
}
