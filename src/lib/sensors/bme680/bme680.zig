const std = @import("std");

// int bme_fd = open("/dev/i2c-1", O_RDWR);
//   if (bme_fd < 0) {
//     printf("can't open device: %d\n", bme_fd);
//     return -1;
//   }
//
//   // this ioctl sets any read or writes to bme_fd to use the i2c slave addr 0x77
//   if (ioctl(bme_fd, I2C_SLAVE, BME_DEV_ADDR) < 0) {
//     printf("can't call ioctl");
//     return -1;
//   }
//
//   unsigned char reg_buf[32];
//   int ret_code, res;
//
//   // 0xd0 is the chip id register
//   // write the reg addr to the bme_fd, read the result
//   // result should be 0x61 (or 97)
//   reg_buf[0] = 0xd0;
//   ret_code = write(bme_fd, reg_buf, 1);
//   res = read(bme_fd, reg_buf, 1);
//   if (reg_buf[0] != 97 || ret_code < 0 || res != 1) {
//     printf("%d is the wrong chip id", reg_buf[0]);
//     return -1;
//
//
//

pub fn bme_init() !void {
    const file = try std.fs.cwd().openFile("/dev/i2c-1", .{});

    if (std.c.ioctl(@intCast(file.handle), @intCast(0x0703), @as(c_uint, @intCast(0x77))) < 0) {
        std.debug.print("can't call ioctl\n", .{});
    }

    var buf: [32]u8 = undefined;

    buf[0] = 0xd0;

    _ = try file.write(&buf);
    std.debug.assert(buf[0] == 97);
}
