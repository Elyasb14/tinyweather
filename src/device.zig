const helpers = @import("helpers.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const c = @cImport(@cInclude("sensors/rg15.h"));
const tcp = @import("tcp.zig");

pub fn get_gas() [4]u8 {
    return helpers.f32_to_bytes(172.34);
}

pub fn get_temp() [4]u8 {
    return helpers.f32_to_bytes(17.2);
}

pub fn get_hum() [4]u8 {
    return helpers.f32_to_bytes(111.17);
}

pub fn get_pres() [4]u8 {
    return helpers.f32_to_bytes(1111.4);
}

// this functions returns null when the sensor returns no data or partial data
// the caller should return the bytearrray representing nan in f32 (std.math.inf(f32))
pub fn parse_rain(allocator: Allocator) !?[]const f32 {
    // TODO: this is a HACK
    // this line is only here because sometimes we have a null pointer if there is no rain gauge device
    _ = (std.fs.accessAbsolute("/dev/tty.usbserial-0001", .{})) catch return null;
    var buf = ArrayList(f32).init(allocator);

    // TODO: c.get_rain() can return a null pointer (see rg15.c get_rain())
    // This will eventually get handled when we rewrite rg15.c in zig
    // but it crashes the server because of an assert in std.mem.span
    // what to do about it now?

    const rain_data = std.mem.span(c.get_rain());
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
