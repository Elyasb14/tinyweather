const helpers = @import("helpers.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tcp = @import("tcp.zig");
const builtin = @import("builtin");
const bme = @import("sensors/bme680/bme680.zig");
const c = @cImport({
    @cInclude("lib/sensors/rg15/rg15.h");
});

// pub fn get_gas(allocator: Allocator) ![4]u8 {
//     const random_gas = std.crypto.random.float(f32) * 200.0;
//     return helpers.f32_to_bytes(random_gas);
// }
//
// pub fn get_temp() [4]u8 {
//     const random_temp = std.crypto.random.float(f32) * 50.0 - 20.0;
//     return helpers.f32_to_bytes(random_temp);
// }
//
// pub fn get_hum() [4]u8 {
//     const random_hum = std.crypto.random.float(f32) * 100.0;
//     return helpers.f32_to_bytes(random_hum);
// }
//
// pub fn get_pres() [4]u8 {
//     const random_pres = std.crypto.random.float(f32) * 500.0 + 500.0;
//     return helpers.f32_to_bytes(random_pres);
// }
//
pub fn parse_bme(allocator: Allocator) !?[]const f32 {
    var buf = ArrayList(f32).init(allocator);

    const bme_data = try bme.exec_python(allocator) orelse {
        std.log.warn("\x1b[33mCouldn't read bme sensor, sending nan to the client\x1b[0m", .{});
        return null;
    };
    var split = std.mem.splitAny(u8, bme_data, " \n");
    while (split.next()) |token| {
        const val = std.fmt.parseFloat(f32, token) catch continue;
        try buf.append(val);
    }
    const data = try buf.toOwnedSlice();
    return data;
}

/// this functions returns null when the sensor returns no data or partial data
/// in the case we do return null, the caller should "orelse" the bytearrray representing nan in f32 (std.math.nan(f32))
pub fn parse_rain(allocator: Allocator) !?[]const f32 {
    // TODO: this is a HACK
    // this is only here because sometimes we have a null pointer if there is no rain gauge device
    const rain_path = if (builtin.target.os.tag == .linux) "/dev/ttyUSB0" else "/dev/tty.usbserial-0001";
    std.fs.accessAbsolute(rain_path, .{}) catch {
        std.log.warn("\x1b[33mCould not open serial device, sending nan to the client\x1b[0m", .{});
        return null;
    };

    var buf = ArrayList(f32).init(allocator);
    const rain_data: []const u8 = std.mem.span(c.get_rain());
    if (rain_data.len < 4) return null;

    var split = std.mem.splitAny(u8, rain_data, " ,{}");
    while (split.next()) |token| {
        const val = std.fmt.parseFloat(f32, token) catch continue;
        try buf.append(val);
    }
    const data = try buf.toOwnedSlice();
    if (data.len < 4) return null;
    return data;
}
