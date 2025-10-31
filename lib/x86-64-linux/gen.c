#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

#include <sys/uio.h>

#include <poll.h>

#include <signal.h>

#include <time.h>
#include <sys/time.h>

#include <sys/socket.h>

#include <sys/signal.h>

#define _GNU_SOURCE          /* See feature_test_macros(7) */
#include <fcntl.h>           /* Definition of AT_* constants */
#include <sys/stat.h>
#include <linux/stat.h>

#include <linux/sched.h>

struct FooStruct {
  unsigned int my_field;
  unsigned short other_field;
};

#define BEGIN(struct_name, virgil_name) \
  { \
  struct_name __instance; \
  printf("layout %s {\n", #virgil_name); \
  
#define END_LAYOUT(struct_name) \
  printf("\t=%ld;\n", sizeof(__instance)); \
  printf("}\n"); \
  }

#define FIELD(field_name, virgil_type)	\
  { \
    ptrdiff_t __diff = ((char*)&__instance.field_name) - (char*)&(__instance); \
  printf("\t+%ld\t%s:\t%s;\n", (long)__diff, #field_name, #virgil_type); \
  }

#define FIELD2(field_name, virgil_name, virgil_type)	\
  { \
    ptrdiff_t __diff = ((char*)&__instance.field_name) - (char*)&(__instance); \
  printf("\t+%ld\t%s:\t%s;\n", (long)__diff, #virgil_name, #virgil_type); \
  }


int main() {
  BEGIN(struct FooStruct, FooLayout);
  FIELD2(my_field, field1, u32);
  FIELD2(other_field, field2, u16);
  END_LAYOUT(FooStruct);

  
  BEGIN(struct iovec, iovec);
  FIELD(iov_base, u64); // Pointer
  FIELD(iov_len, u64);  // size_t
  END_LAYOUT(iovec);

  BEGIN(struct pollfd, pollfd);
  FIELD(fd, u32);
  FIELD(events, u16);
  FIELD(revents, u16);
  END_LAYOUT(pollfd);

  BEGIN(struct sigaction, sigaction);
  FIELD(sa_handler, u64); // Pointer
  FIELD(sa_mask, byte[16]); // TODO
  FIELD(sa_flags, u32);
  FIELD(sa_restorer, u64); // Pointer
  END_LAYOUT(sigaction);

  BEGIN(struct timespec, timespec);
  FIELD(tv_sec, u64);
  FIELD(tv_nsec, u64);
  END_LAYOUT(timespec);

  BEGIN(struct timeval, timeval);
  FIELD(tv_sec, u64);
  FIELD(tv_usec, u64);
  END_LAYOUT(timeval);

  BEGIN(struct itimerval, itimerval);
  FIELD(it_interval, timeval);
  FIELD(it_value, timeval);
  END_LAYOUT(itimerval);

  BEGIN(struct msghdr, msghdr);
  FIELD(msg_name, u64); // Pointer
  FIELD(msg_namelen, u32);
  FIELD(msg_iov, u64); // Pointer<iovec>
  FIELD(msg_iovlen, u64); // size_t
  FIELD(msg_control, u64); // Pointer
  FIELD(msg_controllen, u64);
  FIELD(msg_flags, u32);
  END_LAYOUT(msghdr);

  BEGIN(siginfo_t, siginfo);
  FIELD(si_signo, u32);
  FIELD(si_errno, u32);
  FIELD(si_code, u32);
  FIELD(si_addr, u64);
  //  FIELD(si_pid, u32);
  //  FIELD(si_uid, u32);
  FIELD(si_value, u64); // Pointer
  FIELD(si_arch, u32);
  FIELD(si_utime, u32);
  FIELD(si_stime, u32);
  //  FIELD(si_mtime, u32);
  END_LAYOUT(siginfo_t);
  

    BEGIN(struct statx, statxf);
    FIELD(stx_mask, u32);
    FIELD(stx_blksize, u32);
    FIELD(stx_attributes, u64);
    FIELD(stx_nlink, u32);
    FIELD(stx_uid, u32);
    FIELD(stx_gid, u32);
    FIELD(stx_mode, u16);
    FIELD(stx_ino, u64);
    FIELD(stx_size, u64);
    FIELD(stx_blocks, u64);
    FIELD(stx_attributes_mask, u64);
    FIELD(stx_atime, u64);
    FIELD(stx_btime, u64);
    FIELD(stx_ctime, u64);
    FIELD(stx_mtime, u64);
    FIELD(stx_rdev_major, u32);
    FIELD(stx_rdev_minor, u32);
    FIELD(stx_dev_major, u32);
    FIELD(stx_dev_minor, u32);
    //    FIELD(stx_mnt_id, u64);
    //    FIELD(stx_dio_mem_align, u32);
    //FIELD(stx_dio_offset_align, u32);
  END_LAYOUT(statxf);

  BEGIN(struct clone_args, clone_args);
  FIELD(flags, u64); // Pointer
  FIELD(pidfd, u32);
  FIELD(child_tid, u64); // Pointer<iovec>
  FIELD(parent_tid, u64); // size_t
  FIELD(exit_signal, u64); // Pointer
  FIELD(stack, u64);
  FIELD(stack_size, u64);
  FIELD(tls, u64);
  END_LAYOUT(clone_args);

  return 0;
}
