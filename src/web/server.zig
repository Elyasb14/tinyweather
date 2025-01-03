const std = @import("std");
const net = std.net;
const why = @embedFile("why.html");
const html_404 = @embedFile("404.html");
const index = @embedFile("index.html");
const css = @embedFile("main.css");
const favicon = @embedFile("favicon.ico");

const about = @embedFile("about.html");

const Endpoints = enum {
    Index,
    About,
    Why,
    Css, // NOTE: this is a hack, want to just send main.css to the client when it first gets requested
    Favicon,
    NotFound,

    pub fn from_url(url: []const u8) Endpoints {
        if (std.mem.eql(u8, url, "/")) return .Index;
        if (std.mem.eql(u8, url, "/why")) return .Why;
        if (std.mem.eql(u8, url, "/css")) return .Css;
        if (std.mem.eql(u8, url, "/about")) return .About;
        if (std.mem.eql(u8, url, "/favicon.ico")) return .Favicon;
        return .NotFound;
    }
};

fn handle_request(req: *std.http.Server.Request) !void {
    const target = Endpoints.from_url(req.head.target);
    std.log.info("\x1b[32mclient requested: {s}\x1b[0m", .{req.head.target});

    switch (target) {
        .Index => {
            std.log.info("\x1b[32msending /\x1b[0m", .{});
            try req.respond(index, .{});
        },
        .About => {
            std.log.info("\x1b[32msending /about\x1b[0m", .{});
            try req.respond(about, .{});
        },
        .Why => {
            std.log.info("\x1b[32msending /why\x1b[0m", .{});
            try req.respond(why, .{});
        },
        .Css => {
            std.log.info("\x1b[32msending /css\x1b[0m", .{});
            try req.respond(css, .{});
        },
        .Favicon => {
            std.log.info("\x1b[32msending /favicon.ico\x1b[0m", .{});
            try req.respond(favicon, .{});
        },
        .NotFound => {
            std.log.warn("\x1b[33mclient requested endpoint that does not exist: {s}\x1b[0m", .{req.head.target});
            try req.respond(html_404, .{ .status = .not_found });
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
    std.log.info("\x1b[32mHTTP Server listening on\x1b[0m: {any}", .{server_address});

    while (true) {
        const conn = server.accept() catch |err| {
            std.log.err("\x1b[31mServer failed to connect to client:\x1b[0m {any}", .{err});
            continue;
        };
        std.log.info("\x1b[32mConnection established with\x1b[0m: {any}", .{conn.address});
        defer conn.stream.close();

        var buf: [1024]u8 = undefined;

        var http_server = std.http.Server.init(conn, &buf);
        while (http_server.state == .ready) {
            var request = http_server.receiveHead() catch |err| {
                if (err != error.HttpConnectionClosing) {
                    std.log.debug("connection error: {s}\n", .{@errorName(err)});
                }
                continue;
            };
            try handle_request(&request);
        }
    }
}
