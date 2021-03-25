#define __USE_GNU

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <signal.h>
#include <sys/uio.h>
#include <poll.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/syscall.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <dirent.h>
#include <time.h>
#include <ustat.h>
#include <sys/socket.h>
#include <sys/msg.h>
#include <utime.h>
#include <sys/vfs.h>
#include <linux/sched.h>
#include <sched.h>
#include <sys/resource.h>
#include <linux/aio_abi.h>
#include <sys/epoll.h>
#include <linux/kexec.h>
#include <linux/futex.h>
#include <fcntl.h>

int print_decl(char *struct_name) {
  printf("layout struct %s for \"x86-64-linux\" {\n", struct_name);
}

int finish_decl(char *struct_name, size_t size) {
  if (size % sizeof(void*) == 0) {
    printf("\t=%zuW\n", size / sizeof(void*));
  } else {
    printf("\t=%zuB\n", size);
  }
  printf("}\n");
}

int print_offset(char *field_name, ptrdiff_t offset) {
  if (offset % sizeof(void*) == 0) {
    printf("\t+%zuW", offset / sizeof(void*));
  } else {
    printf("\t+%zuB", offset);
  }
  printf("\t%s;\n", field_name);
}

#define STRUCT_DECL(x) struct x thing; print_decl(#x)
#define DECL(x) x thing; print_decl(#x)
#define __(x) print_offset(#x, (char*)(&thing.x) - (char*)(&thing));
#define FINISH(x) finish_decl(#x, sizeof(thing))

struct file_handle
{
  unsigned int handle_bytes;
  int handle_type;
  /* File identifier.  */
  unsigned char f_handle[0];
};

struct sched_attr {
	__u32 size;

	__u32 sched_policy;
	__u64 sched_flags;

	/* SCHED_NORMAL, SCHED_BATCH */
	__s32 sched_nice;

	/* SCHED_FIFO, SCHED_RR */
	__u32 sched_priority;

	/* SCHED_DEADLINE */
	__u64 sched_runtime;
	__u64 sched_deadline;
	__u64 sched_period;
};


struct mmsghdr
  {
    struct msghdr msg_hdr;	/* Actual message header.  */
    unsigned int msg_len;	/* Number of received or sent bytes for the
				   entry.  */
  };

