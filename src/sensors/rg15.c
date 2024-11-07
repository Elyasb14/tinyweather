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

typedef struct {
    char key[32];
    char value[32];
} KeyValuePair;

typedef struct {
    int fd;         // File descriptor
    char device[64];
    struct termios tty;
} RG15Device;

// Initialize the serial device
RG15Device* rg15_init(const char* device) {
    
    RG15Device* dev = malloc(sizeof(RG15Device));
    if (!dev) {
        perror("Failed to allocate device structure");
        return NULL;
    }

    #ifdef __APPLE__
        strncpy(dev->device, DARWIN_DEVICE, sizeof(dev->device) - 1);
    #else
        strncpy(dev->device, device ? device : DEFAULT_DEVICE, sizeof(dev->device) - 1);
    #endif

    // Check if device exists
    if (access(dev->device, F_OK) == -1) {
        fprintf(stderr, "Device %s does not exist\n", dev->device);
        free(dev);
        return NULL;
    }

    // Check read/write permissions
    if (access(dev->device, R_OK|W_OK) == -1) {
        fprintf(stderr, "Permission denied for %s\n", dev->device);
        fprintf(stderr, "Try: sudo chmod 666 %s\n", dev->device);
        free(dev);
        return NULL;
    }

    dev->fd = open(dev->device, O_RDWR | O_NOCTTY | O_NONBLOCK);  // Added O_NOCTTY and O_NONBLOCK
    if (dev->fd < 0) {
        perror("Error opening serial port");
        free(dev);
        return NULL;
    }

    if (tcgetattr(dev->fd, &dev->tty) != 0) {
        perror("Error getting serial port attributes");
        close(dev->fd);
        free(dev);
        return NULL;
    }

    // Set serial port parameters with error checking
    
    cfmakeraw(&dev->tty);  // Start with raw mode
    
    if (cfsetispeed(&dev->tty, B9600) < 0 || cfsetospeed(&dev->tty, B9600) < 0) {
        perror("Error setting baud rate");
        close(dev->fd);
        free(dev);
        return NULL;
    }

    // Basic settings
    dev->tty.c_cflag |= (CLOCAL | CREAD);    // Enable receiver, ignore modem controls
    dev->tty.c_cflag &= ~PARENB;             // No parity
    dev->tty.c_cflag &= ~CSTOPB;             // 1 stop bit
    dev->tty.c_cflag &= ~CSIZE;
    dev->tty.c_cflag |= CS8;                 // 8 bits per byte
    dev->tty.c_cflag &= ~CRTSCTS;            // No hardware flow control

    // Setting timeouts
    dev->tty.c_cc[VMIN] = 0;                 // No minimum characters
    dev->tty.c_cc[VTIME] = 10;               // 1 second timeout

    if (tcsetattr(dev->fd, TCSANOW, &dev->tty) != 0) {
        perror("Error setting serial port attributes");
        close(dev->fd);
        free(dev);
        return NULL;
    }

    // Clear the O_NONBLOCK flag
    int flags = fcntl(dev->fd, F_GETFL, 0);
    if (flags == -1) {
        perror("Error getting flags");
        close(dev->fd);
        free(dev);
        return NULL;
    }
    flags &= ~O_NONBLOCK;
    if (fcntl(dev->fd, F_SETFL, flags) == -1) {
        perror("Error setting flags");
        close(dev->fd);
        free(dev);
        return NULL;
    }
    
    tcflush(dev->fd, TCIOFLUSH);
    
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
    } else {
        printf("Failed to get data\n");
    }
    rg15_cleanup(dev);
}

