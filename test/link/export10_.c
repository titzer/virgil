# include <stdio.h>
# include <stdlib.h>
typedef int (*FP)(void *, int);

extern FP getIncr(void *);

int main(int argc, char *argv[]) {
  int i = atoi(argv[1]);
  FP incr = getIncr(NULL);
  int j = (*incr)(NULL, i - 1);
  printf("%d\n", j == 1 ? 89 : 75);
  return 0;
}
