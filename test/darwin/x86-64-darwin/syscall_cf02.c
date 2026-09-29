// A successful system call clears the carry flag and returns its result in rax.
#include "rawsyscall.h"

int main() {
	char buf[16] = {0};
	struct kret r = ksyscall(SYS_open, (long)"test.txt", O_RDONLY, 0);
	long fd = r.rax;
	check("open(test.txt, O_RDONLY)", r, r.cf == 0 && fd > 2 && fd < 1000);
	r = ksyscall(SYS_read, fd, (long)buf, sizeof(buf));
	check("read(fd, buf, 16)", r, r.cf == 0 && r.rax == 16);
	r = ksyscall(SYS_lseek, fd, 0, SEEK_END);
	check("lseek(fd, 0, SEEK_END)", r, r.cf == 0 && r.rax == 46);
	r = ksyscall(SYS_close, fd, 0, 0);
	check("close(fd)", r, r.cf == 0 && r.rax == 0);
	return failures;
}
