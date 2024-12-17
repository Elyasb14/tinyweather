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

fn help(process_name: []const u8) noreturn {
    std.debug.print(
        \\Usage: 
        \\  ./{s} --address [ip_address] --port [port]
        \\
        \\Options:
        \\  ip_address (optional)  The IP address to bind to (default: 127.0.0.1)
        \\  port (optional)        The port to listen on (default: 8080)
        \\Example:
        \\  ./{s} --address 10.0.0.7 --port 9090 
        \\
    , .{ process_name, process_name });
    std.process.exit(1);
}

pub fn deinit(self: *Args) void {
    self.it.deinit();
}

pub fn parse(allocator: std.mem.Allocator) !Args {
    var args = try std.process.argsWithAllocator(allocator);
    const process_name = args.next() orelse "tinyweather-proxy";

    var port: u16 = 8080;
    if (std.mem.endsWith(u8, process_name, "tinyweather-proxy")) {
        port = 8081;
    }

    var address: []const u8 = "127.0.0.1";

    while (args.next()) |arg| {
        const option = std.meta.stringToEnum(Option, arg) orelse {
            std.debug.print("{s} is not a valid argument\n", .{arg});
            help(process_name);
        };

        switch (option) {
            .@"--address" => {
                address = args.next() orelse {
                    std.debug.print("--address provided with no argument\n", .{});
                    help(process_name);
                };
            },
            .@"--port" => {
                const port_s = args.next() orelse {
                    std.debug.print("--port provided with no argument\n", .{});
                    help(process_name);
                };
                port = std.fmt.parseInt(u16, port_s, 10) catch {
                    std.debug.print("--port argument is not a valid u16\n", .{});
                    help(process_name);
                };
            },
            .@"--help" => help(process_name),
        }
    }
    return .{
        .address = address,
        .port = port,
        .it = args,
    };
}
