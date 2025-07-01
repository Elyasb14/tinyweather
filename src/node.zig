const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const ArrayList = std.ArrayList;
const handlers = @import("lib/handlers.zig");
const Args = @import("lib/Args.zig");

pub const std_options: std.Options = .{
    .log_level = .warn,
};

pub fn handle_client(connection: net.Server.Connection) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var handler = handlers.NodeConnectionHandler.init(connection.stream);
    defer handler.deinit();

    handler.handle(allocator) catch |e| {
        std.log.warn("\x1b[33mError handling client connection:\x1b[0m {s}", .{@errorName(e)});
        return;
    } orelse {
        std.log.warn("\xb1[33mRead 0 bytes from connection\x1b[0m", .{});
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
    var server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer server.deinit();
    std.log.info("\x1b[32mNode TCP Server listening on\x1b[0m: {any}", .{server_address});

    var pool: std.Thread.Pool = undefined;
    try pool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = 5 });
    defer pool.deinit();

    while (true) {
        const conn = server.accept() catch |err| {
            std.log.err("\x1b[31mProxy Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        try pool.spawn(handle_client, .{conn});
    }
}
