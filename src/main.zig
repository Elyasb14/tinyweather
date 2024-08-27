const std = @import("std");
const net = std.net;

const ArenaAllocator = std.heap.ArenaAllocator;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator() gc;
    
    const address = try net.Address.parseIp("127.0.0.1", 5501);
    var listener = try address.listen(.{
        .reuse_address = true,
        .kernel_backlog = 1024,
    });
    defer listener.deinit();
    std.log.info("listening at {any}\n", .{address});

}
