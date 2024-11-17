const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const why = @embedFile("why.html");
const html_404 = @embedFile("404.html");
const index = @embedFile("index.html");

const Endpoints = enum {
    index,
    why,
    not_found,

    pub fn fromUrl(url: []const u8) Endpoints {
        if (std.mem.eql(u8, url, "/")) return .index;
        if (std.mem.eql(u8, url, "/why")) return .why;
        return .not_found;
    }
};

fn handle_request(req: *std.http.Server.Request) !void {
    const target = Endpoints.fromUrl(req.head.target);

    switch (target) {
        .index => {
            std.log.info("sending /", .{});
            try req.respond(index, .{});
        },
        .why => {
            std.log.info("sending /why", .{});
            try req.respond(why, .{});
        },
        .not_found => {
            std.log.info("client requested endpoint that does not exist: {any}", .{target});
            try req.respond(html_404, .{ .status = .not_found });
            return;
        },
    }
}

pub fn main() !void {
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
