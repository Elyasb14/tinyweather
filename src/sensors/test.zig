const std = @import("std");
const c = @cImport({
    @cInclude("termios.h");
});

pub fn init_rg15() !void {
    const file = try std.fs.cwd().openFile("/dev/ttyUSB0", .{ .mode = .read_write });

    var settings = try std.posix.tcgetattr(file.handle);

    settings.ispeed = std.c.speed_t.B9600;
    settings.ospeed = std.c.speed_t.B9600;
    settings.cflag.PARENB = false;
    settings.cflag.CSTOPB = false;

    settings.cc[c.VTIME] = 30;
}

pub fn main() void {
    const device = init_rg15();
    std.debug.print("device: {any}", .{device});
}

// // Set serial port parameters (matching Python's default settings)
// cfsetispeed(&dev->tty, B9600);
// cfsetospeed(&dev->tty, B9600);
// dev->tty.c_cflag &= ~PARENB;        // No parity
// dev->tty.c_cflag &= ~CSTOPB;        // 1 stop bit
// dev->tty.c_cflag &= ~CSIZE;
// dev->tty.c_cflag |= CS8;            // 8 bits per byte
// dev->tty.c_cflag &= ~CRTSCTS;       // No hardware flow control
// dev->tty.c_cflag |= CREAD | CLOCAL; // Enable reading & ignore ctrl lines
//
// dev->tty.c_lflag &= ~ICANON;        // Disable canonical mode
// dev->tty.c_lflag &= ~ECHO;          // Disable echo
// dev->tty.c_lflag &= ~ECHOE;         // Disable erasure
// dev->tty.c_lflag &= ~ECHONL;        // Disable new-line echo
// dev->tty.c_lflag &= ~ISIG;          // Disable interpretation of INTR, QUIT and SUSP
//
// dev->tty.c_iflag &= ~(IXON | IXOFF | IXANY);   // Turn off software flow control
// dev->tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL);
//
// dev->tty.c_oflag &= ~OPOST;         // Prevent special interpretation of output bytes
// dev->tty.c_oflag &= ~ONLCR;         // Prevent conversion of newline to carriage return/line feed
//
// // Set timeout to 3 seconds (matching Python version)
// dev->tty.c_cc[VTIME] = 30;          // Wait up to 3 seconds (30 deciseconds)
// dev->tty.c_cc[VMIN] = 0;            // No minimum number of characters
//
// if (tcsetattr(dev->fd, TCSANOW, &dev->tty) != 0) {
//     perror("Error setting serial port attributes");
//     close(dev->fd);
//     free(dev);
//     return NULL;
// }
//
// // Flush anything in the buffer
// tcflush(dev->fd, TCIOFLUSH);
//
// printf("Serial port configured successfully\n");
// return dev;
