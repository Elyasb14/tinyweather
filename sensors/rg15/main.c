#include <stdio.h>     // for read, write, and close
#include <string.h>    // for strlen, strcspn, and strdup
#include <fcntl.h>     // for open
#include <unistd.h>    // for read, write, and close
#include <errno.h>     // for error handling
#include <stdlib.h>    // for malloc and free

char* get_data(int fd) {
    // Write "r\n" to the serial device
    char command[] = "r\n";
    write(fd, command, strlen(command));

    // Read data from the serial device
    char buffer[1024];
    read(fd, buffer, 1024);

    // Remove trailing newline characters
    buffer[strcspn(buffer, "\r\n")] = 0;

    // Return the read data as a string
    return strdup(buffer);
}

int main() {
    // Open the serial device
    int fd = open("/dev/tty.usbserial-0001", O_NONBLOCK);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // Get data from the serial device
    char* data = get_data(fd);
    printf("%s\n", data);

    // Free the allocated memory
    free(data);

    // Close the serial device
    close(fd);
    return 0;
}
