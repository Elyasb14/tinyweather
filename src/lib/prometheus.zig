const std = @import("std");

pub const Gauge = struct {
    name: []const u8,
    help_text: []const u8,
    val: f32,

    pub fn init(name: []const u8, help_text: []const u8) Gauge {
        return .{
            .name = name,
            .help_text = help_text,
            .val = std.math.nan(f32),
        };
    }

    pub fn set(self: *Gauge, val: f32) void {
        self.val = val;
    }

    pub fn to_prometheus(self: *const Gauge, allocator: std.mem.Allocator) ![]const u8 {
        var result = std.ArrayList(u8).init(allocator);
        errdefer result.deinit();

        // Write HELP metadata
        try result.writer().print("# HELP {s} {s}\n", .{
            self.name,
            self.help_text,
        });

        // Write TYPE metadata
        try result.writer().print("# TYPE {s} gauge\n", .{
            self.name,
        });

        // Write the actual gauge value
        try result.writer().print("{s} {d}\n", .{
            self.name,
            self.val,
        });

        return result.toOwnedSlice();
    }
};
