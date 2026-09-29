// The kernel both sets and clears the carry flag: its state going into a
// system call never leaks out.
#include "rawsyscall.h"

int main() {
	struct kret r = ksyscall_cf(1, SYS_open, (long)"test.txt", O_RDONLY, 0);
	long fd = r.rax;
	check("CF=1; open(test.txt)", r, r.cf == 0 && fd > 2 && fd < 1000);
	r = ksyscall_cf(1, SYS_close, fd, 0, 0);
	check("CF=1; close(fd)", r, r.cf == 0 && r.rax == 0);
	r = ksyscall_cf(1, SYS_open, (long)"nonexistent.txt", O_RDONLY, 0);
	check("CF=1; open(nonexistent.txt)", r, r.cf == 1 && r.rax == ENOENT);
	r = ksyscall_cf(0, SYS_open, (long)"nonexistent.txt", O_RDONLY, 0);
	check("CF=0; open(nonexistent.txt)", r, r.cf == 1 && r.rax == ENOENT);
	return failures;
}
