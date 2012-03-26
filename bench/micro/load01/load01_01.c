#include <stdio.h>
#include <unistd.h>

char buf[4096];

int main(int argc, char **argv) {
  int hash = 0;
  int fd = open(argv[1], 0);
  if (fd < 0) {
    printf("could not open: %s\n", argv[1]);
    return 1;
  }

  while (1) {
    int i = 0, r = read(fd, buf, 4096);
    if (r <= 0) break;
    for (i = 0; i < r; i++) {
      hash = hash * 33 + buf[i];
    }
  }

  close(fd);
  return hash;
}
