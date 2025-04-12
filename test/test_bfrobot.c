#include <fcntl.h>

#ifdef __unix__
    #include <linux/i2c-dev.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <unistd.h>

#define I2C_DEVICE                                                             \
  "/dev/i2c-1" // Change this to the appropriate I2C bus on your system
#define SENSOR_ADDR 0x40 // The I2C address of your sensor

int i2c_file;

// Function to read registers from the I2C device
int read_sensor_reg(int file, int reg, unsigned char *buffer, size_t length) {
  if (buffer == NULL) {
    printf("Buffer ERROR!! : null pointer\n");
    return -1;
  }

  // Write the register address we want to read from
  if (write(file, &reg, 1) != 1) {
    printf("Failed to write register address\n");
    return -1;
  }

  // Wait a bit for the sensor to process
  usleep(20000); // 20ms delay

  // Read the data from the specified register
  if (read(file, buffer, length) != length) {
    printf("Failed to read from device\n");
    return -1;
  }

  return length;
}

char* get_data() {

    // Select appropriate device based on platform
    #ifdef __APPLE__
        return NULL;
    #else
      unsigned char buf[4];
      uint data, data1;
      float temp, hum;
        char* result_string = NULL;

      // Open the I2C device
      if ((i2c_file = open(I2C_DEVICE, O_RDWR)) < 0) {
        printf("Failed to open the I2C bus\n");
        return NULL;
      }

      // Set the I2C slave address for all subsequent I/O
      if (ioctl(i2c_file, I2C_SLAVE, SENSOR_ADDR) < 0) {
        printf("Failed to acquire bus access and/or talk to slave\n");
        return NULL;
      }

      // Read temperature and humidity registers
      if (read_sensor_reg(i2c_file, 0x00, buf, 4) < 0) {
        printf("Error reading sensor data\n");
        return NULL;
      } else {
        // Calculate temperature and humidity like in the Arduino code
        data = (buf[0] << 8) | buf[1];
        data1 = (buf[2] << 8) | buf[3];

        temp = ((float)data * 165.0 / 65535.0) - 40.0;
        hum = ((float)data1 / 65535.0) * 100.0;

        sprintf(result_string, "%.2f %.2f\n", temp, hum);
        

        usleep(500000); // 500ms delay

        close(i2c_file);
        return result_string;
      }
#endif

}

int main() {
    char* data = get_data();
    printf("%s\n", data);
}

