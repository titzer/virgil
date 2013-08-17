// The process that runs a single test case.

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <sys/wait.h>
#include <signal.h>
#include <stdarg.h>

#define STDOUT_BUF_SIZE 100
#define STDERR_BUF_SIZE 1024
#define SPEC_BUF_SIZE 16384

#define NORM "[0;00m"
#define GREEN "[0;32m"
#define RED "[0;31m"
#define CLEAR_LINE "\r[K"

#define TIMEOUT 5

int VERBOSE = 2;
int INTERACTIVE = 1;

typedef struct run {
  int num;
  int result;
  char *exception;
  char *failure;
  struct run *next;
} v3_run;

typedef struct run_output {
  int status;			// status from waitpid()
  int pipe_stdout[2];		// pipe for stdout
  int pipe_stderr[2];		// pipe for stderr
  char data_stdout[STDOUT_BUF_SIZE];	// first 100 bytes of stdout
  int len_stdout;		// num bytes read from stdout
  char data_stderr[STDERR_BUF_SIZE];	// first 500 bytes of stderr
  int len_stderr;		// num bytes read from stderr
} run_output;

typedef struct {
  char *testFile;
  char *exeDir;
  char *end;
  char *failure;
  v3_run *runs;
} v3_test;

volatile int tests_running;
volatile int test_timeout;
volatile int test_pid;

int tests_total;
int tests_done;
int tests_passed;
int tests_failed;

v3_run *failList;
char spec[SPEC_BUF_SIZE]; // global specification buffer

int parse(v3_test *test, int size);
void *trimFirstLine(char *p, int size);
int execute_test(v3_test *test);
void begin_test(v3_test *test);
void end_test(v3_test *test, int result);

void timeout_thread(void *ptr);

int main(int argc, char **argv) {
  int i;
  pthread_t thread;
  if (argc < 3) {
    printf("Usage: <exe_dir> <test1> ...\n");
    return 1;
  }
  tests_total = argc - 2;
  tests_running = 1;
  pthread_create(&thread, NULL, &timeout_thread, NULL);
  for (i = 2; i < argc; i++) {
    int result;
    v3_test test;
    memset(&test, 0, sizeof(test));
    test.testFile = argv[i];
    test.exeDir = argv[1];
    begin_test(&test);
    result = run_test(&test);
    end_test(&test, result);
  }
  tests_running = 0;
  if (INTERACTIVE) printf(CLEAR_LINE);
  if (tests_done == tests_total && tests_failed == 0) {
    printf("%d of %d " GREEN "ok" NORM "\n", tests_done, tests_total);
  } else {
    char *red = "";
    if (tests_failed > 0) red = RED;
    printf("%d of %d ", tests_done, tests_total);
    printf("[" GREEN "%d" NORM "/%s%d" NORM "]", tests_passed, red, tests_failed);
    printf(" completed (%.2f%% passed)\n", 100 * ((float)tests_passed / (float)tests_total));
  }
  if (tests_failed > 0) return 1;
  return 0;
}

void begin_test(v3_test *test) {
    if (VERBOSE > 1) {
      if (INTERACTIVE) {
        char *red = "";
        if (tests_failed > 0) red = RED;
	printf(CLEAR_LINE);
        int testnum = 1 + tests_passed + tests_failed;
	printf("%d of %d ", testnum, tests_total);
        printf("[" GREEN "%d" NORM "/%s%d" NORM "]", tests_passed, red, tests_failed);
	printf(": %s...", test->testFile);
      } else {
	printf("%s...", test->testFile);
      }
      fflush(stdout);
    }
}

void end_test(v3_test *test, int result) {
  tests_done++;
  if (result) tests_passed++;
  else tests_failed++;
    if (VERBOSE == 1) {
      if (result) printf(GREEN "o" NORM);
      else printf(RED "X" NORM);
      if ((tests_done % 10) == 0 || tests_done == tests_total) putc(' ', stdout);
      if ((tests_done % 50) == 0 || tests_done == tests_total) {
	printf("%d of %d\n", tests_done, tests_total);
      }
      fflush(stdout);
    } else if (VERBOSE > 1) {
      if (INTERACTIVE) {
        if (!result) {
 	  printf(CLEAR_LINE);
 	  printf(RED "%s" NORM ": %s\n", test->testFile, test->failure);
	}
      } else {
        if (result) printf(GREEN "ok" NORM);
        else printf(RED "failed" NORM);
      }
      fflush(stdout);
    }
}

