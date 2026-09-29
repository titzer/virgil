// Raw x86-64 Darwin system calls that bypass libSystem, recording exactly what
// the kernel left in rax, rdx, and the carry flag (CF).
#include <stdio.h>

#define SYS_read	0x2000003
#define SYS_write	0x2000004
#define SYS_open	0x2000005
#define SYS_close	0x2000006
#define SYS_pipe	0x200002A
#define SYS_stat	0x20000BC
#define SYS_lseek	0x20000C7

#define O_RDONLY	0
#define O_WRONLY	1
#define SEEK_END	2

#define ENOENT		2
#define EBADF		9
#define EACCES		13

struct kret {
	long rax;
	long rdx;
	long cf;
};

// Issue system call {num} with up to 3 arguments. The carry flag is set to
// {cf_in} immediately before the syscall instruction and sampled right after.
static struct kret ksyscall_cf(long cf_in, long num, long a, long b, long c) {
	struct kret r;
	long rax = num, rdi = a, rsi = b, rdx = c, rbx = cf_in;
	__asm__ volatile (
		"bt $0, %%rbx\n\t"	// CF = cf_in
		"syscall\n\t"
		"setc %%bl\n\t"		// CF as the kernel left it
		"movzbq %%bl, %%rbx"
		: "+a"(rax), "+D"(rdi), "+S"(rsi), "+d"(rdx), "+b"(rbx)
		:
		: "rcx", "r8", "r9", "r10", "r11", "cc", "memory");
	r.rax = rax;
	r.rdx = rdx;
	r.cf = rbx;
	return r;
}

static inline struct kret ksyscall(long num, long a, long b, long c) {
	return ksyscall_cf(0, num, a, b, c);
}

static int failures = 0;

// Print what the kernel returned and record a failure if {ok} is false.
static void check(const char *what, struct kret r, int ok) {
	printf("%-36s rax=%ld rdx=%ld CF=%ld%s\n", what, r.rax, r.rdx, r.cf, ok ? "" : "  <== unexpected");
	if (!ok) failures++;
}
