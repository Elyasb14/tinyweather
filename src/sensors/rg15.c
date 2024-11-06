#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <stdlib.h>
#include "rg15.h"

#define MAX_BUFFER 1024
#define DEFAULT_DEVICE "/dev/ttyUSB0"
#define DARWIN_DEVICE "/dev/tty.usbserial-0001"

// Initialize the serial device
RG15Device* rg15_init(const char* device) {
    RG15Device* dev = malloc(sizeof(RG15Device));
    if (!dev) {
        perror("Failed to allocate device structure");
        return NULL;
    }

    // Select appropriate device based on platform
    #ifdef __APPLE__
        strncpy(dev->device, DARWIN_DEVICE, sizeof(dev->device) - 1);
    #else
        strncpy(dev->device, device ? device : DEFAULT_DEVICE, sizeof(dev->device) - 1);
    #endif

    //printf("Opening device: %s\n", dev->device);

    // Open serial port
    dev->fd = open(dev->device, O_RDWR);
    if (dev->fd < 0) {
        perror("Error opening serial port");
        free(dev);
        return NULL;
    }

    //printf("Successfully opened device with fd: %d\n", dev->fd);

    // Configure serial port
    if (tcgetattr(dev->fd, &dev->tty) != 0) {
        perror("Error getting serial port attributes");
        close(dev->fd);
        free(dev);
        return NULL;
    }

    // Set serial port parameters (matching Python's default settings)
    cfsetispeed(&dev->tty, B9600);
    cfsetospeed(&dev->tty, B9600);
    dev->tty.c_cflag &= ~PARENB;        // No parity
    dev->tty.c_cflag &= ~CSTOPB;        // 1 stop bit
    dev->tty.c_cflag &= ~CSIZE;
    dev->tty.c_cflag |= CS8;            // 8 bits per byte
    dev->tty.c_cflag &= ~CRTSCTS;       // No hardware flow control
    dev->tty.c_cflag |= CREAD | CLOCAL; // Enable reading & ignore ctrl lines

    dev->tty.c_lflag &= ~ICANON;        // Disable canonical mode
    dev->tty.c_lflag &= ~ECHO;          // Disable echo
    dev->tty.c_lflag &= ~ECHOE;         // Disable erasure
    dev->tty.c_lflag &= ~ECHONL;        // Disable new-line echo
    dev->tty.c_lflag &= ~ISIG;          // Disable interpretation of INTR, QUIT and SUSP

    dev->tty.c_iflag &= ~(IXON | IXOFF | IXANY);   // Turn off software flow control
    dev->tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL);

    dev->tty.c_oflag &= ~OPOST;         // Prevent special interpretation of output bytes
    dev->tty.c_oflag &= ~ONLCR;         // Prevent conversion of newline to carriage return/line feed

    // Set timeout to 3 seconds (matching Python version)
    dev->tty.c_cc[VTIME] = 30;          // Wait up to 3 seconds (30 deciseconds)
    dev->tty.c_cc[VMIN] = 0;            // No minimum number of characters

    if (tcsetattr(dev->fd, TCSANOW, &dev->tty) != 0) {
        perror("Error setting serial port attributes");
        close(dev->fd);
        free(dev);
        return NULL;
    }

    // Flush anything in the buffer
    tcflush(dev->fd, TCIOFLUSH);
    
    //printf("Serial port configured successfully\n");
    return dev;
}

char* rg15_get_data(RG15Device* dev) {
    static char buffer[MAX_BUFFER];
    ssize_t bytes_written;
    
    bytes_written = write(dev->fd, "r\n", 2);
    if (bytes_written != 2) {
        perror("Failed to write command");
        return NULL;
    }
    
    // Small delay to ensure command is sent
    usleep(100000);  // 100ms delay
    
    ssize_t n = 0;
    int retries = 3;
    
    while (retries > 0) {
        n = read(dev->fd, buffer, sizeof(buffer) - 1);
        
        if (n > 0) {
            buffer[n] = '\0';
            // for (int i = 0; i < n; i++) {
            //     printf("%02X ", (unsigned char)buffer[i]);
            // }
            // printf("\n");
            
            // Remove CR/LF
            char* p = strchr(buffer, '\r');
            if (p) *p = '\0';
            p = strchr(buffer, '\n');
            if (p) *p = '\0';
            
            return buffer;
        }
        
        retries--;
        usleep(100000);  // Wait 100ms between retries
    }
    
    printf("No data received after 3 attempts\n");
    return NULL;
}

// Parse data into key-value pairs with debug info
KeyValuePair* rg15_parse_data(const char* data, int* count) {
    if (!data || !count) return NULL;
    
    printf("Parsing data string: '%s'\n", data);
    
    // First, count the number of comma-separated groups
    *count = 1;
    for (const char* p = data; *p; p++) {
        if (*p == ',') (*count)++;
    }
    
    printf("Found %d groups\n", *count);

    KeyValuePair* pairs = malloc(*count * sizeof(KeyValuePair));
    if (!pairs) {
        perror("Failed to allocate memory for pairs");
        return NULL;
    }

    char* data_copy = strdup(data);
    if (!data_copy) {
        perror("Failed to duplicate data string");
        free(pairs);
        return NULL;
    }

    char* token = strtok(data_copy, ",");
    int i = 0;

    while (token && i < *count) {
        printf("Processing token: '%s'\n", token);
        
        // Split each group into key and value
        char* space = strchr(token, ' ');
        if (space) {
            *space = '\0';
            strncpy(pairs[i].key, token, sizeof(pairs[i].key) - 1);
            strncpy(pairs[i].value, space + 1, sizeof(pairs[i].value) - 1);
            pairs[i].key[sizeof(pairs[i].key) - 1] = '\0';
            pairs[i].value[sizeof(pairs[i].value) - 1] = '\0';
            printf("Parsed pair - Key: '%s', Value: '%s'\n", pairs[i].key, pairs[i].value);
            i++;
        } else {
            printf("Warning: No space found in token\n");
        }
        token = strtok(NULL, ",");
    }

    free(data_copy);
    return pairs;
}

// Cleanup
void rg15_cleanup(RG15Device* dev) {
    if (dev) {
        //printf("Closing device fd: %d\n", dev->fd);
        close(dev->fd);
        free(dev);
    }
}

void display_data() {
    RG15Device* dev = rg15_init(NULL);
    if (!dev) {
        fprintf(stderr, "Failed to initialize device\n");
        return;
    }
    char* data = rg15_get_data(dev);
    if (data) {
        printf("Received data: '%s'\n", data);
    } 

    rg15_cleanup(dev);
}

