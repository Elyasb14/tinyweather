const std = @import("std");
const c = @cImport(@cInclude("termios.h"));

pub fn setup_serial() !void {
    const port_name = "/dev/tty.usbserial-0001";
    var serial = std.fs.cwd().openFile(port_name, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("Invalid config: the serial port '{s}' does not exist.\n", .{port_name});
            return;
        },
        else => return err,
    };
    defer serial.close();
    std.debug.print("opened serial port: {any}", .{serial});
}
