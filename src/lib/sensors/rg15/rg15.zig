const std = @import("std");
const os = std.os;
const mem = std.mem;
const fs = std.fs;
const print = std.debug.print;

const MAX_BUFFER = 1024;

pub const RG15Error = error{
    DeviceOpenError,
    AttributeError,
    WriteError,
    ReadError,
    AllocationError,
};

pub const RG15Device = struct {
    fd: fs.File,
    device_path: []const u8,
    termios: std.posix.termios,
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator, device_path: ?[]const u8) !*RG15Device {
        const default_device = if (comptime @import("builtin").target.os.tag == .macos)
            "/dev/cu.usbserial"
        else
            "/dev/ttyUSB0";

        const path = device_path orelse default_device;

        // Allocate the device structure
        var dev = try allocator.create(RG15Device);
        errdefer allocator.destroy(dev);

        // Open the serial port
        dev.fd = try fs.openFileAbsolute(path, .{
            .mode = .read_write,
            .lock = .none,
        });
        errdefer dev.fd.close();

        // Get current terminal attributes
        dev.termios = try std.posix.tcgetattr(dev.fd.handle);
        var tty = dev.termios;

        // Set baud rate
        try std.posix.tcsetattr(dev.fd.handle, .NOW, tty);

        // Configure port settings
        tty.cflag &= ~@as(std.posix.tc_cflag_t, std.posix.PARENB); // No parity
        tty.cflag &= ~@as(os.tcflag_t, os.CSTOPB); // 1 stop bit
        tty.cflag &= ~@as(os.tcflag_t, os.CSIZE); // Clear size bits
        tty.cflag |= os.CS8; // 8 bits per byte
        tty.cflag &= ~@as(os.tcflag_t, os.CRTSCTS); // No hardware flow control
        tty.cflag |= (os.CREAD | os.CLOCAL); // Enable reading & ignore ctrl lines

        // Input flags
        tty.iflag &= ~@as(os.tcflag_t, os.IXON | os.IXOFF | os.IXANY); // No software flow control
        tty.iflag &= ~@as(os.tcflag_t, os.IGNBRK | os.BRKINT | os.PARMRK | os.ISTRIP | os.INLCR | os.IGNCR | os.ICRNL);

        // Output flags
        tty.oflag &= ~@as(os.tcflag_t, os.OPOST); // Raw output
        tty.oflag &= ~@as(os.tcflag_t, os.ONLCR); // No CR/LF conversion

        // Local flags
        tty.lflag &= ~@as(os.tcflag_t, os.ICANON | os.ECHO | os.ECHOE | os.ECHONL | os.ISIG);

        // Set timeouts
        tty.cc[os.V.TIME] = 30; // 3 seconds timeout (30 deciseconds)
        tty.cc[os.V.MIN] = 0; // No minimum characters

        // Apply settings
        try std.posix.tcsetattr(dev.fd.handle, .NOW, tty);

        // Flush buffers
        try std.posix.tcflush(dev.fd.handle, os.TCIOFLUSH);

        dev.device_path = path;
        dev.allocator = allocator;

        return dev;
    }

    pub fn deinit(self: *RG15Device) void {
        self.fd.close();
        self.allocator.destroy(self);
    }

    pub fn getData(self: *RG15Device) !?[]const u8 {
        var buffer: [MAX_BUFFER]u8 = undefined;

        // Write command
        const cmd = "r\n";
        _ = try self.fd.write(cmd);

        // Small delay
        std.time.sleep(100 * std.time.ns_per_ms); // 100ms delay

        var retries: u8 = 3;
        while (retries > 0) : (retries -= 1) {
            const bytes_read = try self.fd.read(&buffer);

            if (bytes_read > 0) {
                var data = buffer[0..bytes_read];

                // Remove CR/LF
                if (mem.indexOf(u8, data, "\r")) |cr_pos| {
                    data = data[0..cr_pos];
                }
                if (mem.indexOf(u8, data, "\n")) |lf_pos| {
                    data = data[0..lf_pos];
                }

                return data;
            }

            std.time.sleep(100 * std.time.ns_per_ms); // Wait 100ms between retries
        }

        print("No data received after 3 attempts\n", .{});
        return null;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var dev = try RG15Device.init(allocator, null);
    defer dev.deinit();

    if (try dev.getData()) |data| {
        print("Received data: {s}\n", .{data});
    } else {
        print("No data received\n", .{});
    }
}
