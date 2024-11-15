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
        return error.NoDevice;
    }
    defer _ = c.close(fd);

    var settings = try std.posix.tcgetattr(fd);

    settings.ispeed = std.c.speed_t.B9600;
    settings.ospeed = std.c.speed_t.B9600;

    return fd;
}

pub fn main() void {
    const device = init_rg15();
    std.debug.print("device: {any}\n", .{device});
}

// // Basic settings
//     dev->tty.c_cflag |= (CLOCAL | CREAD);    // Enable receiver, ignore modem controls
//     dev->tty.c_cflag &= ~PARENB;             // No parity
//     dev->tty.c_cflag &= ~CSTOPB;             // 1 stop bit
//     dev->tty.c_cflag &= ~CSIZE;
//     dev->tty.c_cflag |= CS8;                 // 8 bits per byte
//     dev->tty.c_cflag &= ~CRTSCTS;            // No hardware flow control
//
//     // Setting timeouts
//     dev->tty.c_cc[VMIN] = 0;                 // No minimum characters
//     dev->tty.c_cc[VTIME] = 10;               // 1 second timeout
