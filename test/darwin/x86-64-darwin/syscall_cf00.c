// A failed system call sets the carry flag and returns a positive errno in rax.
#include "rawsyscall.h"

int main() {
	struct kret r = ksyscall(SYS_open, (long)"nonexistent.txt", O_RDONLY, 0);
	check("open(nonexistent.txt, O_RDONLY)", r, r.cf == 1 && r.rax == ENOENT);
	r = ksyscall(SYS_stat, (long)"nonexistent.txt", (long)(char[256]){0}, 0);
	check("stat(nonexistent.txt)", r, r.cf == 1 && r.rax == ENOENT);
	r = ksyscall(SYS_open, (long)"readonly.txt", O_WRONLY, 0);
	check("open(readonly.txt, O_WRONLY)", r, r.cf == 1 && r.rax == EACCES);
	return failures;
}
