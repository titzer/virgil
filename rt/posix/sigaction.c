#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <signal.h>

#define PRINT_OFFSET(x) printf("  ." #x " = %zu\n", (char*)(&thing.x) - (char*)(&thing));

int main(int argc, char **argv) {
  struct sigaction thing;

  printf("sizeof(sigaction) = %zu\n", sizeof(thing));
  PRINT_OFFSET(sa_handler);
  PRINT_OFFSET(sa_sigaction);
  PRINT_OFFSET(sa_mask);
  PRINT_OFFSET(sa_flags);
  PRINT_OFFSET(sa_restorer);
  // sa_handler
  // sa_sigaction
  // sa_mask
  // sa_flags
  // sa_restorer
}
