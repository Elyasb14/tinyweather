const std = @import("std");
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

pub fn init_rg15() !c_int {
    const fd = c.open("/dev/tty.usbserial-0001", c.O_RDWR | c.O_NOCTTY | c.O_NONBLOCK); // Removed O_NONBLOCK
    if (fd < 0) {
        std.log.err("can't open serial device: {d}", .{fd});
        return error.DeviceOpenError;
    }

    // Get the current flags
    const flags = c.fcntl(fd, c.F_GETFL, @as(c_int, 0));
    if (flags < 0) {
        _ = c.close(fd);
        return error.FcntlError;
    }

    // Clear the O_NONBLOCK flag if it's set
    if (c.fcntl(fd, c.F_SETFL, flags & ~c.O_NONBLOCK) < 0) {
        _ = c.close(fd);
        return error.FcntlError;
    }

    var settings = try std.posix.tcgetattr(fd);

    // Set baud rate
    settings.ispeed = std.c.speed_t.B9600;
    settings.ospeed = std.c.speed_t.B9600;

    // Control flags
    settings.cflag.CLOCAL = true; // Ignore modem control lines
    settings.cflag.CREAD = true; // Enable receiver
    settings.cflag.PARENB = true; // Enable parity
    settings.cflag.PARODD = false; // Use even parity
    settings.cflag.CSTOPB = true; // 2 stop bits
    settings.cflag.CSIZE = .CS8; // 8 bits per byte

    // Input flags
    settings.iflag.ICRNL = false; // Don't translate CR to NL
    settings.iflag.INLCR = false; // Don't translate NL to CR
    settings.iflag.IGNCR = false; // Don't ignore CR
    settings.iflag.ISTRIP = false; // Don't strip 8th bit

    // Output flags
    settings.oflag.OPOST = false; // Raw output

    // Local flags
    settings.lflag.ICANON = false; // Raw input
    settings.lflag.ECHO = false; // Don't echo input
    settings.lflag.ECHOE = false; // Don't echo erase
    settings.lflag.ISIG = false; // Disable signals

    // Special characters
    settings.cc[c.VMIN] = 0; // Return immediately with what's available
    settings.cc[c.VTIME] = 10; // Wait up to 1 second for data

    try std.posix.tcsetattr(fd, std.posix.TCSA.NOW, settings);

    const flush = c.tcflush(fd, c.TCIOFLUSH);
    if (flush != 0) {
        std.log.err("flush failed: {d}", .{flush});
        return error.FlushError;
    }

    return fd;
}

pub fn read_response(fd: c_int, buffer: []u8) !usize {
    const bytes_read = c.read(fd, buffer.ptr, buffer.len);
    if (bytes_read < 0) {
        std.log.err("read error: {d}", .{bytes_read});
        return error.ReadError;
    }
    return @intCast(bytes_read);
}

pub fn main() !void {
    const device = try init_rg15();
    const cmd = "r\n"; // Capital R for RG-15 measurement command
    const written = c.write(device, cmd, cmd.len);
    if (written < 0) {
        std.log.err("write error: {d}", .{written});
        return error.WriteError;
    }
    std.debug.print("Wrote {d} bytes\n", .{written});
    // Read response
    var buffer: [1024]u8 = undefined;
    const bytes_read = try read_response(device, &buffer);
    if (bytes_read > 0) {
        std.debug.print("Response: {s}\n", .{buffer[0..bytes_read]});
    } else {
        std.debug.print("No response received\n", .{});
    }
}
// // Clear the O_NONBLOCK flag
//     int flags = fcntl(dev->fd, F_GETFL, 0);
//     if (flags == -1) {
//         perror("Error getting flags");
//         close(dev->fd);
//         free(dev);
//         return NULL;
//     }
//     flags &= ~O_NONBLOCK;
//     if (fcntl(dev->fd, F_SETFL, flags) == -1) {
//         perror("Error setting flags");
//         close(dev->fd);
//         free(dev);
//         return NULL;
//     }
