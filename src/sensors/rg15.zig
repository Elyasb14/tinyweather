const std = @import("std");
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("fcntl.h");
});

const DeviceError = error{DeviceOpenError};

const Device = struct {
    fd: c_int,

    pub fn init(fd: c_int) Device {
        return Device{ .fd = fd };
    }
};

pub fn init_rg15() DeviceError!Device {
    const fd = c.open("/dev/ttyUSB0", c.O_RDWR);
    if (fd == -1) {
        std.debug.print("can't open device... fd: {any}\n", .{fd});
        return DeviceError.DeviceOpenError;
    }
    return Device.init(fd);
}

pub fn main() void {
    const device = init_rg15();
    std.debug.print("device: {any}", .{device});
}
