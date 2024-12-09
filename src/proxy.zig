const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const prometheus = @import("lib/prometheus.zig");
const handlers = @import("lib/handlers.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const server_address = try net.Address.parseIp("127.0.0.1", 8080);
    var tcp_server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer tcp_server.deinit();
    std.log.info("\x1b[32mProxy TCP Server listening on\x1b[0m: {any}", .{server_address});

    while (true) {
        const conn = tcp_server.accept() catch |err| {
            std.log.err("\x1b[31mProxy Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };

        var handler = handlers.ProxyConnectionHandler.init(conn);
        const thread = std.Thread.spawn(.{}, handlers.ProxyConnectionHandler.handle, .{ &handler, allocator }) catch {
            continue;
        };
        thread.detach();
    }
}
