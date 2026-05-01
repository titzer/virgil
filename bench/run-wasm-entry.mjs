// Run a Virgil-compiled .wasm binary that exports `entry()` (rather than
// `_start`). Used by the enum benchmarks: Virgil's wasm/wasm-gc targets
// export `entry`, not `_start`, so we set up WASI as a "reactor"
// (initialize + manually call entry()) instead of using wasi.start().
//
// returnOnExit:false makes proc_exit call process.exit(code) directly,
// so the program's exit code propagates and a real wasm trap stays
// uncaught (visible as a node failure rather than a silent zero exit).
//
// Usage: node --no-warnings --experimental-wasi-unstable-preview1 \
//        run-wasm-entry.mjs <path-to-wasm> [program-args...]

import { readFileSync } from 'node:fs';
import { WASI } from 'wasi';
import { argv, env } from 'node:process';

const wasm_path = argv[2];
// WASI's `args` is the program's argv: index 0 is the program name and is
// skipped by Virgil's RiRuntime, so the user-visible args[] starts at 1.
const program_args = ['program', ...argv.slice(3)];

const wasi = new WASI({
  returnOnExit: false,
  version: 'preview1',
  args: program_args,
  env,
  preopens: { '.': '.' },
});
const importObject = { wasi_snapshot_preview1: wasi.wasiImport };

const bytes = readFileSync(wasm_path);
const instance = new WebAssembly.Instance(new WebAssembly.Module(bytes), importObject);

wasi.initialize(instance);
instance.exports.entry();
