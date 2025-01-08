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

    pub fn to_prometheus(self: *Gauge, allocator: std.mem.Allocator) ![]const u8 {
        // TODO: remove allocPrint here and replace with arraylist
        return std.fmt.allocPrint(allocator, "# HELP {s} {s}\n# TYPE {s} gauge\n{s} {d}\n", .{ self.name, self.help_text, self.name, self.name, self.val });
    }
};
