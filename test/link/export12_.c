# include <stdio.h>
# include <stdint.h>
# include <stdlib.h>
extern char   foo_b(void *, char);
extern short  foo_s(void *, short);
extern int    foo_i(void *, int);
extern int64_t foo_l(void *, int64_t);
extern float  foo_f(void *, float);
extern double foo_d(void *, double);
extern void  *foo_p(void *, void *);
int main(int argc, char *argv[]) {
  // types of arguments: byte, i16, i32, i64, float, double, Pointer
  char    c = foo_b(NULL, (char   )(atoi(argv[1])));
  short   s = foo_s(NULL, (short  )(atoi(argv[2])));
  int     i = foo_i(NULL, (int    )(atoi(argv[3])));
  int64_t l = foo_l(NULL, (int64_t)(atoi(argv[4])));
  float   f = foo_f(NULL, (float  )(atof(argv[5])));
  double  d = foo_d(NULL, (double )(strtod(argv[6], NULL)));
  void   *p = foo_p(NULL, (void * )(atol(argv[7])));
  printf("%d %d %d %ld %.1f %.1lf %ld\n", c, s, i, l, f, d, (long)(p));
  return 0;
}
