#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <signal.h>
#include <ucontext.h>

ucontext_t ucontext;
mcontext_t mcontext;

#define PRINT_OFFSET(thing, name) printf(#name " = %d\n", (int)(((char*)&(thing.name)) - (char*)&thing));

enum
{
  REG_R8 = 0,
# define REG_R8		REG_R8
  REG_R9,
# define REG_R9		REG_R9
  REG_R10,
# define REG_R10	REG_R10
  REG_R11,
# define REG_R11	REG_R11
  REG_R12,
# define REG_R12	REG_R12
  REG_R13,
# define REG_R13	REG_R13
  REG_R14,
# define REG_R14	REG_R14
  REG_R15,
# define REG_R15	REG_R15
  REG_RDI,
# define REG_RDI	REG_RDI
  REG_RSI,
# define REG_RSI	REG_RSI
  REG_RBP,
# define REG_RBP	REG_RBP
  REG_RBX,
# define REG_RBX	REG_RBX
  REG_RDX,
# define REG_RDX	REG_RDX
  REG_RAX,
# define REG_RAX	REG_RAX
  REG_RCX,
# define REG_RCX	REG_RCX
  REG_RSP,
# define REG_RSP	REG_RSP
  REG_RIP,
# define REG_RIP	REG_RIP
  REG_EFL,
# define REG_EFL	REG_EFL
  REG_CSGSFS,		/* Actually short cs, gs, fs, __pad0.  */
# define REG_CSGSFS	REG_CSGSFS
  REG_ERR,
# define REG_ERR	REG_ERR
  REG_TRAPNO,
# define REG_TRAPNO	REG_TRAPNO
  REG_OLDMASK,
# define REG_OLDMASK	REG_OLDMASK
  REG_CR2
# define REG_CR2	REG_CR2
};


int main(int argc, char** argv) {
  printf("sizeof(ucontext_t) = %d\n", (int)sizeof(ucontext)); 
  printf("sizeof(mcontext_t) = %d\n", (int)sizeof(mcontext)); 

  PRINT_OFFSET(ucontext, uc_mcontext);

  {
    char* base = (char*)&ucontext;
    printf("  .rip = %d\n", (int)((char*)(&ucontext.uc_mcontext.gregs[REG_RIP]) - base));
    printf("  .rsp = %d\n", (int)((char*)(&ucontext.uc_mcontext.gregs[REG_RSP]) - base));
    printf("  .rbp = %d\n", (int)((char*)(&ucontext.uc_mcontext.gregs[REG_RBP]) - base));
  }
  
  return 0;
}