int run_test(v3_test *test) {
  int fd, size;

  fd = open(test->testFile, O_RDONLY);
  if (fd < 0) {
    test->failure = "cannot open";
    return 0;
  }
  size = read(fd, spec, SPEC_BUF_SIZE);
  if (size <= 0) {
    test->failure = "cannot read";
    return 0;
  }
  spec[size] = 0;
  close(fd);
  return parse(test, size) && execute_test(test);
}

void *trimFirstLine(char *p, int size) {
  char *end = p + size;
  char *q = p;
  while (q < end) {
    if (*q == '\n') {
      *q = 0;
      return q;
    }
    q++;
  }
  return end;
}

void *addResult(v3_test *test, char *p, int result, char *except) {
  //  printf("run %d %s\n", result, except == NULL ? "null" : except);
  v3_run *run = (v3_run *) malloc(sizeof(v3_run));
  run->result = result;
  run->exception = except;
  run->failure = NULL;
  run->next = test->runs;
  test->runs = run;
  return p;
}

void parseError(v3_test *test, char *p) {
  printf("invalid input spec @ %d\n", (int)(p - spec));
  exit(5);
}

char *strextract(char *p, char *c) {
  int size = strspn(p, c);
  char *q = p + size;
  char *x = (char *) malloc(size);
  strncpy(x, p, size);
  x[size] = 0;
  return x;
}

int hex(v3_test *test, char *p, char a) {
  if ('0' <= a && a <= '9') return a - '0';
  if ('a' <= a && a <= 'f') return 10 + a - 'a';
  if ('A' <= a && a <= 'F') return 10 + a - 'A';
  parseError(test, p);
  return -1;
}

void *parseResult(v3_test *test, char *p, char *end) {
  char *q, *endptr;
  while (p < end && (*p == ' ' || *p == '\t')) p++; // skip whitespace
  switch (*p) {
  case 't':
    if (strncmp(p, "true", 4) == 0) return addResult(test, p, 1, NULL);
    else parseError(test, p);
  case 'f':
    if (strncmp(p, "false", 5) == 0) return addResult(test, p, 0, NULL);
    else parseError(test, p);
  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
  case '-':
    return addResult(test, p, strtol(p, &endptr, 10), NULL);
  case '!':
    return addResult(test, p, 0, strextract(p, "!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"));
  case '\'': {
    char c = *(++p);
    if (c != '\\') return addResult(test, p, c, NULL);
    switch (*(++p)) {
    case 'n': return addResult(test, p, '\n', NULL);
    case 'r': return addResult(test, p, '\r', NULL);
    case 't': return addResult(test, p, '\t', NULL);
    case '\'': return addResult(test, p, '\'', NULL);
    case '\"': return addResult(test, p, '\"', NULL);
    case '\\': return addResult(test, p, '\\', NULL);
    case 'x': {
      char a = *(++p);
      char b = *(++p);
      return addResult(test, p, hex(test, p, a) << 4 | hex(test, p, b), NULL);
    }
    default: parseError(test, p);
    }
  }
    
  default:
    parseError(test, p);
  }
  return p;
}

int parse(v3_test *test, int size) {
  char *start = spec;
  if (strncmp(start, "//@execute ", 11) == 0) {
    // parse a normal execution test
    char *end = trimFirstLine(spec, size);
    char *p = end;
    while (p > start) {
      if (*p == '=') {
        parseResult(test, p + 1, end);
      }
      p--;
    }
    return 1;
  } else if (strncmp(start, "//@stacktrace", 13) == 0) {
    // parse a stacktrace test
    char *end = start + size;
    char *p = end, *prev = end;
    while (p >= start) {
      if (*p == '/' && (strncmp(p, "//@stacktrace", 13) == 0)) {
	char *q = p + 13;
	if (*q == '=') { // normal result
	  parseResult(test, q + 1, prev);
          prev = p;
	} else if (*q == '\n') { // stacktrace follows
	  int size = prev - q - 1;
          char *stacktrace = malloc(size + 1);
	  strncpy(stacktrace, q + 1, size);
	  stacktrace[size] = 0;
	  addResult(test, q + 1, 0, stacktrace);
          prev = p;
        } else {
          test->failure = "invalid test case spec";
          return 0;
        }
      }
      p--;
    }
    return 1;
  } else {
    test->failure = "invalid test case spec";
    return 0;
  }
}

int error(v3_run *run, char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  run->failure = (char *) malloc(1024);
  vsnprintf(run->failure, 1024, fmt, ap);
  if (VERBOSE > 1) {
    printf("(%s) ", run->failure);
  }
  if (failList != run) {
    // collect a list of all failures
    run->next = failList;
    failList = run;
  }
  return 0;
}

