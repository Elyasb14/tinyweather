const std = @import("std");
const c = @cImport({
    @cInclude("linux/i2c.h");
    @cInclude("linux/i2c-dev.h");
    @cInclude("sys/ioctl.h");
    @cInclude("bme_defs.h");
});

const i2c_device = "/dev/i2c-1";
const i2c_addr: c_int = 0x77;

pub fn main() !void {
    const fd = try std.fs.openFileAbsolute(i2c_device, .{ .write = true, .read = true });
    defer fd.close();

    comptime {
        if (c.ioctl(fd.handle, c.I2C_SLAVE, i2c_addr) < 0) {
            std.debug.print("ioctl failed, errno: {any}\n", c.errno);
        }

        std.debug.print("Init successful\n", .{});
    }
}