int main(int argc, char **argv) {
  {
    STRUCT_DECL(sigaction);
    __(sa_handler);
    __(sa_mask);
    __(sa_flags);
    __(sa_restorer);
    FINISH(sigaction);
  }
  {
    STRUCT_DECL(iovec);
    __(iov_base);
    __(iov_len);
    FINISH(iovec);
  }
  {
    STRUCT_DECL(pollfd);
    __(fd);
    __(events);
    __(revents);
    FINISH(pollfd);
  }
  {
    STRUCT_DECL(shmid_ds);
    __(shm_perm);
    __(shm_segsz);
    __(shm_atime);
    __(shm_dtime);
    __(shm_ctime);
    __(shm_cpid);
    __(shm_lpid);
    __(shm_nattch);
    FINISH(shmid_ds);
  }
  {
    STRUCT_DECL(timespec);
    __(tv_sec);
    __(tv_nsec);
    FINISH(timespec);
  }
  {
    STRUCT_DECL(timeval);
    __(tv_sec);
    __(tv_usec);
    FINISH(timeval);
  }
  {
    STRUCT_DECL(dirent);
    __(d_ino);
    __(d_off);
    __(d_reclen);
    __(d_name);
    __(d_type);
    FINISH(linux_dirent);
  }
  {
    STRUCT_DECL(ustat);
    __(f_tfree);
    __(f_tinode);
    __(f_fname);
    __(f_fpack);
    FINISH(ustat);
  }
  {
    STRUCT_DECL(itimerval);
    __(it_interval);
    __(it_value);
    FINISH(itimerval);
  }
  {
    STRUCT_DECL(sockaddr);
    FINISH(sockaddr);
  }
  {
    STRUCT_DECL(msghdr);
    __(msg_name);
    __(msg_namelen);
    __(msg_iov);
    __(msg_iovlen);
    __(msg_control);
    __(msg_controllen);
    __(msg_flags);
    FINISH(msghdr);
  }
  {
    STRUCT_DECL(sembuf);
    __(sem_num);
    __(sem_op);
    __(sem_flg);
    FINISH(sembuf);
  }
  {
    STRUCT_DECL(timezone);
    __(tz_minuteswest);
    __(tz_dsttime);
    FINISH(timezone);
  }
  {
    DECL(siginfo_t);
    __(si_signo);
    __(si_errno);
    __(si_code);
    __(si_pid);
    __(si_timerid);
    __(si_addr);
    __(si_band);
    __(si_call_addr);
    __(si_status);
    __(si_value);
    __(si_int);
    __(si_fd);
    __(si_addr_lsb);
    __(si_ptr);
    __(si_syscall);
    __(si_utime);
    __(si_lower);
    __(si_pkey);
    __(si_stime);
    __(si_upper);
    __(si_uid);
    __(si_overrun);
    __(si_arch);
    FINISH(siginfo_t);
  }
  {
    STRUCT_DECL(utimbuf);
    __(actime);
    __(modtime);
    FINISH(utimbuf);
  }
  {
    STRUCT_DECL(statfs);
    __(f_type);
    __(f_bsize);
    __(f_blocks);
    __(f_bfree);
    __(f_bavail);
    __(f_files);
    __(f_ffree);
    __(f_fsid);
    __(f_namelen);
    __(f_frsize);
    __(f_flags);
    FINISH(statfs);
  }
  {
    STRUCT_DECL(sched_param);
    __(sched_priority);
    FINISH(sched_param);
  }

   {
     STRUCT_DECL(rlimit);
     __(rlim_cur);
     __(rlim_max);
     FINISH(rlimit);
   }
  /* { // TODO
     STRUCT_DECL(pt_regs);
     FINISH(pt_regs);
     }*/
   {
     STRUCT_DECL(iocb);
     __(aio_data);
     __(aio_key);
     __(aio_rw_flags);
     __(aio_lio_opcode);
     __(aio_reqprio);
     __(aio_fildes);
     __(aio_buf);
     __(aio_nbytes);
     __(aio_offset);
     __(aio_flags);
     __(aio_resfd);
     FINISH(iocb);
   }
   {
     STRUCT_DECL(sigevent);
     __(sigev_value);
     __(sigev_signo);
     __(sigev_notify);
     __(sigev_notify_function);
     __(sigev_notify_attributes);
     //     __(sigev_notify_thread_id);
     FINISH(sigevent);
   }
   {
     STRUCT_DECL(itimerspec);
     __(it_interval);
     __(it_value);
     FINISH(itimerspec);
   }
   {
     STRUCT_DECL(epoll_event);
     __(events);
     __(data.ptr);
     FINISH(epoll_event);
   }
   {
     STRUCT_DECL(kexec_segment);
     __(buf);
     __(bufsz);
     __(mem);
     __(memsz);
     FINISH(kexec_segment);
   }
   {
     STRUCT_DECL(rusage);
     __(ru_utime);
     __(ru_stime);
     __(ru_maxrss);
     __(ru_ixrss);
     __(ru_idrss);
     __(ru_isrss);
     __(ru_minflt);
     __(ru_majflt);
     __(ru_nswap);
     __(ru_inblock);
     __(ru_oublock);
     __(ru_msgsnd);
     __(ru_msgrcv);
     __(ru_nsignals);
     __(ru_nvcsw);
     __(ru_nivcsw);
     FINISH(rusage);
     }
  {
     STRUCT_DECL(robust_list_head);
     __(list);
     __(futex_offset);
     __(list_op_pending);
     FINISH(robust_list_head);
     }
   {
     STRUCT_DECL(file_handle);
     __(handle_bytes);
     __(handle_type);
     __(f_handle);
     FINISH(file_handle);
   }
   {
     STRUCT_DECL(sched_attr);
     __(size);
     __(sched_policy);
     __(sched_flags);
     __(sched_nice);
     __(sched_priority);
     __(sched_runtime);
     __(sched_deadline);
     __(sched_period);
     FINISH(sched_attr);
   }
    { 
     STRUCT_DECL(mmsghdr); // TODO
     __(msg_hdr);
     __(msg_len);
     FINISH(mmsghdr);
    } 
  return 0;
  }
