# Temp Sensors

We have a problem. I hate how we have to go to python and download a ton of libs to get temperature. We need to explore other options. I bought [this](https://wiki.dfrobot.com/SKU_SEN0546_I2C_Temperature_and_Humidity_Sensor_Stainless_Steel_Shell), it seems to be pretty simple. I've found some [python sample code](https://www.dfrobot.com/forum/topic/335192?srsltid=AfmBOopzBqwovoCCgz2HSF9Vry_XfEjiD5f3uFfIwgdyoAB5dEG5SYzX) that seems pretty simple. I'd like to write it in zig, but c would be fine. 

This code should work?

```c
// sudo apt-get install libi2c-dev i2c-tools

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <stdint.h>

#define I2C_DEVICE "/dev/i2c-1"  // Equivalent to channel 1 in Python
#define SENSOR_ADDR 0x40         // SEN0546 defaults to address 0x40

int main() {
    int i2c_file;
    uint8_t reg_addr;
    uint8_t val1, val2, val3, val4;
    uint16_t tempData, humidityData;
    float temp, hum;
    
    // Open the I2C device
    if ((i2c_file = open(I2C_DEVICE, O_RDWR)) < 0) {
        perror("Failed to open the I2C bus");
        return 1;
    }
    
    // Set the I2C slave address for all subsequent I/O
    if (ioctl(i2c_file, I2C_SLAVE, SENSOR_ADDR) < 0) {
        perror("Failed to acquire bus access and/or talk to slave");
        close(i2c_file);
        return 1;
    }
    
    while (1) {
        // Request temperature read
        reg_addr = 0x00;
        if (write(i2c_file, &reg_addr, 1) != 1) {
            perror("Failed to write temperature request");
            close(i2c_file);
            return 1;
        }
        
        // Wait briefly
        usleep(300000);  // 300ms
        
        // Read the 2 byte temperature value
        val1 = 0;
        val2 = 0;
        if (read(i2c_file, &val1, 1) != 1 || read(i2c_file, &val2, 1) != 1) {
            perror("Failed to read temperature data");
            close(i2c_file);
            return 1;
        }
        
        // Wait briefly
        usleep(300000);  // 300ms
        
        // Request humidity read
        reg_addr = 0x01;
        if (write(i2c_file, &reg_addr, 1) != 1) {
            perror("Failed to write humidity request");
            close(i2c_file);
            return 1;
        }
        
        // Wait briefly
        usleep(300000);  // 300ms
        
        // Read the 2 byte humidity value
        val3 = 0;
        val4 = 0;
        if (read(i2c_file, &val3, 1) != 1 || read(i2c_file, &val4, 1) != 1) {
            perror("Failed to read humidity data");
            close(i2c_file);
            return 1;
        }
        
        // Calculate the human-readable values
        tempData = (val1 << 8) | val2;
        humidityData = (val3 << 8) | val4;
        
        temp = (tempData * 165.0 / 65535.0) - 40.0;
        hum = (humidityData / 65535.0) * 100.0;
        
        // Print the result
        printf("temp(C): %.2f\n", temp);
        printf("hum(%%RH): %.2f\n", hum);
        
        sleep(1);  // 1 second delay
    }
    
    close(i2c_file);
    return 0;
}
```

[this](https://raspberrypihobbyist.blogspot.com/2015/02/using-am2315-temperaturehumidity-sensor.html) looks like an interesting temp sensor option too. 
