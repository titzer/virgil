#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#define BUF_SIZE 4096

char buffer[BUF_SIZE];

int main(int argc, char* argv[]) {
  for (int i = 1; i < argc; i++) {
    printf("%s:\n", argv[i]);
    int fd = open(argv[i], O_RDONLY);
    int r = 0;
    if (fd >= 0) {
      do {
        r = read(fd, buffer, BUF_SIZE);
        write(1, buffer, r);
      } while (r > 0);
      close(fd);
    } else {
        printf("error opening input %s: %s\n", argv[i], strerror(errno));
    }
  }
  return 0;
}
