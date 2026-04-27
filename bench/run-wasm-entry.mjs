// Run a Virgil-compiled .wasm binary that exports `entry()` (rather than
// `_start`). Used by the enum benchmarks: Virgil's wasm/wasm-gc targets
// export `entry`, not `_start`, so we set up WASI as a "reactor"
// (initialize + manually call entry()) instead of using wasi.start().
//
// Quirk: when the program calls proc_exit() under a reactor-initialized
// WASI on node, the WASI implementation throws (a Symbol with
// returnOnExit:true, or RuntimeError("unreachable") otherwise) rather
// than terminating cleanly. Either flavor signals a normal exit; we
// catch both.
//
// Usage: node --no-warnings --experimental-wasi-unstable-preview1 \
//        run-wasm-entry.mjs <path-to-wasm> [program-args...]

import { readFileSync } from 'node:fs';
import { WASI } from 'wasi';
import { argv, env, exit } from 'node:process';

const wasm_path = argv[2];
// WASI's `args` is the program's argv: index 0 is the program name and is
// skipped by Virgil's RiRuntime, so the user-visible args[] starts at 1.
const program_args = ['program', ...argv.slice(3)];

const wasi = new WASI({
  returnOnExit: true,
  version: 'preview1',
  args: program_args,
  env,
  preopens: { '.': '.' },
});
const importObject = { wasi_snapshot_preview1: wasi.wasiImport };

const bytes = readFileSync(wasm_path);
const module_ = new WebAssembly.Instance(new WebAssembly.Module(bytes), importObject);

wasi.initialize(module_);
try {
  module_.exports.entry();
  exit(0);
} catch (e) {
  // Both proc_exit's Symbol throw (with returnOnExit:true) and the
  // RuntimeError("unreachable") trap from the post-proc_exit unreachable
  // mean the program terminated normally. Anything else is a real error.
  if (typeof e === 'symbol') exit(0);
  if (e instanceof WebAssembly.RuntimeError && /unreachable/.test(e.message)) {
    exit(0);
  }
  throw e;
}
