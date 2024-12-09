const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");
const ArrayList = std.ArrayList;
const handlers = @import("lib/handlers.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

fn help() noreturn {
    std.debug.print(
        \\Usage: 
        \\  ./tinyweather-node --address [ip_address] --port [port]
        \\
        \\Options:
        \\  ip_address (optional)  The IP address to bind to (default: 127.0.0.1)
        \\  port (optional)        The port to listen on (default: 8080)
        \\Example:
        \\  ./tinyweather-node 10.0.0.7 9090
        \\
    , .{});
    std.process.exit(1);
}

const Args = struct {
    port: u16,
    address: []const u8,
    it: std.process.ArgIterator,

    const Option = enum {
        @"--address",
        @"--port",
        @"--help",
    };

    pub fn deinit(self: *Args) void {
        self.it.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator) !Args {
        var args = try std.process.argsWithAllocator(allocator);
        _ = args.next() orelse "tinyweather-node";

        var port: u16 = 8080;
        var address: []const u8 = "127.0.0.1";

        while (args.next()) |arg| {
            const option = std.meta.stringToEnum(Option, arg) orelse {
                std.debug.print("{s} is not a valid argument\n", .{arg});
                help();
            };

            switch (option) {
                .@"--address" => {
                    address = args.next() orelse {
                        std.debug.print("--address provided with no argument\n", .{});
                        help();
                    };
                },
                .@"--port" => {
                    const port_s = args.next() orelse {
                        std.debug.print("--port provided with no argument\n", .{});
                        help();
                    };
                    port = std.fmt.parseInt(u16, port_s, 10) catch {
                        std.debug.print("--port argument is not a valid u16\n", .{});
                        help();
                    };
                },
                .@"--help" => help(),
            }
        }
        return .{
            .address = address,
            .port = port,
            .it = args,
        };
    }
};

fn handle_client(connection: net.Server.Connection, allocator: std.mem.Allocator) !void {
    var handler = handlers.NodeConnectionHandler.init(connection.stream);
    defer handler.deinit();
    while (true) {
        handler.handle(allocator) catch |e| {
            std.log.warn("\x1b[33mError handling client connection:\x1b[0m {s}", .{@errorName(e)});
            break;
        } orelse break;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = try Args.parse(allocator);
    defer args.deinit();

    std.debug.print("address: {s}, port: {d}\n", .{ args.address, args.port });

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

        // try handle_client(client_stream, allocator);
        const thread = try std.Thread.spawn(.{}, handle_client, .{ connection, allocator });
        thread.detach();
    }
}
