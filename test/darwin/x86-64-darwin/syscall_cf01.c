// System calls on a bad file descriptor set the carry flag and return EBADF.
#include "rawsyscall.h"

int main() {
	char buf[16] = {0};
	struct kret r = ksyscall(SYS_read, 99, (long)buf, sizeof(buf));
	check("read(99, buf, 16)", r, r.cf == 1 && r.rax == EBADF);
	r = ksyscall(SYS_write, 99, (long)buf, sizeof(buf));
	check("write(99, buf, 16)", r, r.cf == 1 && r.rax == EBADF);
	r = ksyscall(SYS_lseek, 99, 0, SEEK_END);
	check("lseek(99, 0, SEEK_END)", r, r.cf == 1 && r.rax == EBADF);
	r = ksyscall(SYS_close, 99, 0, 0);
	check("close(99)", r, r.cf == 1 && r.rax == EBADF);
	return failures;
}
