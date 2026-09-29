// rdx holds a second result after some successful system calls, such as the
// write end from pipe(), so a non-zero rdx does not signal an error.
#include "rawsyscall.h"

int main() {
	struct kret r = ksyscall(SYS_pipe, 0, 0, 0);
	long rfd = r.rax, wfd = r.rdx;
	check("pipe()", r, r.cf == 0 && rfd > 2 && wfd > 2 && rfd != wfd);
	char buf[4] = {0};
	r = ksyscall(SYS_write, wfd, (long)"abc", 3);
	check("write(wfd, \"abc\", 3)", r, r.cf == 0 && r.rax == 3);
	r = ksyscall(SYS_read, rfd, (long)buf, 3);
	check("read(rfd, buf, 3)", r, r.cf == 0 && r.rax == 3 && buf[0] == 'a' && buf[2] == 'c');
	return failures;
}
