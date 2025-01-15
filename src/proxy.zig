const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const handlers = @import("lib/handlers.zig");
const Args = @import("lib/Args.zig");
const posix = std.posix;

pub const std_options: std.Options = .{
    .log_level = .debug,
};

pub fn handle_connection(connection: net.Server.Connection, allocator: std.mem.Allocator) !void {
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

    const epoll_fd = try posix.epoll_create1(0);
    defer posix.close(epoll_fd);

    while (true) {
        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mProxy Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        const thread = std.Thread.spawn(.{}, handle_connection, .{ conn, allocator }) catch {
            continue;
        };
        thread.detach();
    }
}
