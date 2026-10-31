/* Test-only adapter: network-disabled RetroArch omits stdin O_NONBLOCK setup. */
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
    int flags = fcntl(STDIN_FILENO, F_GETFL);
    if (argc < 2 || flags < 0 ||
        fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK) < 0) {
        return 2;
    }
    execvp(argv[1], argv + 1);
    perror("nonblocking-stdin exec");
    return 1;
}
