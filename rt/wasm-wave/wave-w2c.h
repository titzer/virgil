// Copyright 2025 Virgil authors. All rights reserved.
// See LICENSE for details of Apache 2.0 license.

#include <unistd.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <limits.h>
#include <sys/stat.h>
#include <fcntl.h>

// Wave needs to access the instance memory to copy arguments and do IO.
struct w2c_wave {
  int argc;
  char **argv;
  wasm_rt_memory_t* memory;
};

void w2c_wave_init(struct w2c_wave* w, int argc, char** argv, wasm_rt_memory_t* m) {
  w->argc = argc;
  w->argv = argv;
  w->memory = m;
}

/* import: 'wave' 'arg_len' */
u32 w2c_wave_arg_len(struct w2c_wave* w, u32 arg) {
  if (arg >= w->argc) return 0;
  return strlen(w->argv[arg]);
}

/* import: 'wave' 'arg_copy' */
u32 w2c_wave_arg_copy(struct w2c_wave* w, u32 arg, u32 ptr, u32 len) {
  uint8_t* dest = w->memory->data + ptr;
  if (arg >= w->argc) return 0;
  char* str = w->argv[arg];
  u32 slen = 1 + strlen(str);
  if (len < slen) slen = len;
  memcpy(dest, str, slen);
  return 0;
}

/* import: 'wave' 'fs_size' */
u32 w2c_wave_fs_size(struct w2c_wave* w, u32 ptr, u32 len) {
  char path[PATH_MAX];
  struct stat st;

  if (len >= PATH_MAX) len = PATH_MAX - 1;
  memcpy(path, w->memory->data + ptr, len);
  path[len] = 0;
  if (stat(path, &st) != 0) return 0;
  return (u32)st.st_size;   // size in bytes
}

/* import: 'wave' 'fs_open' */
u32 w2c_wave_fs_open(struct w2c_wave* w, u32 ptr, u32 len, u32 mode) {
  char path[PATH_MAX];
  struct stat st;

  if (len >= PATH_MAX) len = PATH_MAX - 1;
  memcpy(path, w->memory->data + ptr, len);
  path[len] = 0;
  int flags = mode ? O_CREAT | O_WRONLY : O_RDONLY;
  return (u32)open(path, flags, 420);
}

/* import: 'wave' 'fs_chmod' */
u32 w2c_wave_fs_chmod(struct w2c_wave* w, u32 ptr, u32 len, u32 perm) {
  char path[PATH_MAX];
  struct stat st;

  if (len >= PATH_MAX) len = PATH_MAX - 1;
  memcpy(path, w->memory->data + ptr, len);
  path[len] = 0;
  return (u32)chmod(path, perm);
}

/* import: 'wave' 'fs_read' */
u32 w2c_wave_fs_read(struct w2c_wave* w, u32 fd, u32 ptr, u32 len) {
  uint8_t* base = w->memory->data + ptr;
  return read(fd, base, len);
}

/* import: 'wave' 'fs_avail' */
u32 w2c_wave_fs_avail(struct w2c_wave* w, u32 fd) {
  int n = 0;
  if (ioctl(fd, FIONREAD, &n) == -1) return 0;
  return (u32)n;
}
  
/* import: 'wave' 'fs_close' */
void w2c_wave_fs_close(struct w2c_wave* w, u32 fd) {
  close(fd);
}
  
/* import: 'wave' 'ticks_ms' */
u32 w2c_wave_ticks_ms(struct w2c_wave* w) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (u32)(ts.tv_sec * 1000u + ts.tv_nsec / 1000000u);
}

/* import: 'wave' 'ticks_us' */
u32 w2c_wave_ticks_us(struct w2c_wave* w) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (u32)(ts.tv_sec * 1000000u + ts.tv_nsec / 1000u);
}

/* import: 'wave' 'ticks_ns' */
u32 w2c_wave_ticks_ns(struct w2c_wave* w) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (u32)(ts.tv_sec * 1000000000u + ts.tv_nsec);
}

/* import: 'wave' 'fs_write' */
u32 w2c_wave_fs_write(struct w2c_wave* w, u32 fd, u32 ptr, u32 len) {
  uint8_t* base = w->memory->data + ptr;
  return write(fd, base, len);
}

/* import: 'wave' 'throw_ex' */
void w2c_wave_throw_ex(struct w2c_wave* w, u32 which, u32 which_len, u32 msg, u32 msg_len) {
  uint8_t* ws = w->memory->data + which;
  uint8_t* ms = w->memory->data + msg;

  fprintf(stderr, "%.*s: %.*s\n", which_len, ws, msg_len, ms);
  abort();
}

