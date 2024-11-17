const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const why = @embedFile("why.html");

fn handle_request(req: *std.http.Server.Request) !void {
    const target = req.head.target;
    std.log.info("request target: {s}", .{target});
    try req.respond(why, .{});
}

pub fn main() !void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    //
    const server_address = try net.Address.parseIp("127.0.0.1", 8080);
    var server = try net.Address.listen(server_address, .{
        .kernel_backlog = 1024,
        .reuse_address = true,
        .reuse_port = true,
    });

    defer server.deinit();
    std.log.info("\x1b[32mServer listening on {}\x1b[0m", .{server_address});

    while (true) {
        const conn = server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{conn.address});

        var buf: [1024]u8 = undefined;

        var http_server = std.http.Server.init(conn, &buf);
        var request = try http_server.receiveHead();
        try handle_request(&request);
    }
}
