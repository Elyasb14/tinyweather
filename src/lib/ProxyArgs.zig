const std = @import("std");

const NodeArgs = @This();

listen_port: u16,
remote_port: u16,
listen_addr: []const u8,
remote_addr: []const u8,
it: std.process.ArgIterator,

const Option = enum {
    @"--listen-address",
    @"--remote-addr",
    @"--remote-port",
    @"--listen-port",
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
        \\  ./{s} 10.0.0.7 9090
        \\
    , .{ process_name, process_name });
    std.process.exit(1);
}

pub fn deinit(self: *NodeArgs) void {
    self.it.deinit();
}

pub fn parse(allocator: std.mem.Allocator) !NodeArgs {
    var args = try std.process.argsWithAllocator(allocator);
    const process_name = args.next() orelse "tinyweather-node";

    var listen_port: u16 = 8080;
    var listen_address: []const u8 = "127.0.0.1";
    var remote_address: []const u8 = "127.0.0.1";
    var remote_port: u16 = 8081;

    while (args.next()) |arg| {
        const option = std.meta.stringToEnum(Option, arg) orelse {
            std.debug.print("{s} is not a valid argument\n", .{arg});
            help(process_name);
        };

        switch (option) {
            .@"--listen-address" => {
                listen_address = args.next() orelse {
                    std.debug.print("--address provided with no argument\n", .{});
                    help(process_name);
                };
            },
            .@"--listen-port" => {
                const port_s = args.next() orelse {
                    std.debug.print("--port provided with no argument\n", .{});
                    help(process_name);
                };
                listen_port = std.fmt.parseInt(u16, port_s, 10) catch {
                    std.debug.print("--port argument is not a valid u16\n", .{});
                    help(process_name);
                };
            },
            .@"--help" => help(process_name),
            .@"--remote-addr" => {
                remote_address = args.next() orelse {
                    std.debug.print("--remote-addr provided with no argument\n", .{});
                    help(process_name);
                };
            },
            .@"--remote-port" => {
                const port_s = args.next() orelse {
                    std.debug.print("--port provided with no argument\n", .{});
                    help(process_name);
                };
                remote_port = std.fmt.parseInt(u16, port_s, 10) catch {
                    std.debug.print("--port argument is not a valid u16\n", .{});
                    help(process_name);
                };
            },
        }
    }
    return .{
        .address = listen_address,
        .port = listen_port,
        .it = args,
    };
}
