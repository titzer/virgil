#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <cinttypes>
#include <sys/time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#include "wasm.hh"

#define TRACE(...) printf(__VA_ARGS__)

#define WAVE_FUNC(name) auto wave_##name(const wasm::Val args[], wasm::Val results[]) -> wasm::own<wasm::Trap*>

#define ERROR(msg, filename) (std::cout << "ERROR: " << msg << filename << std::endl, 1)

struct Use {
  template <typename T>
  Use(T&&) {}
};
#define USE(...)                                                   \
  do {                                                             \
    Use unused_tmp_array_for_use_macro[]{__VA_ARGS__}; \
    (void)unused_tmp_array_for_use_macro;                          \
  } while (false)

#define FD_MAX 1024
#define FD_MASK ((FD_MAX)-1)

struct instance_fds {
  int fd_map[FD_MAX];
  int last_fd = 2;

  void clear() {
    fd_map[0] = 0;
    fd_map[1] = 0;
    fd_map[2] = 0;
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

#define MAXPATH 1024

instance_fds global_fds;
uint8_t global_pathbuf[MAXPATH + 1];
wasm::Memory* global_memory;
int global_argc;
char** global_argv;

void* checkbuffer(int32_t buffer, int32_t length) {
  // XXX: remove 2GiB restrictions here
  if (!global_memory) return nullptr;
  if (buffer < 0) return nullptr;
  if (length < 0) return nullptr;
  if (buffer + length < 0) return nullptr;
  if (length > global_memory->data_size()) return nullptr;
  if (buffer + length > global_memory->data_size()) return nullptr;
  return global_memory->data() + buffer;
}

inline char* copypath(int32_t path, int32_t path_len) {
  if (path_len < 0 || path_len > MAXPATH) return nullptr;
  void* mem = checkbuffer(path, path_len);
  if (mem) {
    memcpy(global_pathbuf, mem, path_len);
    global_pathbuf[path_len] = 0;
    return reinterpret_cast<char*>(global_pathbuf);
  }
  return nullptr;
}

#define ARG(index, name, type) auto name = args[index].type(); USE(name)
#define RETURN_MINUS_1 results[0] = wasm::Val::i32(-1); return nullptr

bool sig_equal(const wasm::FuncType* a, const wasm::FuncType* b) {
  if (a->params().size() != b->params().size()) return false;
  for (size_t i = 0; i < a->params().size(); i++) {
    if (a->params()[i] != b->params()[i]) return false;
  }
  if (a->results().size() != b->results().size()) return false;
  for (size_t i = 0; i < a->results().size(); i++) {
    if (a->results()[i] != b->results()[i]) return false;
  }
  return true;
}

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
  TRACE("fs_size(path=\"%*s\")\n", path_len, path_str);
  if (!path_str) { RETURN_MINUS_1; }

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
  TRACE("fs_chmod(path=\"%*s\", mode=0x%08x)\n", path_len, path_str, mode);
  if (!path_str) { RETURN_MINUS_1; }
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
  if (sys_fd >= 0) { RETURN_MINUS_1; }
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


//============================================================================
//=={ main function }=========================================================
//============================================================================
int main(int argc, char* argv[]) {
  global_argc = argc - 1;
  global_argv = &argv[1];

  if (argc < 2) {
    std::cout << "Error: no input files" << std::endl;
    return 1;
  }

  // Load binary.
  auto filename = argv[1];
  std::ifstream file(filename);
  file.seekg(0, std::ios_base::end);
  auto file_size = file.tellg();
  file.seekg(0);
  auto binary = wasm::vec<byte_t>::make_uninitialized(file_size);
  file.read(binary.get(), file_size);
  file.close();
  if (file.fail()) return ERROR("loading", filename);

  // Set up the engine.
  auto engine = wasm::Engine::make();
  auto store_ = wasm::Store::make(engine.get());
  auto store = store_.get();

  // Initialize the file system.
  global_fds.clear();

  // Compile.
  TRACE("Compiling module...\n");
  auto module = wasm::Module::make(store, binary);
  if (!module) return ERROR("compiling", filename);

  // Create imported functions.
#define V(...) wasm::vec<wasm::ValType*>::make(__VA_ARGS__)
#define F(a, b) wasm::FuncType::make(a, b)
  auto ti = wasm::ValType::make(wasm::I32);
  auto i_i = F(V(ti), V(ti));
  auto iii_i = F(V(ti, ti, ti), V(ti));
  auto ii_i = F(V(ti, ti), V(ti));
  auto v_i = F(V(), V(ti));
  auto iiii_v = F(V(ti, ti, ti, ti), V());

#define IMPORT_ENTRY(name, sig) {#name, sizeof(#name), wave_##name, sig}

  struct ImportEntry {
    const char* name;
    size_t name_len;
    wasm::own<wasm::Trap *> (*func)(const wasm::Val *, wasm::Val *);
    wasm::own<wasm::FuncType*>& sig;
  } import_entries[] = {
    IMPORT_ENTRY(arg_len, i_i),
    IMPORT_ENTRY(arg_copy, iii_i),
    IMPORT_ENTRY(fs_size, ii_i),
    IMPORT_ENTRY(fs_chmod, iii_i),
    IMPORT_ENTRY(fs_open, iii_i),
    IMPORT_ENTRY(fs_read, iii_i),
    IMPORT_ENTRY(fs_write, iii_i),
    IMPORT_ENTRY(fs_avail, i_i),
    IMPORT_ENTRY(fs_close, i_i),
    IMPORT_ENTRY(ticks_ms, v_i),
    IMPORT_ENTRY(ticks_us, v_i),
    IMPORT_ENTRY(ticks_ns, v_i),
    IMPORT_ENTRY(throw_ex, iiii_v),
  };

  constexpr size_t num_import_entries = sizeof(import_entries) / sizeof(ImportEntry);

  // Process imports of the module.
  TRACE("Processing imports...\n");
  auto imports = module->imports();
  wasm::Extern** import_bindings = new wasm::Extern*[imports.size()];
  for (size_t i = 0; i < imports.size(); i++) {
    auto imp = imports[i];
    if (imp->type()->kind() != wasm::EXTERN_FUNC) return ERROR("wrong import type", filename);
    if (imp->module().size() != 4 || !strncmp("wave", imp->module().get(), 4)) return ERROR("only imports from \'wave\' allowed", filename);
    bool found = false;
    auto func_type = imp->type()->func();
    // XXX: linear search for each import. Replace with std::unordered_map ?
    for (size_t j = 0; j < num_import_entries; j++) {
      auto candidate = &import_entries[j];
      if (candidate->name_len != imp->name().size()) continue;
      if (!strncmp(candidate->name, imp->name().get(), candidate->name_len)) continue;
      if (!sig_equal(candidate->sig.get(), imp->type()->func())) return ERROR("import with wrong signature", filename);

      // Construct the imported function.
      auto imp_func = wasm::Func::make(store, candidate->sig.get(), candidate->func);
      import_bindings[i] = imp_func.get();
      found = true;
    }
    if (!found) return ERROR("import not found", filename);
  }

  // Instantiate.
  TRACE("Instantiating module...\n");
  auto instance = wasm::Instance::make(store, module.get(), import_bindings);
  if (!instance) return ERROR("instantiating", filename);

  // Extract export(s).
  TRACE("Extracting exports...\n");
  auto exports = instance->exports();
  wasm::Func* entry_func = nullptr;
  for (size_t i = 0; i < exports.size(); i++) {
    auto e = exports[i];
    switch (e->kind()) {
    case wasm::EXTERN_MEMORY:
      global_memory = e->memory();
      break;
    case wasm::EXTERN_FUNC:
      entry_func = e->func();
      break;
    default:
      // ignore exports of other types.
      break;
    }
  }

  if (!entry_func) return ERROR("no entry function", filename);

  // Call the entrypoint function.
  wasm::Val args[] = { wasm::Val::i32(global_argc) };
  wasm::Val results[1];
  auto trap = entry_func->call(args, results);
  if (trap) {
    std::cout << "Trap: " << trap->message().get() << std::endl;
    return 42;
  }

  return results[0].i32();
}
