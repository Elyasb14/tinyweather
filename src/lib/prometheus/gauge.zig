const std = @import("std");

pub const Gauge = struct {
    name: []const u8,
    help_text: []const u8,

    var value: f32 = 0.0;

    pub fn init(name: []const u8, help_text: []const u8) Gauge {
        return .{
            .name = name,
            .help_text = help_text,
        };
    }

    pub fn set(self: *Gauge, val: f32) void {
        self.value = val;
    }

    pub fn to_prometheus(self: *Gauge, allocator: std.mem.Allocator) ![]const u8 {
        return try std.fmt.allocPrint(allocator, "# HELP {s} {s}\n# TYPE {s} gauge\n{s} {d}", .{ self.name, self.help_text, self.name, self.name, value });
    }
    //     def to_prometheus(self) -> str:
    //         return f"""# HELP {self.name} {self.help_text}
    // # TYPE {self.name} gauge
    // {self.name} {self.get()}"""
};
