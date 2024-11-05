#ifndef RG15_H
#define RG15_H

#include <termios.h>

typedef struct {
    char key[32];
    char value[32];
} KeyValuePair;

typedef struct {
    int fd;         // File descriptor
    char device[64];
    struct termios tty;
} RG15Device;
// Declare the functions
RG15Device* rg15_init(const char* device);
char* rg15_get_data(RG15Device* dev);
KeyValuePair* rg15_parse_data(const char* data, int* count);
void rg15_cleanup(RG15Device* dev);
void display_data();

#endif // RG15_H