// in child process, exec() the test binary with the appropriate number of arguments
int exec_run(v3_run *run, char *binFile) {
  int i, num = run->num;
  char **argv = (char **) malloc((2 + num) * sizeof(char *));
  char *narg = "a";
  argv[0] = binFile;
  for (i = 1; i < num + 1; i++) {
    argv[i] = narg;
  }
  argv[num + 1] = NULL;
  execve(binFile, argv, NULL);
}

int check_result(v3_run *run, run_output *result) {
  int status = result->status;
  int retval = *((int*)result->data_stdout);
  int outlen = result->len_stdout;
  int errlen = result->len_stderr;

  if (WIFSIGNALED(status)) {
    // process terminated due to signal.
    return error(run, "run %d: unexpected signal %d", run->num, WTERMSIG(status));
  } else if (WIFEXITED(status)) {
    // process exited normally
    if (run->exception != NULL) {
      // expected exception
      if (outlen == 0 
	  && errlen >= strlen(run->exception)
	  && strncmp(run->exception, result->data_stderr, strlen(run->exception)) == 0) return 1;
      if (outlen == 4 && errlen == 0) return error(run, "run %d: expected %s, got %d", run->num, run->exception, retval);
      if (outlen == 0) return error(run, "run %d: expected \"%s\" = %ld, got \"%s\"", run->num, run->exception, strlen(run->exception), result->data_stderr);
      return error(run, "run %d: expected \"%s\", got %d (%d bytes), \"%s\"", run->num, run->exception, retval, outlen, result->data_stderr);
    } else {
      // expected successful return
      if (outlen == 4 
          && errlen == 0
	  && retval == run->result) return 1;
      if (outlen == 4 && errlen == 0) return error(run, "run %d: expected %d, got %d", run->num, run->result, retval);
      if (outlen == 0) return error(run, "run %d: expected %d, got \"%s\"", run->num, run->result, result->data_stderr);
      return error(run, "run %d: expected %d, got %d (%d bytes), \"%s\"", run->num, run->result, retval, outlen, result->data_stderr);
    }
  } else if (WIFSTOPPED(status)) {
    // TODO: process is stopped, and can be restarted
  }
  return 1;
}

// execute each of the runs of the test, checking each one against the expected results.
int execute_test(v3_test *test) {
  v3_run *run;
  int num = 0;
  char binFile[256];

  char *p = binFile + snprintf(binFile, 256, "%s/%s", test->exeDir, basename(test->testFile));
  while (p-- > binFile) {
    if (*p == '.') { // trim extension from name of file
      *p = 0;
      break;
    }
    if (*p == '/') break;
  }

  if (chmod(binFile, 0744) != 0) {
    test->failure = "not executable";
    return 0;
  }

  for (run = test->runs; run != NULL; run = run->next) {
    run_output result;
    memset(&result, 0, sizeof(result));
    run->num = num++;

    if (VERBOSE > 2) {
      printf("\n  run %d...", run->num);
    }
    if (pipe(result.pipe_stdout) != 0) return error(run, "couldn't pipe stdout");
    if (pipe(result.pipe_stderr) != 0) return error(run, "couldn't pipe stderr");
    
    int pid = vfork();
    if (pid == 0) {
      // child process; redirect output to pipes
      dup2(result.pipe_stdout[1], fileno(stdout)); // redirect stdout
      dup2(result.pipe_stderr[1], fileno(stderr)); // redirect stderr
      // close read end of pipe in child
      close(result.pipe_stdout[0]);
      close(result.pipe_stderr[0]);
      // exec test binary
      exec_run(run, binFile);
    } else {
      // in parent process
      // close write end of pipe in parent
      close(result.pipe_stdout[1]);
      close(result.pipe_stderr[1]);

      // wait for signal / exit
      test_timeout = TIMEOUT;
      test_pid = pid;
      waitpid(pid, &result.status, 0);

      // read stdout into buffer
      result.len_stdout = read(result.pipe_stdout[0], result.data_stdout, STDOUT_BUF_SIZE);
      // read stderr into buffer
      result.len_stderr = read(result.pipe_stderr[0], result.data_stderr, STDERR_BUF_SIZE);

      // close all pipe files
      close(result.pipe_stdout[0]);
      close(result.pipe_stderr[0]);

      // check the result
      if (!check_result(run, &result)) {
        test->failure = run->failure;
	return 0;
      }

    }
  }
  return 1;
}

void timeout_thread(void *ptr) {
  while (tests_running) {
    if (test_timeout-- < 0) {
      test_timeout = 0;
      kill(test_pid, 9);
    }
    sleep(1);
  }
}
