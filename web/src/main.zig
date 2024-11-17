const std = @import("std");
const zap = @import("zap");
const http = std.http;

fn on_request(r: zap.Request) void {
    if (r.methodAsEnum() != .GET) return;

    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/why")) {
            r.setContentTypeFromFilename("why.html") catch return;
            r.sendBody("hello") catch return;
        } else {
            r.setStatus(.bad_request);
            r.setContentType(.HTML) catch return;
            r.sendBody("<p> 400 bad request</p>");
        }
    }
}
pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .public_folder = "src",
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
