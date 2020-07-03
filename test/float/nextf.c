#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char* argv[]) {
  for (int i = 1; i < argc; i++) {
    int out = 0;
    if (argv[i][0] == '-') {
      // negative
      int64_t v = atol(argv[i]);
      for (int j = 1; out < 21; j++) {
	int64_t x = v + j;
	if (x == (int64_t)(float)x) {
	  printf("%ld\n", x);
	  out++;
	}
	x = v - j;
	if (x == (int64_t)(float)x) {
	  printf("%ld\n", x);
	  out++;
	}
      }
    } else {
      // positive
      uint64_t v = strtoull(argv[i], NULL, 10);
      for (int j = 1; out < 21; j++) {
	uint64_t x = v + j;
	if (x == (uint64_t)(float)x) {
	  printf("%lu\n", x);
	  out++;
	}
	x = v - j;
	if (x == (uint64_t)(float)x) {
	  printf("%lu\n", x);
	  out++;
	}
      }
    }
    
  }
  return 0;
}
