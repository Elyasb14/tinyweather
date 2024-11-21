const rl = @import("raylib");
const std = @import("std");
const net = std.net;
const assert = std.debug.assert;
const tcp = @import("lib/tcp.zig");

pub fn get_rain(allocator: std.mem.Allocator) ![]tcp.SensorData {
    const address = try net.Address.parseIp4("127.0.0.1", 8080);
    const stream = net.tcpConnectToAddress(address) catch |err| {
        std.log.err("Can't connect to address: {any}... error: {any}", .{ address, err });
        return error.ConnectionRefused;
    };
    std.log.info("\x1b[32mClient initializing communication with: {any}....\x1b[0m", .{address});
    defer stream.close();

    const sensors = &[_]tcp.SensorType{
        tcp.SensorType.RainAcc,
        tcp.SensorType.RainTotalAcc,
        tcp.SensorType.RainEventAcc,
    };
    const sensor_request = tcp.SensorRequest.init(sensors);
    const sensor_request_encoded = try sensor_request.encode(allocator);
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, sensor_request_encoded);
    const encoded_packet = try packet.encode(allocator);

    var buf: [50]u8 = undefined;
    std.log.info("\x1b[32mPacket Sent\x1b[0m: {any}", .{packet});
    _ = try stream.write(encoded_packet);
    const n = try stream.read(&buf);
    std.log.info("\x1b[32mBytes read by stream\x1b[0m: {any}", .{n});
    const decoded_packet = try tcp.Packet.decode(buf[0..n]);
    switch (decoded_packet.type) {
        .SensorResponse => {
            const decoded_sensor_response = try tcp.SensorResponse.decode(sensor_request, decoded_packet.data, allocator);
            std.log.info("\x1b[32mSensor Response Packet Received\x1b[0m: {any}", .{decoded_sensor_response});
            return decoded_sensor_response.data;
        },
        .SensorRequest => {
            std.log.err("Expected SensorResponse, got SensorRequest: {any}", .{decoded_packet});
            return tcp.TCPError.InvalidPacketType;
        },
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screen_width = 1400;
    const screen_height = 700;
    rl.initWindow(screen_width, screen_height, "tinyweather console");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // Button properties
    const button_width = 200;
    const button_height = 50;
    const rain_buttonx = 50;
    const rain_buttony = 50;
    const env_buttonx = 50;
    const env_buttony = 150;

    var rain_data_strings = std.ArrayList([]const u8).init(allocator);
    defer rain_data_strings.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.dark_gray);

        // Draw button
        const mouse_pos = rl.getMousePosition();
        const is_mouse_over_rain_button =
            mouse_pos.x >= rain_buttonx and mouse_pos.x <= rain_buttonx + button_width and
            mouse_pos.y >= rain_buttony and mouse_pos.y <= rain_buttony + button_height;

        const is_mouse_over_env_button =
            mouse_pos.x >= env_buttonx and mouse_pos.x <= env_buttonx + button_width and
            mouse_pos.y >= env_buttony and mouse_pos.y <= env_buttony + button_height;
        // Button colors
        const rain_button_color = if (is_mouse_over_rain_button) rl.Color.light_gray else rl.Color.gray;
        const env_button_color = if (is_mouse_over_env_button) rl.Color.light_gray else rl.Color.gray;

        // Draw button rectangle
        rl.drawRectangle(rain_buttonx, rain_buttony, button_width, button_height, rain_button_color);
        rl.drawRectangle(env_buttonx, env_buttony, button_width, button_height, env_button_color);

        // Draw button text
        rl.drawText("Get Rain Data", rain_buttonx + 40, rain_buttony + 15, 20, rl.Color.black);
        rl.drawText("Get Env data", env_buttonx + 40, env_buttony + 15, 20, rl.Color.black);
        // Check for button click
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            if (is_mouse_over_rain_button) {
                rain_data_strings.clearAndFree();

                const rain_data = try get_rain(allocator);

                for (rain_data) |sensor_data| {
                    const printable = try std.fmt.allocPrint(allocator, "Sensor Type: {}, Value: {}", .{ sensor_data.sensor_type, sensor_data.val });
                    try rain_data_strings.append(printable);
                }
            }
        }

        // Draw all stored rain data strings
        for (rain_data_strings.items, 0..) |str, i| {
            rl.drawText(@ptrCast(str), screen_width / 4, 50 + @as(i32, @intCast(i * 30)), 20, rl.Color.green);
        }
    }
}
