const std = @import("std");
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

pub fn init_rg15() !c_int {
    const fd = c.open("/dev/tty.usbserial-0001", c.O_RDWR | c.O_NOCTTY | c.O_NONBLOCK);
    if (fd < 0) {
        _ = c.close(fd);
        std.log.err("can't open serial device", .{});
    }
    defer _ = c.close(fd);

    var settings = try std.posix.tcgetattr(fd);

    settings.ispeed = std.c.speed_t.B9600;
    settings.ospeed = std.c.speed_t.B9600;
    // Basic settings
    settings.cflag.CLOCAL = true;
    settings.cflag.CREAD = true;
    settings.cflag.PARENB = true;
    settings.cflag.CSTOPB = true;
    settings.cflag.CSIZE = .CS8;

    settings.cc[c.VMIN] = 0;
    settings.cc[c.VTIME] = 10;

    try std.posix.tcsetattr(fd, std.posix.TCSA.NOW, settings);
    _ = c.tcflush(fd, c.TCIOFLUSH);

    return fd;
}
pub fn main() !void {
    const device = try init_rg15();
    const written = c.write(device, "r\n", 2);
    if (written != 2) {
        std.log.err("didn't write enough bytes: {any}", .{written});
    }
}
// n = read(dev->fd, buffer, sizeof(buffer) - 1);
