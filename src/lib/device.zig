const helpers = @import("helpers.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tcp = @import("tcp.zig");
const builtin = @import("builtin");
const bme = @import("sensors/bme680/bme680.zig");
const c = @cImport({
    @cInclude("lib/sensors/rg15/rg15.h");
    @cInclude("lib/sensors/bfrobot/bfrobot.h");
});

/// this functions returns null when the sensor returns no data or partial data
/// in the case we do return null, the caller should "orelse" the bytearrray representing nan in f32 (helpers.f32_to_bytes(std.math.nan(f32)))
pub fn parse_bme(allocator: Allocator) !?[]const f32 {
    var buf = ArrayList(f32).init(allocator);

    const bme_data = try bme.exec_python(allocator) orelse {
        std.log.warn("\x1b[33mCouldn't read bme sensor, sending nan to the client\x1b[0m", .{});
        return null;
    };

    std.log.info("\x1b[32mRaw data read by bme680\x1b[0m: {s}", .{bme_data});

    var split = std.mem.splitAny(u8, bme_data, " \n");
    while (split.next()) |token| {
        const val = std.fmt.parseFloat(f32, token) catch continue;
        try buf.append(val);
    }
    const data = try buf.toOwnedSlice();
    return data;
}

/// this functions returns null when the sensor returns no data or partial data
/// in the case we do return null, the caller should "orelse" the bytearrray representing nan in f32 (helpers.f32_to_bytes(std.math.nan(f32)))
pub fn parse_rg15(allocator: Allocator) !?[]const f32 {
    const rain_path = if (builtin.target.os.tag == .linux) "/dev/ttyUSB0" else "/dev/tty.usbserial-0001";
    std.fs.accessAbsolute(rain_path, .{}) catch {
        std.log.warn("\x1b[33mCould not open serial device, sending nan to the client\x1b[0m", .{});
        return null;
    };

    var buf = ArrayList(f32).init(allocator);
    const rain_data: []const u8 = std.mem.span(c.get_rg15());
    std.log.info("\x1b[32mRaw data read by RG15\x1b[0m: {s}", .{rain_data});
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

/// this functions returns null when the sensor returns no data or partial data
/// in the case we do return null, the caller should "orelse" the bytearrray representing nan in f32 (helpers.f32_to_bytes(std.math.nan(f32)))
pub fn parse_bfrobot(allocator: Allocator) !?[]const f32 {
    if (builtin.target.os.tag.isDarwin()) return null;

    const bf_data: []const u8 = std.mem.span(c.get_bfrobot());
    std.log.info("\x1b[32m Raw data read by BFROBOT temp & humidity sensor\x1b[0m: {s}", .{bf_data});
    if (bf_data.len < 2) return null;
    var buf = ArrayList(f32).init(allocator);

    var split = std.mem.splitAny(u8, bf_data, " ");
    while (split.next()) |token| {
        const val = std.fmt.parseFloat(f32, token) catch continue;
        try buf.append(val);
    }

    const data = try buf.toOwnedSlice();
    if (data.len < 2) return null;

    return data;
}
