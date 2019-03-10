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

#define ENABLE_TRACE 1

#if ENABLE_TRACE
#define TRACE(...) if(global_trace) printf(__VA_ARGS__)
#else
#define TRACE(...)
#endif

#define WAVE_FUNC(name) auto wave_##name(const wasm::Val args[], wasm::Val results[]) -> wasm::own<wasm::Trap*>

#define ERROR(...) printf("ERROR: " __VA_ARGS__)

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

bool global_trace;
char* global_filename;
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

bool sig_equal(const wasm::FuncType* fa, const wasm::FuncType* fb) {
  {
    auto& a = fa->params();
    auto& b = fb->params();
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); i++) {
      if (a[i] != b[i]) return false;
    }
  }
  {
    auto& a = fa->results();
    auto& b = fb->results();
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); i++) {
      if (a[i] != b[i]) return false;
    }
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
  // Process arguments.
#define ARG_MATCH(expr, str) (strncmp((expr)+2, str, sizeof(str)-1) == 0)
  int i = 1;
  while (i < argc) {
    auto arg = argv[i];
    if (strncmp("--", arg, 2)) break;
    if (ARG_MATCH(arg, "trace")) {
      global_trace = true;
    } else {
      ERROR("unrecognized option: %s\n", arg);
      return -1;
    }
    i++;
  }
  global_filename = argv[i];
  global_argc = argc - i -1;
  global_argv = &argv[i + 1];

  if (i == argc) {
    std::cout << "Error: no input files" << std::endl;
    return 1;
  }

  // Load binary.
  std::ifstream file(global_filename);
  file.seekg(0, std::ios_base::end);
  auto file_size = file.tellg();
  file.seekg(0);
  auto binary = wasm::vec<byte_t>::make_uninitialized(file_size);
  file.read(binary.get(), file_size);
  file.close();
  if (file.fail()) {
    ERROR("could not load %s\n", global_filename);
    return -1;
  }

  // Set up the engine.
  auto engine = wasm::Engine::make();
  auto store_ = wasm::Store::make(engine.get());
  auto store = store_.get();

  // Initialize the file system.
  global_fds.clear();

  // Compile.
  TRACE("Compiling module...\n");
  auto module = wasm::Module::make(store, binary);
  if (!module) {
    ERROR("could not compile %s\n", global_filename);
    return -1;
  }

  // Create imported functions.
#define V(...) wasm::vec<wasm::ValType*>::make(__VA_ARGS__)
#define TI wasm::ValType::make(wasm::I32)
#define F(a, b) wasm::FuncType::make(a, b)
  auto i_i = F(V(TI), V(TI));
  auto iii_i = F(V(TI, TI, TI), V(TI));
  auto ii_i = F(V(TI, TI), V(TI));
  auto v_i = F(V(), V(TI));
  auto iiii_v = F(V(TI, TI, TI, TI), V());

#define IMPORT_ENTRY(name, sig) {#name, sizeof(#name)-1, wave_##name, sig}

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

  std::unique_ptr<wasm::own<wasm::Func*>[]> import_bindings(new wasm::own<wasm::Func*>[imports.size()]);
  for (size_t i = 0; i < imports.size(); i++) {
    auto imp = imports[i];
    if (imp->type()->kind() != wasm::EXTERN_FUNC) {
      ERROR("import[%zu] must be a function import\n", i);
      return -1;
    }
    auto& m = imp->module();
    auto& n = imp->name();
    TRACE("import[%zu] = %.*s.%.*s\n", i,
           static_cast<int>(m.size()), m.get(),
           static_cast<int>(n.size()), n.get());
    if (m.size() != 4 || strncmp("wave", m.get(), 4)) {
      ERROR("import[%zu] is not from \"wave\" module\n", i);
      return -1;
    }
    bool found = false;
    auto func_type = imp->type()->func();
    // XXX: linear search for each import. Replace with std::unordered_map ?
    for (size_t j = 0; j < num_import_entries; j++) {
      auto candidate = &import_entries[j];
      if (candidate->name_len != n.size()) continue;
      if (strncmp(candidate->name, n.get(), candidate->name_len)) continue;
      if (!sig_equal(candidate->sig.get(), func_type)) {
        ERROR("import[%zu] of \"%s\" has unexpected signature\n", i, candidate->name);
        return -1;
      }

      // Construct the imported function.
      import_bindings[i] = wasm::Func::make(store, candidate->sig.get(), candidate->func);
      found = true;
      break;
    }
    if (!found) {
      ERROR("import[%zu] wave.\"%.*s\" not found\n",
            i, static_cast<int>(m.size()), m.get());
      return -1;
    }
  }

  // Instantiate.
  TRACE("Instantiating module...\n");
  std::unique_ptr<wasm::Extern*[]> import_array(new wasm::Extern*[imports.size()]);
  for (size_t i = 0; i < imports.size(); i++) {
    import_array[i] = import_bindings[i].get();
  }
  auto instance = wasm::Instance::make(store, module.get(), import_array.get());
  if (!instance) {
    ERROR("could not instantiate the module\n");
    return -1;
  }
  
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

  if (!entry_func) {
    ERROR("no exported entrypoint function found\n");
    return -1;
  }

  // Call the entrypoint function.
  TRACE("Calling entrypoint...\n");
  wasm::Val args[] = { wasm::Val::i32(global_argc) };
  wasm::Val results[] = { wasm::Val::i32(0) };
  auto trap = entry_func->call(args, results);
  if (trap) {
    std::cout << "Trap: " << trap->message().get() << std::endl;
    return 42;
  }

  if (results[0].kind() == wasm::I32) {
    auto result = results[0].i32();
    TRACE("Return value: %d\n", result);
    return result;
  } else {
    return 0;
  }
}
