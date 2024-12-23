#include "linux/i2c-dev.h"
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdlib.h>
#include <math.h>

#define BME_DEV_ADDR 0x77
#define BME_LEN_TEMP_COEFF_1 UINT8_C(23)
#define BME680_REG_ID 0xD0
#define BME680_REG_TEMP_CALIB 0xE9
#define BME680_REG_CTRL_MEAS 0x74
#define BME680_REG_STATUS 0x73
#define BME680_REG_DATA 0x1D
#define BME680_REG_CTRL_GAS 0x71
#define BME680_REG_GAS_WAIT 0x64
#define BME680_REG_CTRL_HUM 0x72

// Calibration parameters for the temperature
static int t1_cal, t2_cal, t3_cal;
static int32_t t_fine; // Fine temperature

// Function to read a number of bytes from a given register
int read_i2c_bytes(int fd, uint8_t reg, uint8_t *data, size_t length) {
    int ret_code = write(fd, &reg, 1); // Send the register address
    if (ret_code != 1) {
        printf("Failed to write register address: %d\n", ret_code);
        return -1;
    }

    int res = read(fd, data, length); // Read the data from the register
    if (res != length) {
        printf("Failed to read data: %d\n", res);
        return -1;
    }

    return 0;
}

// Convert raw temperature data into Celsius
float compensate_temperature(int32_t raw_temp) {
    int32_t var1, var2;

    // Calculate temperature compensation
    var1 = ((((raw_temp >> 3) - (t1_cal << 1))) * (t2_cal)) >> 11;
    var2 = (((((raw_temp >> 4) - t1_cal) * ((raw_temp >> 4) - t1_cal)) >> 12) * (t3_cal)) >> 14;
    t_fine = var1 + var2;

    // Convert to Celsius
    return (float)(t_fine * 5 + 128) / 256.0f;
}

// Function to initialize the sensor
int bme680_init(int fd) {
    unsigned char reg_buf[32];
    int ret_code, res;

    // Verify chip ID
    reg_buf[0] = BME680_REG_ID;
    ret_code = write(fd, reg_buf, 1);
    res = read(fd, reg_buf, 1);
    if (reg_buf[0] != 0x61 || ret_code < 0 || res != 1) {
        printf("Wrong chip ID: %d\n", reg_buf[0]);
        return -1;
    }

    // Read temperature calibration data
    reg_buf[0] = BME680_REG_TEMP_CALIB;
    ret_code = write(fd, reg_buf, 1);
    res = read(fd, reg_buf, BME_LEN_TEMP_COEFF_1);
    if (ret_code < 0 || res != BME_LEN_TEMP_COEFF_1) {
        printf("Failed to read temperature calibration data\n");
        return -1;
    }

    // Extract calibration coefficients for temperature
    t1_cal = (int)((int16_t)(reg_buf[1] << 8 | reg_buf[0]));
    t2_cal = (int)((int16_t)(reg_buf[3] << 8 | reg_buf[2]));
    t3_cal = (int)((int8_t)(reg_buf[4]));

    return 0;
}

// Read sensor data (temperature, pressure, humidity, gas resistance)
int read_bme680_data(int fd, float *temperature, float *humidity, float *pressure, float *gas) {
    unsigned char reg_buf[32];
    int ret_code;

    // Read the sensor data registers (0x1D to 0x22)
    ret_code = read_i2c_bytes(fd, BME680_REG_DATA, reg_buf, 9);
    if (ret_code < 0) {
        printf("Failed to read data registers\n");
        return -1;
    }

    // Extract temperature data (20-bit)
    int32_t raw_temp = (int32_t)((reg_buf[0] << 12) | (reg_buf[1] << 4) | (reg_buf[2] >> 4));
    *temperature = compensate_temperature(raw_temp);

    // Extract humidity data (16-bit)
    uint16_t raw_humidity = (reg_buf[3] << 8) | reg_buf[4];
    *humidity = (float)raw_humidity / 1024.0f; // Humidity in percentage (0-100)

    // Extract pressure data (20-bit)
    uint32_t raw_pressure = (reg_buf[5] << 12) | (reg_buf[6] << 4) | (reg_buf[7] >> 4);
    *pressure = (float)raw_pressure / 16.0f; // Pressure in hPa

    // Extract gas resistance (16-bit)
    uint16_t raw_gas = (reg_buf[8] << 8) | reg_buf[9];
    *gas = (float)raw_gas;

    return 0;
}

int main() {
    int bme_fd = open("/dev/i2c-1", O_RDWR);
    if (bme_fd < 0) {
        printf("Can't open device: %d\n", bme_fd);
        return -1;
    }

    // Set I2C slave address
    if (ioctl(bme_fd, I2C_SLAVE, BME_DEV_ADDR) < 0) {
        printf("Can't call ioctl\n");
        close(bme_fd);
        return -1;
    }

    // Initialize the sensor
    if (bme680_init(bme_fd) < 0) {
        printf("Sensor initialization failed\n");
        close(bme_fd);
        return -1;
    }

    // Variables to hold sensor data
    float temperature, humidity, pressure, gas;

    // Read sensor data
    if (read_bme680_data(bme_fd, &temperature, &humidity, &pressure, &gas) < 0) {
        printf("Failed to read sensor data\n");
        close(bme_fd);
        return -1;
    }

    // Print sensor data
    printf("Temperature: %.2f °C\n", temperature);
    printf("Humidity: %.2f %%\n", humidity);
    printf("Pressure: %.2f hPa\n", pressure);
    printf("Gas resistance: %.2f ohms\n", gas);

    // Close the I2C device
    close(bme_fd);
    return 0;
}

