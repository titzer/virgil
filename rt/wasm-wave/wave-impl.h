#pragma once

#define WAVE_FUNC(name) auto wave_##name(const wasm::Val args[], wasm::Val results[]) -> wasm::own<wasm::Trap*>
#define ERROR(...) printf("ERROR: " __VA_ARGS__)

#define FD_MAX 1024
#define FD_MASK ((FD_MAX)-1)

/* Design questions
  1. where does the state for virtualizing the file descriptors live?
  2. how to get the global exported memory
  3. how to do traps
 */

// State for virtualizing file descriptors.
struct instance_fds {
  int fd_map[FD_MAX];
  int last_fd = 2;

  void clear() {
    fd_map[0] = 0;
    fd_map[1] = 1;
    fd_map[2] = 2;
    for (int i = 2; i < FD_MAX; i++) fd_map[i] = -1;
  }

  void close() {
    for (int i = 2; i < FD_MAX; i++) {
      if (fd_map[i] >= 0) ::close(fd_map[i]);
    }
  }

  int alloc_fd(int sys_fd) {
    int start = last_fd, i = start;
    while (true) {
      if (fd_map[i] < 0) {
        fd_map[i] = sys_fd;
        return i;
      }
      int j = (i + 1) & FD_MASK;
      if (j == start) break;
      i = j;
    }
    return -1;
  }

  void free_fd(int fd) {
    fd_map[fd] = -1;
  }

  int get_sys_fd(int fd) {
    if (fd < 0 || fd >= FD_MAX) return -1;
    return fd_map[fd];
  }
};

//============================================================================
// Wave functions that can be imported into a module.
//============================================================================
WAVE_FUNC(arg_len) {
  ARG(0, arg, i32);
  TRACE("arg_len(%d)\n", arg);
  if (arg >= global_argc) { RETURN_MINUS_1; }
  int len = static_cast<int>(strlen(global_argv[arg]));
  results[0] = wasm::Val::i32(len);
  return nullptr;
}

WAVE_FUNC(arg_copy) {
  ARG(0, arg, i32);
  ARG(1, dest, i32);
  ARG(2, dest_len, i32);
  TRACE("arg_copy(%d, buf=0x%08x, len=%d)\n", arg, dest, dest_len);
  if (arg >= global_argc) { RETURN_MINUS_1; }
  char* buffer = reinterpret_cast<char*>(checkbuffer(dest, dest_len));
  if (!buffer) { RETURN_MINUS_1; }
  char* result = stpncpy(buffer, global_argv[arg], dest_len);
  results[0] = wasm::Val::i32(static_cast<int>(result - buffer));
  return nullptr;
}

WAVE_FUNC(fs_size) {
  ARG(0, path, i32);
  ARG(1, path_len, i32);
  char* path_str = copypath(path, path_len);
  if (!path_str) { RETURN_MINUS_1; }
  TRACE("fs_size(path=\"%*s\")\n", path_len, path_str);

  struct stat s;
  auto result = stat(path_str, &s);
  if (result != 0) { RETURN_MINUS_1; }
  results[0] = wasm::Val::i32(s.st_size);
  return nullptr;
}

WAVE_FUNC(fs_chmod) {
  ARG(0, path, i32);
  ARG(1, path_len, i32);
  ARG(2, mode, i32);
  char* path_str = copypath(path, path_len);
  if (!path_str) { RETURN_MINUS_1; }
  TRACE("fs_chmod(path=\"%*s\", mode=0x%08x)\n", path_len, path_str, mode);
  ::chmod(path_str, mode);  // TODO: audit mode bits
  results[0] = wasm::Val::i32(0);
  return nullptr;
}

