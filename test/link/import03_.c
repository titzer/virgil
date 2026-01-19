# include <stdio.h>
# include <stdlib.h>

extern int vmain(void *, int);

int main(int argc, char *argv[]) {
  int i = atoi(argv[1]);
  int result = vmain(NULL, i);
  printf("%d\n", result);
  return 0;
}

int xmeth(int x) { return x + 1000000000; }
