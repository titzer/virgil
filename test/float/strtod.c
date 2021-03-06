#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
  for (int i = 1; i < argc; i++) {
    double d = strtod(argv[i], NULL);
    int64_t* p = (int64_t*)&d;
    printf("%s %lfd 0x%016lx\n", argv[i], d, *p);
  }
  return 0;
}
