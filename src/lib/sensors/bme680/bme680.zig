const std = @import("std");

pub fn exec_python(allocator: std.mem.Allocator) !?[]const u8 {
    const source =
        \\import board
        \\import adafruit_bme680
        \\i2c = board.I2C()
        \\sensor = adafruit_bme680.Adafruit_BME680_I2C(i2c)
        \\print(sensor.temperature, sensor.pressure, sensor.humidity, sensor.gas)
    ;

    const arg: [3][]const u8 = .{ "python3", "-c", source };
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &arg });
    if (!std.mem.eql(u8, result.stderr, "")) {
        std.log.warn("\x1b[33mStderr for python execution: {s}\x1b[0m", .{result.stderr});
        return null;
    }
    return result.stdout;
}
