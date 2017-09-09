// A utility similar to "time" that reports elapsed time for a given subcommand.
// Reports in microseconds, as opposed to milliseconds (or hundredths of a second).
// Does not do path resolution, however.

#include <sys/resource.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>

#define MAX_RUNS 1000

char **global_envp;
double times[MAX_RUNS];

// print timeval and rusage
void print_time(struct timeval *elapsed, struct rusage *usage) {
  if (elapsed == NULL) {
    // print the rows
    printf(" %12s", "elapsed");
    printf(" %12s", "user");
    printf(" %12s", "sys");
  } else {
    printf(" %5ld.%06d", elapsed->tv_sec, (int)elapsed->tv_usec);
    printf(" %5ld.%06d", usage->ru_utime.tv_sec, (int)usage->ru_utime.tv_usec);
    printf(" %5ld.%06d", usage->ru_stime.tv_sec, (int)usage->ru_stime.tv_usec);
  }
  printf("\n");
}

// run the program, redirecting its output to the given tmp files
int run(int run, int numruns, int nstdout, int nstderr, char *argv[]) {
  struct rusage usage;
  struct timeval start;
  struct timeval end;
  struct timeval elapsed;
  int pid, status = 0, i = 0, rc = 0;
  char tmpfname[1024];

  // get start time
  gettimeofday(&start, NULL);

  // fork
  pid = vfork();

  if (pid == 0) {
    // in child, redirect output
    dup2(nstdout, 1);
    dup2(nstderr, 2);
    // execve the command
    status = execve(argv[0], argv, global_envp);
    // should not reach here unless exec failed
    printf("exec failed with status = %d, errno = %d\n", status, errno);
    exit(status);
  }

  // in parent, wait for child
  rc = wait4(pid, &status, 0, &usage);
  if (rc < 0 || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    // program returned nonzero exit code, or terminated with signal
    if (numruns > 1) {
	printf(" %12s", "--");
    } else if (rc == pid) {
      if (WIFEXITED(status)) {
        printf("process exited with rc = %d\n", WEXITSTATUS(status));
      } else {
	printf("process failed with status = %d\n", WEXITSTATUS(status));
      }
    } else {
	printf("wait4 failed with rc = %d, exited = %d, exit = %d\n", rc, WIFEXITED(status), WEXITSTATUS(status));
    }
    fflush(stdout);
    return 1;
  }

  // get elapsed time
  gettimeofday(&end, NULL);
  timersub(&end, &start, &elapsed);

  times[run] = ((double) elapsed.tv_sec) + ((double) elapsed.tv_usec) / 1000000.0;

  if (numruns > 1) {
    // print each time on the same row
    printf(" %5ld.%06d", elapsed.tv_sec, (int)elapsed.tv_usec);
    fflush(stdout);
  } else {
    // print one row with multiple times
    print_time(NULL, NULL);
    print_time(&elapsed, &usage);
  }
  return 0;
}

void print_stats(int runs) {
  double total = 0;
  double min = 1.0 / 0.0;
  int i = 0;
  for (i = 0; i < runs; i++) {
    total += times[i];
  }
  double average = total / runs, dev = 0;
  for (i = 0; i < runs; i++) {
    dev += (times[i] - average) * (times[i] - average);
    if (times[i] < min) min = times[i];
  }
  double stddev = sqrt(dev / (runs - 1));
  printf("  min=%.6lf  avg=%.6lf  stddev=%.6lf", min, average, stddev);
}

int do_fail_run(char* argv[]) {
  printf("\n=={ FAILED }=============================================\n");
  run(0, 1, STDOUT_FILENO, STDERR_FILENO, argv);
  printf(  "=========================================================\n");
  return 1;
}

int main(int argc, char *argv[], char *envp[]) {
  int i;
  char *tmp = "/dev/null";
  global_envp = envp;
  if (argc < 2) {
    printf("usage: btime [runs] <command>\n");
    exit(1);
  }
  // open /dev/null as the default output.
  int devnull = open("/dev/null", O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (devnull <= 0) {
    printf("could not open /dev/null\n");
    return 1;
  }

  if (argc > 2) {
    // Check to see if the number of runs was specified.
    char *num = argv[1];
    if (num[0] >= '0' && num[0] <= '9') {
      int runs = atoi(num);
      if (runs > MAX_RUNS) runs = MAX_RUNS;
      if (runs > 1) {
	int i = 0, failed = 0;
        for(i = 0; i < runs; i++) {
  	  if (run(i, runs, devnull, devnull, &argv[2]) != 0) {
		return do_fail_run(&argv[2]);
	  }
        }
        print_stats(runs);
        printf("\n");
        return 0;
      }
    }
  }
  // Just do a single run.
  if (run(0, 1, devnull, devnull, &argv[1]) != 0) {
    return do_fail_run(&argv[1]);
  }
  return 0;
}

