const std = @import("std");

const Args = @This();

port: u16,
address: []const u8,
it: std.process.ArgIterator,

const Option = enum {
    @"--address",
    @"--port",
    @"--help",
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
