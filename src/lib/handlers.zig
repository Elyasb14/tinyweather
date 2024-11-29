const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const tcp = @import("tcp.zig");

pub const ClientHandler = struct {
    stream: net.Stream,

    pub fn init(stream: net.Stream) ClientHandler {
        return .{
            .stream = stream,
        };
    }

    pub fn deinit(self: *ClientHandler) void {
        std.log.info("\x1b[32mStream closed\x1b[0m: {any}", .{self.stream});
        self.stream.close();
    }

    pub fn handle_request(self: *ClientHandler, allocator: Allocator) !?void {
        var buf: [50]u8 = undefined;
        const bytes_read = try self.stream.read(&buf);
        if (bytes_read == 0) return null;
        std.log.info("\x1b[32mBytes read by connection\x1b[0m: {any}", .{bytes_read});
        const received_packet = tcp.Packet.decode(buf[0..bytes_read]) catch |err| {
            std.log.err("\x1b[31mClient wrote a bad packet, error\x1b[0m: {any}", .{err});
            return tcp.TCPError.BadPacket;
        };

        std.log.info("\x1b[32mPacket received from stream\x1b[0m: {any}", .{received_packet});

        switch (received_packet.type) {
            .SensorRequest => {
                const decoded_request = try tcp.SensorRequest.decode(received_packet.data, allocator);

                std.log.info("\x1b[32mDecoded Response Packet\x1b[0m: {any}", .{decoded_request});

                const sensor_response = tcp.SensorResponse.init(decoded_request, undefined);
                const encoded_response = try sensor_response.encode(allocator);
                std.log.info("\x1b[32mEncoded SensorResponse packet\x1b[0m: {any}", .{encoded_response});

                const response_packet = tcp.Packet.init(1, tcp.PacketType.SensorResponse, encoded_response);
                std.log.info("\x1b[32mPacket response to be sent to stream\x1b[0m: {any}", .{response_packet});

                const encoded_response_packet = try response_packet.encode(allocator);
                _ = try self.stream.write(encoded_response_packet);
            },
            .SensorResponse => {
                std.log.err("\x1b[31mExpected SensorRequest packet, got SensorResponse\x1b[0m: {any}", .{received_packet.type});
                return tcp.TCPError.InvalidPacketType;
            },
        }
    }
};

const ProxyHandler = struct {};
