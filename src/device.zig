const helpers = @import("helpers.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const c = @cImport(@cInclude("sensors/rg15.h"));

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

pub fn parse_rain(allocator: Allocator) Allocator.Error![]const f32 {
    var buf = ArrayList(f32).init(allocator);
    const rain_data = std.mem.span(c.get_rain());
    var split = std.mem.splitAny(u8, rain_data, " ,{}");
    while (split.next()) |x| {
        if (std.mem.eql(u8, x, "")) continue;
        const val = std.fmt.parseFloat(f32, x) catch continue;
        try buf.append(val);
    }
    return try buf.toOwnedSlice();
}

// TODO: we parse the data from the sensor every time we get the data from the sensor
// change this to only happen once
pub fn get_rainacc(allocator: Allocator) ![4]u8 {
    const rain_acc = try parse_rain(allocator);
    return helpers.f32_to_bytes(rain_acc[0]);
}

pub fn get_raineventacc(allocator: Allocator) ![4]u8 {
    const rain_acc = try parse_rain(allocator);
    return helpers.f32_to_bytes(rain_acc[1]);
}
pub fn get_raintotalacc(allocator: Allocator) ![4]u8 {
    const rain_totalacc = try parse_rain(allocator);
    return helpers.f32_to_bytes(rain_totalacc[2]);
}
pub fn get_rainrint(allocator: Allocator) ![4]u8 {
    const rain_acc = try parse_rain(allocator);
    return helpers.f32_to_bytes(rain_acc[3]);
}
