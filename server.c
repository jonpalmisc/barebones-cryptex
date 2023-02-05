//
// This is a modified version of the "simple server" example provided with the
// SRD repo; it is Apple's code (licensed under Apache 2.0), not mine.
//

#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include <os/log.h>

#define PORT 7070

int main(int argc, char **argv)
{
    os_log_t log = os_log_create("com.example.barebones", "server");

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);

    int sock_fd = -1;
    sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (bind(sock_fd, (struct sockaddr *)&addr, sizeof(addr))) {
        os_log_error(log, "Failed to bind to 0.0.0.0:%d (%s)", PORT, strerror(errno));
        return 1;
    }
    if (listen(sock_fd, 5)) {
        os_log_error(log, "Failed to listen with file descriptor %d (%s)", sock_fd, strerror(errno));
        return 1;
    }

    while (true) {
        struct sockaddr_in client;
        socklen_t client_size = sizeof(client);
        int fd = accept(sock_fd, (struct sockaddr *)&client, &client_size);

        dup2(fd, 0);
        dup2(fd, 1);

        fprintf(stdout, "pid=%d, CRYPTEX_MOUNT_PATH=\"%s\"\n", getpid(), getenv("CRYPTEX_MOUNT_PATH"));
        fflush(stdout);

        close(fd);
    }

    return 0;
}
