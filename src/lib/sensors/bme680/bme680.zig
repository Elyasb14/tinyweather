const std = @import("std");

// how tinygrad locks fd. can we lock the i2c fd here?
// os.umask(0) # Set umask to 0 to allow creating files with 0666 permissions
//
// # Avoid O_CREAT because we don’t want to re-create/replace an existing file (triggers extra perms checks) when opening as non-owner.
// if os.path.exists(lock_name:=temp(f"am_{self.devfmt}.lock")): self.lock_fd = os.open(lock_name, os.O_RDWR)
// else: self.lock_fd = os.open(lock_name, os.O_RDWR | os.O_CREAT, 0o666)
//
// try: fcntl.flock(self.lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
// except OSError: raise RuntimeError(f"Failed to open AM device {self.devfmt}. It's already in use.")
// /// returns null if stderr != ""
pub fn exec_python(allocator: std.mem.Allocator) !?[]const u8 {
    const code =
        \\import board
        \\import adafruit_bme680
        \\i2c = board.I2C()
        \\sensor = adafruit_bme680.Adafruit_BME680_I2C(i2c)
        \\print(sensor.temperature, sensor.pressure, sensor.humidity, sensor.gas)
    ;

    const arg: [3][]const u8 = .{ "python3", "-c", code };
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &arg });
    if (!std.mem.eql(u8, result.stderr, "")) {
        std.log.warn("\x1b[33mStderr for python execution:\n {s}\x1b[0m", .{result.stderr});
        return null;
    }
    return result.stdout;
}
