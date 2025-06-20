const std = @import("std");
const net = std.net;
const tcp = @import("lib/tcp.zig");
const handlers = @import("lib/handlers.zig");
const Args = @import("lib/Args.zig");
const builtin = @import("builtin");

pub const std_options: std.Options = .{
    .log_level = .warn,
};

fn handle_connection(connection: net.Server.Connection, allocator: std.mem.Allocator) void {
    var handler = handlers.ProxyConnectionHandler.init(connection);
    defer handler.deinit();

    handler.handle(allocator) catch |e| {
        std.log.warn("\x1b[33mError handling client connection:\x1b[0m {s}", .{@errorName(e)});
        return;
    };
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

    while (true) {
        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mProxy Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        try pool.spawn(handle_connection, .{ conn, allocator });
    }
}
