import { readFileSync } from 'node:fs';
import { WASI } from 'wasi';
import { argv, env } from 'node:process';

var program_args = argv.slice(2);

const wasi = new WASI({
  args: program_args,
  env,
  preopens: {
    '.': '.'
  }
});

// Some WASI binaries require:
//   const importObject = { wasi_unstable: wasi.wasiImport };
const importObject = { wasi_snapshot_preview1: wasi.wasiImport };

const bytes = readFileSync(argv[2]);
const wasm = new WebAssembly.Module(bytes);
const instance = new WebAssembly.Instance(wasm, importObject);

var result = wasi.start(instance);

