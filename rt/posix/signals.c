#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <sys/signal.h>
#include <sys/ucontext.h>

typedef _STRUCT_X86_THREAD_STATE32 *x86_regs;

void handler(int sig, siginfo_t *info, ucontext_t *uc) {
  void *eip = (void*) uc->uc_mcontext->__ss.__eip;
  printf("uc = %p, esp = %p\n", uc, eip);
  void *esp = (void*) uc->uc_mcontext->__ss.__esp;
  printf("uc = %p, esp = %p\n", uc, esp);

  printf("Offset of uc_mcontext = %ld\n", offsetof(ucontext_t, uc_mcontext));
  printf("Offset of __ss = %ld\n", offsetof(_STRUCT_MCONTEXT32, __ss));
  printf("Offset of __eip = %ld\n", offsetof(_STRUCT_X86_THREAD_STATE32, __eip));
  printf("Offset of __esp = %ld\n", offsetof(_STRUCT_X86_THREAD_STATE32, __esp));
  printf("(%d) caught, fault %p\n", sig, info->si_addr);
  fflush(stdout);
  exit(1);
}

int illegal = 0x0000FF0F;

int main() {

  int i;
  int *null = (int*)NULL;
  struct sigaction sa;
  void (*f)() = (void *)&illegal;

  printf("Installing handler...\n");

  sa.sa_handler = (void *)handler;
  sa.sa_mask = 0;
  sa.sa_flags = 0;

  sigaction(SIGSEGV, &sa, NULL);
  sigaction(SIGFPE, &sa, NULL);
  sigaction(SIGBUS, &sa, NULL);
  sigaction(SIGILL, &sa, NULL);

  printf("Offset of sa_handler = %d\n", ((char*)&sa.sa_handler - (char*)&sa));
  printf("Offset of sa_mask = %d\n", ((char*)&sa.sa_mask - (char*)&sa));
  printf("Offset of sa_flags = %d\n", ((char*)&sa.sa_flags - (char*)&sa));
  printf("Sizeof sigaction = %ld\n", sizeof(sa));

  printf("Triggering...");
  fflush(stdout);

  *null = 0;
  i = i / ((int)main ^ (int)main);
  f();

  return 1;
}

