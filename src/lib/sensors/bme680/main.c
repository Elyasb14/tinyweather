#include "linux/i2c-dev.h"
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define BME_DEV_ADDR 0x77
#define BME_LEN_TEMP_COEFF_1 UINT8_C(23)
#define BME68X_REG_COEFF2 UINT8_C(0xe1)

static int t1_cal, t2_cal, t3_cal; //temp calibration

int main() {
  int bme_fd = open("/dev/i2c-1", O_RDWR);
  if (bme_fd < 0) {
    printf("can't open device: %d\n", bme_fd);
    return -1;
  }

  // this ioctl sets any read or writes to bme_fd to use the i2c slave addr 0x77
  if (ioctl(bme_fd, I2C_SLAVE, BME_DEV_ADDR) < 0) {
    printf("can't call ioctl");
    return -1;
  }

  unsigned char reg_buf[32];
  int ret_code, res;

  // 0xd0 is the chip id register
  // write the reg addr to the bme_fd, read the result
  // result should be 0x61 (or 97)
  reg_buf[0] = 0xd0;
  ret_code = write(bme_fd, reg_buf, 1);
  res = read(bme_fd, reg_buf, 1);
  if (reg_buf[0] != 97 || ret_code < 0 || res != 1) {
    printf("%d is the wrong chip id\n", reg_buf[0]);
    return -1;
  }

  // get temp calib data
  reg_buf[0] = 0xe9;
  ret_code = write(bme_fd, reg_buf, 1);
  res = read(bme_fd, reg_buf, BME_LEN_TEMP_COEFF_1);
  if (ret_code < 0 || res != BME_LEN_TEMP_COEFF_1) {
    printf("ret_code: %d, res: %d", ret_code, res);
    return -1;
  }

  t1_cal = reg_buf[0];



  return 0;
}
