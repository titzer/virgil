# include <stdio.h>
# include <stdlib.h>
extern int bar(void *, int);
int main(int argc, char *argv[]) {
  int i = atoi(argv[1]);
  int j = bar(NULL, i + 1);
  printf("%d\n", j == 1 ? 89 : 75);
  return 0;
}
