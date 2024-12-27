const std = @import("std");
const c = @cImport({
    @cInclude("linux/i2c.h");
    @cInclude("linux/i2c-dev.h");
    @cInclude("sys/ioctl.h");
    @cInclude("bme_defs.h");
});

const i2c_device = "/dev/i2c-1";

const Device = struct {
    fd: std.fs.File,

    pub fn init(path: []const u8) !Device {
        const fd = try std.fs.openFileAbsolute(path, .{ .mode = .read_write });
        defer fd.close();

        if (c.ioctl(fd.handle, c.I2C_SLAVE, c.BME68X_CHIP_ID) < 0) {
            std.debug.print("ioctl failed, errno\n", .{});
        }

        return .{ .fd = fd };
    }

    fn write(self: *Device) void {
        var buf: [32]u8 = undefined;
        const ret_code = self.fd.write(&buf);
        std.debug.print("{any}\n", .{ret_code});
    }
    fn read() void {}

    // pub fn set_registers(register_addr: c_int, register_data: c_int, len: u32, device: *Device) u8 {

};

pub fn main() !void {
    const device = try Device.init(i2c_device);
    device.write();

    std.debug.print("{any}\n", .{device});
}
