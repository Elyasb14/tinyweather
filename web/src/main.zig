const std = @import("std");
const zap = @import("zap");

fn on_request_minimal(r: zap.Request) void {
    r.sendBody("./index.html") catch return;
}
pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 8080,
        .on_request = on_request_minimal,
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
