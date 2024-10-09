const std = @import("std");
const tcp = @import("../tcp.zig");
const testing = std.testing;

pub fn main() !void {
    std.debug.print("*** benchmarking end to end without network connection overhead", .{});
    const allocator = std.heap.page_allocator;
    const sensors = &[_]tcp.SensorType{ tcp.SensorType.Gas, tcp.SensorType.Temp };
    const sensor_request = tcp.SensorRequest.init(sensors);
    const encoded_sensor_request = try sensor_request.encode(allocator);
    defer allocator.free(encoded_sensor_request);
    try testing.expectEqualSlices(u8, encoded_sensor_request, &[_]u8{ 3, 0 });
    const packet = tcp.Packet.init(1, tcp.PacketType.SensorRequest, encoded_sensor_request);
    const encoded_packet = try packet.encode(allocator);
    defer allocator.free(encoded_packet);
    const decoded_packet = try tcp.Packet.decode(encoded_packet);
    switch (decoded_packet.type) {
        .SensorRequest => {
            const decoded_request_packet = try tcp.SensorRequest.decode(decoded_packet.data, allocator);
            defer allocator.free(decoded_request_packet.sensors);
            try testing.expectEqualDeep(decoded_request_packet, sensor_request);
            const response_packet = tcp.SensorResponse.init(decoded_request_packet, undefined);
            const encoded_response_packet = try response_packet.encode(allocator);
            defer allocator.free(encoded_response_packet);
            const new_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response_packet);
            const new_packet_encoded = try new_packet.encode(allocator);
            defer allocator.free(new_packet_encoded);
            const new_packet_decoded = tcp.Packet.decode(new_packet_encoded);
            try testing.expectEqualDeep(new_packet, new_packet_decoded);
        },
        else => {},
    }
    try testing.expectEqualDeep(packet, decoded_packet);
}
