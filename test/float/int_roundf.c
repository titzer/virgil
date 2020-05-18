#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
  //  uint64_t v = 0xFFFFFFFFFFFFFFFF;
  uint64_t v = 0x700000000000000;
  for (int i = 0; i < 15; i++) {
    float f = (float)v;
    v -= 1uL << 43;
    printf("\t(%ff, %zuuL),\n", f, (uint64_t)f);
  }
  return 0;
}
