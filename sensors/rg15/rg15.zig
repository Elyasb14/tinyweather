const std = @import("std");
const c = @cImport( @cInclude("termios.h"), @cInclude("fcntl.h") );

const Device = struct {
    fd: c_int,

    pub fn init(fd: c_int) *Device {
        return &.Device{ .fd = fd };
    }
};

pub fn init_rg15() *Device {
    const fd = c.open("/dev/ttyUSB0", c.O_RDWR);
    return Device.init(fd, c.termios);
}

pub fn main() void {
    const device = init_rg15();
    std.debug.print("device: {any}", .{device});
}
