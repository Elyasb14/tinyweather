const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const ArrayList = std.ArrayList;
const handlers = @import("lib/handlers.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};
fn handle_client(connection: net.Server.Connection, allocator: std.mem.Allocator) !void {
    var handler = handlers.NodeConnectionHandler.init(connection.stream);
    defer handler.deinit();
    while (true) {
        try handler.handle(allocator) orelse break;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const server_address = try net.Address.parseIp("127.0.0.1", 8080);
    var server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer server.deinit();
    std.log.info("\x1b[32mNode TCP Server listening on\x1b[0m: {any}", .{server_address});

    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("\x1b[31mNode Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{connection.address});

        // try handle_client(client_stream, allocator);
        const thread = try std.Thread.spawn(.{}, handle_client, .{ connection, allocator });
        thread.detach();
    }
}
