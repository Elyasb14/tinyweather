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
        .Error => {
            std.log.err("Got bad packet: {any}", .{decoded_packet});
            return tcp.TCPError.BadPacket;
        },
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screen_width = 800;
    const screen_height = 450;
    rl.initWindow(screen_width, screen_height, "tinyweather console");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // Button properties
    const button_width = 200;
    const button_height = 50;
    const buttonx = (screen_width - button_width) / 2;
    const buttony = screen_height - 100;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.dark_gray);

        // Draw button
        const mouse_pos = rl.getMousePosition();
        const is_mouse_over_button =
            mouse_pos.x >= buttonx and mouse_pos.x <= buttonx + button_width and
            mouse_pos.y >= buttony and mouse_pos.y <= buttony + button_height;

        // Button colors
        const button_color = if (is_mouse_over_button) rl.Color.light_gray else rl.Color.gray;

        // Draw button rectangle
        rl.drawRectangle(buttonx, buttony, button_width, button_height, button_color);

        // Draw button text
        rl.drawText("Get Rain Data", buttonx + 40, buttony + 15, 20, rl.Color.black);

        // Check for button click
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            if (is_mouse_over_button) {
                const rain_data = try get_rain(allocator);

                for (rain_data) |sensor_data| {
                    std.debug.print("Sensor Type: {}, Value: {}\n", .{ sensor_data.sensor_type, sensor_data.val });
                }
            }
        }
        // Draw received rain text
    }
}
