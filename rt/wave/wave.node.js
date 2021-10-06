const fs = require("fs");
const util = require("util");
var args = process.argv.slice(3);
var memory = undefined;

function extract_path(ptr, len) {
  return new util.TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
}

const wave = {
  arg_len: (arg) => {
    return args[arg].length;
  },
  arg_copy: (arg, buf_ptr, len) => {
    var s = args[arg];
    var data = new util.TextEncoder().encode(s);
    for (i = 0; i < data.length && i < len; i++) memory[buf_ptr + i] = data[i];
  },
  fs_size: (path_ptr, path_len) => {
    var path = extract_path(path_ptr, path_len);
    var r = fs.lstatSync(path);
    return r.size;
  },
  fs_chmod: (path_ptr, path_len, perm) => {
    var path = extract_path(path_ptr, path_len);
    fs.chmodSync(path, perm);
  },
  fs_open: (path_ptr, path_len, read) => {
    var path = extract_path(path_ptr, path_len);
    if (read != 0) {
      return fs.openSync(path, fs.constants.O_RDONLY);
    } else {
      return fs.openSync(path, fs.constants.O_WRONLY);
    }
  },
  fs_read: (fd, buf_ptr, buf_len) => {
    return fs.writeSync(fd, memory, buf_ptr, buf_len); // TODO: handle errors
  },
  fs_write: (fd, buf_ptr, buf_len) => {
    return fs.writeSync(fd, memory, buf_ptr, buf_len); // TODO: handle errors
  },
  fs_avail: (fd) => {
    // TODO
  },
  fs_close: (fd) => {
    fs.closeSync(fd);
  },
  ticks_ms: () => {
    var [t0, t1] = process.hrtime();
    return (t0 * 1000 + t1 / 1000000) | 0;
  },
  ticks_us: () => {
    var [t0, t1] = process.hrtime();
    return (t0 * 1000000 + t1 / 1000) | 0; },
  ticks_ns: () => {
    var [t0, t1] = process.hrtime();
    return (t0 * 1000000000 + t1) | 0;
  },
  throw_ex: (ex_ptr, ex_len, msg_ptr, msg_len) => {
  }
}

const bytes = fs.readFileSync(process.argv[2]);
const wasm = new WebAssembly.Module(bytes);
const instance = new WebAssembly.Instance(wasm, {wave: wave});
memory = instance.exports.memory;
if (memory == undefined) memory = instance.exports.mem;
memory = new Uint8Array(memory.buffer);

var main = instance.exports[".entry"];
if (main == undefined) main = instance.exports["entry"];
if (main == undefined) main = instance.exports["main"];
main(args.length);
