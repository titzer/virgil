# include <stdio.h>
# include <stdlib.h>

// first void * is the usual "extra" void * for calling Virgil top-level functions
// second void * is the address of the function being passed to Virgil; it should
//   accept an "extra" void * and an int, and return an int
// int argument is the integer being passed over to Virgil
extern int callIncr(void *, void *, int);

int incr(void *p, int i) { return i + 1; }

int main(int argc, char *argv[]) {
  int i = atoi(argv[1]);
  void *p = &incr;
  int j = callIncr(NULL, p, i - 1);
  printf("%d\n", j == 1 ? 89 : 75);
  return 0;
}
