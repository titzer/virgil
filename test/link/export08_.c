# include <stdio.h>
# include <stdlib.h>
extern int foo(void *, int);
extern int xfoo(void *, int);
int main(int argc, char *argv[]) {
  int i = atoi(argv[1]);
  int j = foo(NULL, i - 1);
  int xj = xfoo(NULL, i - 1);
  int k = !(j == xj);
  printf("%d\n", (j + k) == 1 ? 89 : 75);
  return 0;
}
