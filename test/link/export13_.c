# include <stdio.h>
# include <stdint.h>
# include <stdlib.h>
extern void foo(void *, char, short, int, int64_t, float, double, void *, void *, int);
char space[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int main(int argc, char *argv[]) {
  // types of arguments: byte, i16, i32, i64, float, double, Pointer
  char    c = (char   )(atoi(argv[1]));
  short   s = (short  )(atoi(argv[2]));
  int     i = (int    )(atoi(argv[3]));
  int64_t l = (int64_t)(atoi(argv[4]));
  float   f = (float  )(atof(argv[5]));
  double  d = (double )(strtod(argv[6], NULL));
  void   *p = (void * )(atol(argv[7]));
  void *spc = &(space[0]);
  int which = atoi(argv[8]);
  foo(NULL, c, s, i, l, f, d, p, spc, which);
  switch (which) {
  case 0: printf("%d\n"   , *((char    *)(spc))); break;
  case 1: printf("%d\n"   , *((short   *)(spc))); break;
  case 2: printf("%d\n"   , *((int     *)(spc))); break;
  case 3: printf("%ld\n"   , *((int64_t *)(spc))); break;
  case 4: printf("%.1f\n" , *((float   *)(spc))); break;
  case 5: printf("%.1lf\n", *((double  *)(spc))); break;
  default:
  case 6: printf("%ld\n"  , *((int64_t *)(spc))); break;
  }
  return 0;
}
