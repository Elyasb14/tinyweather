const helpers = @import("helpers.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const c = @cImport(@cInclude("sensors/rg15.h"));
const tcp = @import("tcp.zig");

const RainSensorValues = enum {
    Acc,
    EventAcc,
    TotalAcc,
    RInt,
};

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
// the caller should return the bytearrray representing inf in f32 (std.math.inf(f32)
fn parse_rain(allocator: Allocator) !?[]const f32 {
    var buf = ArrayList(f32).init(allocator);

    // TODO: c.get_rain() can return a null pointer (see rg15.c get_rain())
    // This will eventuall get handled when we rewrite rg15.c in zig
    // but it crashes the server because of an assert in std.mem.span
    // what to do about it now?
    const rain_data = std.mem.span(c.get_rain());
    if (rain_data.len < 4) return null;

    var split = std.mem.splitAny(u8, rain_data, " ,{}");
    while (split.next()) |token| {
        if (std.mem.eql(u8, token, "")) continue;
        const val = std.fmt.parseFloat(f32, token) catch continue;
        try buf.append(val);
    }
    const data = try buf.toOwnedSlice();
    if (data.len < 4) return null;
    return data;
}

// TODO: we parse the data from the sensor every time we get the data from the sensor
// change this to only happen once
pub fn get_rainacc(allocator: Allocator) ![4]u8 {
    const rain_acc = (try parse_rain(allocator)) orelse return helpers.f32_to_bytes(std.math.inf(f32));
    return helpers.f32_to_bytes(rain_acc[0]);
}

pub fn get_raineventacc(allocator: Allocator) ![4]u8 {
    const rain_acc = (try parse_rain(allocator)) orelse return helpers.f32_to_bytes(std.math.inf(f32));
    return helpers.f32_to_bytes(rain_acc[1]);
}
pub fn get_raintotalacc(allocator: Allocator) ![4]u8 {
    const rain_totalacc = (try parse_rain(allocator)) orelse return helpers.f32_to_bytes(std.math.inf(f32));
    return helpers.f32_to_bytes(rain_totalacc[2]);
}
pub fn get_rainrint(allocator: Allocator) ![4]u8 {
    const rain_acc = (try parse_rain(allocator)) orelse return helpers.f32_to_bytes(std.math.inf(f32));
    return helpers.f32_to_bytes(rain_acc[3]);
}
