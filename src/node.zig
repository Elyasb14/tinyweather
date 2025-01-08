const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const ArrayList = std.ArrayList;
const handlers = @import("lib/handlers.zig");
const Args = @import("lib/Args.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

fn handle_client(connection: net.Server.Connection, allocator: std.mem.Allocator) !void {
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

    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("\x1b[31mNode Server failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{connection.address});

        const thread = try std.Thread.spawn(.{}, handle_client, .{ connection, allocator });
        thread.detach();
    }
}
