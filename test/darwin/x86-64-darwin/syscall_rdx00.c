// rdx can be zero after a failed system call, so it cannot signal the error.
#include "rawsyscall.h"

int main() {
	struct kret r = ksyscall(SYS_open, (long)"nonexistent.txt", O_RDONLY, 0);
	check("open(nonexistent.txt, O_RDONLY, 0)", r, r.cf == 1 && r.rdx == 0);
	// rdx here is 420 on a native kernel (untouched) and 0 under Rosetta 2.
	r = ksyscall(SYS_open, (long)"nonexistent.txt", O_RDONLY, 420);
	check("open(nonexistent.txt, O_RDONLY, 420)", r, r.cf == 1 && (r.rdx == 420 || r.rdx == 0));
	return failures;
}