WAVE_FUNC(fs_open) {
  instance_fds* fds = &global_fds;
  ARG(0, path, i32);
  ARG(1, path_len, i32);
  ARG(2, mode, i32);

  char* path_str = copypath(path, path_len);
  TRACE("fs_open(path=\"%*s\", mode=0x%08x)\n", path_len, path_str, mode);
  if (!path_str) { RETURN_MINUS_1; }
  int flags = mode ? O_CREAT | O_WRONLY : O_RDONLY;
  int sys_fd = ::open(path_str, flags, 420);
  if (sys_fd < 0) { RETURN_MINUS_1; }
  int fd = fds->alloc_fd(sys_fd);
  results[0] = wasm::Val::i32(fd);
  return nullptr;
}

WAVE_FUNC(fs_read) {
  instance_fds* fds = &global_fds;
  ARG(0, fd, i32);
  ARG(1, buf, i32);
  ARG(2, buf_len, i32);

  TRACE("fs_read(fd=%d, buf=0x%08x, len=%d)\n", fd, buf, buf_len);

  int sys_fd = fds->get_sys_fd(fd);
  void* buffer = checkbuffer(buf, buf_len);
  if (sys_fd < 0 || !buffer) { RETURN_MINUS_1; }
  int32_t result = ::read(sys_fd, buffer, buf_len);
  results[0] = wasm::Val::i32(result);
  return nullptr;
}

WAVE_FUNC(fs_write) {
  instance_fds* fds = &global_fds;
  ARG(0, fd, i32);
  ARG(1, buf, i32);
  ARG(2, buf_len, i32);

  TRACE("fs_write(fd=%d, buf=0x%08x, len=%d)\n", fd, buf, buf_len);

  int sys_fd = fds->get_sys_fd(fd);
  void* buffer = checkbuffer(buf, buf_len);
  if (sys_fd < 0 || !buffer) { RETURN_MINUS_1; }
  int32_t result = ::write(sys_fd, buffer, buf_len);
  results[0] = wasm::Val::i32(result);
  return nullptr;
}

WAVE_FUNC(fs_avail) {
  instance_fds* fds = &global_fds;
  ARG(0, fd, i32);

  TRACE("fs_avail(fd=%d)\n", fd);

  int sys_fd = fds->get_sys_fd(fd);
  if (sys_fd < 0) { RETURN_MINUS_1; }
  auto cur = lseek(sys_fd, 0, SEEK_CUR);
  auto avail = lseek(sys_fd, 0, SEEK_END) - cur;
  lseek(sys_fd, cur, SEEK_SET);
  results[0] = wasm::Val::i32(static_cast<int32_t>(avail));
  return nullptr;
}

WAVE_FUNC(fs_close) {
  instance_fds* fds = &global_fds;
  ARG(0, fd, i32);

  TRACE("fs_close(fd=%d)\n", fd);

  int sys_fd = fds->get_sys_fd(fd);
  if (sys_fd >= 0) {
    fds->free_fd(fd);
    ::close(sys_fd);
  }
  return nullptr;
}

WAVE_FUNC(ticks_ms) {
  TRACE("ticks_ms()\n");
  struct timeval tv;
  gettimeofday(&tv, nullptr);
  uint32_t val = tv.tv_sec * 1000 + tv.tv_usec / 1000;
  results[0] = wasm::Val::i32(val);
  return nullptr;
}

WAVE_FUNC(ticks_us) {
  TRACE("ticks_us()\n");

  struct timeval tv;
  gettimeofday(&tv, nullptr);
  uint32_t val = tv.tv_sec * 1000000 + tv.tv_usec;
  results[0] = wasm::Val::i32(val);
  return nullptr;
}

WAVE_FUNC(ticks_ns) {
  TRACE("ticks_ns()\n");

  struct timeval tv;
  gettimeofday(&tv, nullptr);
  uint32_t val = tv.tv_sec * 10000000000 + tv.tv_usec * 1000;
  results[0] = wasm::Val::i32(val);
  return nullptr;
}

WAVE_FUNC(throw_ex) {
  ARG(0, ex, i32);
  ARG(1, ex_len, i32);
  ARG(2, msg, i32);
  ARG(3, msg_len, i32);
  return nullptr;
}
//============================================================================
