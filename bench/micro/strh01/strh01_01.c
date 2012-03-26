#include <string.h>
#include <stdlib.h>
int main() {
	char *f = "abcdefgjimklmnopqrstuvwxyz";
	char *g = (char *)malloc(32);
	char *e = g + 26;
	strcpy(g, f);
        int i = 0;
	for (i = 0; i < 150000000; i++) {
		char *s = g;
		int sum = 0;
		while (s < e) {
			sum = *s + sum;
			*s = (char)sum;
			s++;	
		}
	}
	return g[0] + g[26];
}
