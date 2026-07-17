# ARM64 Port: Progress Tracker

This document tracks progress on the arm64 port of the Virgil compiler.
See `tasks/Port-arm64.md` for the full technical spec.

## How to Resume After Context Loss

If you are Claude Code and have just been restarted with no context, do this:

1. **Read the spec**: `tasks/Port-arm64.md` — implementation plan, design decisions, all phases
2. **Read this file**: `tasks/Port-arm64-progress.md` — find the first checkpoint marked `[ ]` (not done)
3. **Check git history**: `git log --oneline -20` — see what was last committed
4. **Check passing tests**: look for `test/*/success.arm64-linux` files — these show current state
5. **Verify environment**:
   ```bash
   export PATH=$PATH:$(pwd)/bin:$(pwd)/bin/dev
   v3c-dev -target=arm64-linux-test -output=/tmp test/core/add00.v3
   # Should compile without "unimplemented" errors
   ```
6. **Continue** from the first unchecked checkpoint below

## Success File Convention

Each test suite has a success file listing currently-passing tests:
- `test/core/success.arm64-linux`
- `test/cast/success.arm64-linux`
- `test/fsi32/success.arm64-linux`
- `test/fsi64/success.arm64-linux`
- `test/variants/success.arm64-linux`
- `test/enums/success.arm64-linux`
- `test/float/success.arm64-linux`
- etc.

Format: one filename per line (basename only, e.g. `add00.v3`), sorted.

These files grow monotonically — new passing tests are appended, nothing is removed.
They are removed entirely once all tests in a suite pass.

### How to run tests and update success files

Single test (fast, no build needed):
```bash
export PATH=$PATH:$(pwd)/bin:$(pwd)/bin/dev
v3c-dev -target=arm64-linux-test -output=/tmp test/core/add00.v3
# Run on arm64 via Docker:
docker run --rm --platform linux/arm64 -v /tmp:/tmp alpine:3.20 /tmp/add00
# Or use the test runner directly (if on arm64 Linux or via Docker):
```

Full suite via test runner (requires arm64 execution environment):
```bash
cd test/core
TEST_TARGETS=arm64-linux AENEAS_TEST=v3c-dev ./test.bash
```

After bootstrap (faster for large runs):
```bash
make bootstrap
cd test/core
TEST_TARGETS=arm64-linux AENEAS_TEST=current ./test.bash
```

The test runner reports pass/fail per test. Collect the passing ones into the success file.

### Updating the success file after a checkpoint

After a checkpoint, run the relevant test suite(s) and update the success file:
```bash
# Example: after a checkpoint, regenerate test/core/success.arm64-linux
# (exact command depends on how the test runner reports results)
cd test/core
TEST_TARGETS=arm64-linux AENEAS_TEST=v3c-dev ./test.bash 2>&1 | grep "^PASS" | awk '{print $2}' | sort > success.arm64-linux
```

## Commit Convention

Each checkpoint = one git commit. Commit message format:
```
[arm64] <short description>

<what was implemented>
<test results: N/M tests pass in test/core>
```

Example:
```
[arm64] implement integer arithmetic (Mul, Div, Mod, And, Or, Xor, shifts)

Implements IntMul, IntDiv, IntMod, IntAnd, IntOr, IntXor, IntShl, IntSar,
IntShr in SsaArm64Gen. Adds corresponding assembler instructions. Fixes
tryUseImm32 to use 12-bit ARM64 immediate constraint.

test/core: 312/3903 tests pass (up from 0)
```

After each commit, write a brief report to `tasks/reports/arm64-cpN.md` (where N is the checkpoint number).

## Report Convention

Each checkpoint report lives in `tasks/reports/arm64-cpN.md`. Format:
```markdown
# ARM64 Checkpoint N: <title>

Commit: <hash>
Date: <date>

## What was implemented
...

## Test results
- test/core: N/3903 pass
- test/cast: N/M pass  (if applicable)

## Known issues / next steps
...
```

---

## Checkpoint Plan

### CP1: Register allocation basics + fix imm12 [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`

What to implement:
- Fix `tryUseImm32`: ARM64 ADD/SUB immediate is 12-bit unsigned (0–4095), not 32-bit. Only use `AM_R_R_I_I` when the value fits in u12; otherwise fall back to register form.
- Implement `genMoveLocLoc`: GPR→GPR via `MOV` (ORR Xd, XZR, Xn), stack→GPR via `LDR`, GPR→stack via `STR`. Add opcodes I_MOVR/I_MOVRQ in the instruction encoding.
- Implement `genMoveConstStack`: load constant to scratch register (R16), STR to stack slot.
- Add `MOV` to assembler if not present (encoded as `ORR Rd, XZR, Rm`).

Test target: any test in `test/core` that uses integer addition with non-trivial register pressure.

Commit message: `[arm64] fix imm12 constraint and implement genMoveLocLoc`

---

### CP2: Integer arithmetic (all ops) [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `lib/asm/arm64/Arm64Assembler.v3`

What to implement in `visitApply`:
- `IntMul` → `MUL Rd, Rn, Rm` (muld/mulq already in assembler)
- `IntDiv` signed → `SDIV`, unsigned → `UDIV` (sdivd/sdivq/udivd/udivq in assembler)
- `IntMod` → `SDIV/UDIV` + `MSUB Rd, Rtmp, Rm, Rn` (Rd = Rn - Rtmp*Rm). Needs a temp register.
- `IntAnd` / `BoolAnd` → `AND` (andd/andq in assembler)
- `IntOr` / `BoolOr` → `ORR` (orrd/orrq in assembler)
- `IntXor` → `EOR` (eord/eorq in assembler)
- `IntShl` → `LSLV Rd, Rn, Rm` (variable shift; add to assembler if missing)
- `IntSar` → `ASRV Rd, Rn, Rm` (asrd/asrq in assembler — verify names)
- `IntShr` → `LSRV Rd, Rn, Rm` (add to assembler if missing)

All ops have 32-bit (D suffix) and 64-bit (Q suffix) forms selected by `selectWidth`.

Assembler additions needed (check what's already there):
- `lslvd_r_r_r`, `lslvq_r_r_r` — logical shift left variable
- `lsrvd_r_r_r`, `lsrvq_r_r_r` — logical shift right variable
- Verify `msubd_r_r_r_r`, `msubq_r_r_r_r` exist (for IntMod)

Add these to `test/asm/arm64/Arm64AssemblerTestGen.v3` if new assembler instructions are added.

Expected test results: a significant fraction of `test/core` should pass (integer arithmetic tests).

Commit message: `[arm64] implement all integer arithmetic operations`

---

### CP3: Comparisons, BoolNot, visitSwitch [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `lib/asm/arm64/Arm64Assembler.v3`

What to implement:
- Add `CMP` opcode: `cmpd_r_r` and `cmpq_r_r` (already in assembler as `cmpd_r_r_sh_u5` with shift=LSL, amount=0)
- Add `CSET Rd, cond`: add `cset_r_cond` to assembler
- In `visitApply`:
  - `IntEq` → CMP + CSET EQ
  - `IntLt` signed → CMP + CSET LT; unsigned → CMP + CSET LO
  - `IntLteq` signed → CMP + CSET LE; unsigned → CMP + CSET LS
  - `BoolEq` → CMP + CSET EQ (32-bit)
  - `BoolNot` → EOR Rd, Rs, #1 (add `eord_r_r_u12` form if needed)
  - `RefEq` → CMP + CSET EQ (64-bit)
- Optimize `visitIf` when condition is a comparison in the same block: emit CMP + B.cond instead of CSET + CBZ
  - Check `inSameBlock` (see how x86-64 does this in `emitCmp`)
  - Add `B.cond imm19` to assembler: `b_cond_i19` (already exists)
- `visitSwitch`: emit linear sequence of CMP + B.EQ for each case, unconditional B for default. (Jump table optimization is future work.)
- `visitThrow`: emit BL to a fatal stub address (use I_B for now with a placeholder; full stubs in CP9).

Commit message: `[arm64] implement comparisons, BoolNot, and visitSwitch`

---

### CP4: Constant pool (ARM64_REL_IMM19) [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `aeneas/src/arm64/Arm64Backend.v3`, `aeneas/src/mach/MachDataWriter.v3`

What to implement:
- Add `ARM64_REL_IMM19` handler in `MachDataWriter.patchWithCallback`:
  ```
  ARM64_REL_IMM19 => {
      var offset = int.!((absAddr - posAddr) / 4);
      var old = read_b32(pos);
      put_b32((old & 0xFF00001F) | ((offset & 0x7FFFF) << 5));
  }
  ```
  LDR literal encoding: bits [23:5] = imm19, bits [4:0] = Rt, upper bits determine size.
- Add `Arm64ConstPool` class (in `Arm64Backend.v3` or new file `Arm64ConstPool.v3`):
  - Maintains list of `(Addr, List<int>)` — addr value + list of code positions of forward LDR references
  - `add(addr: Addr) -> void`: adds addr, emits `LDR Xn, [PC, #0]` placeholder, records patch position
  - `flush(w: MachDataWriter)`: emits 8-byte pool entries inline, patches all LDR offsets
  - Pool is flushed at `ARCH_END` and when approaching 800KB of code within a chunk
- Update `genMoveConstReg` for `Addr` values: instead of failing or using MOVZ+MOVK, use the constant pool
- Add opcode `I_LDR_POOL` (LDR literal from constant pool) to the instruction encoding

This enables loading method and record addresses at runtime.

Commit message: `[arm64] implement constant pool for address constants (ARM64_REL_IMM19)`

---

### CP5: Direct and indirect calls [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`

What to implement in `visitApply`:
- `CallAddress(funcRep)`:
  - Set up parameter moves per calling convention (register allocator handles this)
  - Kill caller-saved registers: emit `kill(Regs.ALL)`
  - Emit refmap for GC: `refmap(null)` (or appropriate refmap)
  - Direct call: emit `BL imm26` with `ARM64_REL_IMM26` patch. Use `context.fail` if known to be > 128MB.
  - Record the call via `useImm(methodAddr)` and `emitN(I_BL)`
- `TupleGetElem`: no-op (calls define their projections)
- `KillRegisters`: emit `kill(Regs.ALL)` + `emitN(I_KILL_REGS)`
- `CallerIp`: use `ADR Xd, .` (add `adr_r_i21` to assembler if missing, or use a BL+pop trick)
- `CallerSp`: `MOV Xd, SP` (add `mov_r_sp` to assembler)

Assembler additions:
- `bl_pool`: BL via constant pool (LDR X16 from pool + BLR X16) for >128MB range (defer, add context.fail for now)

Expected: call-heavy tests in test/core pass.

Commit message: `[arm64] implement direct calls (CallAddress)`

---

### CP6: Load/store, PtrAdd/Sub, Alloc [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `lib/asm/arm64/Arm64Assembler.v3`

What to implement in `visitApply`:
- `PtrLoad`: select LDR variant by type size and signedness:
  - 1 byte unsigned: `LDRB Wd, [Xn, #offset]`
  - 1 byte signed: `LDRSB Xd, [Xn, #offset]`
  - 2 byte unsigned: `LDRH`, signed: `LDRSH`
  - 4 byte: `LDR Wd` (or `LDR Sd` for float)
  - 8 byte: `LDR Xd` (or `LDR Dd` for double)
  - Addressing: use `[Xbase, #imm12*scale]` for constant offsets; `[Xbase, Xindex, LSL #scale]` for variable
- `PtrStore`: symmetric STR variants
- `PtrAdd` → `ADD Xd, Xn, Xm` (64-bit)
- `PtrSub` → `SUB Xd, Xn, Xm` (64-bit)
- `Alloc`:
  - If `mach.allocStub != null`: call alloc stub (load from pool + BLR, size in X1, result in X0)
  - Otherwise: emit `I_TEST_ALLOC` (ovwReg, for test mode)
- `IntViewP` → same as PtrAdd with zero (mov)

Assembler additions (verify what's missing):
- `ldrb_r_r_u12`, `ldrsb_r_r_u12`, `ldrh_r_r_u12`, `ldrsh_r_r_u12` (byte/halfword loads)
- `strb_r_r_u12`, `strh_r_r_u12` (byte/halfword stores)
- `ldrb_r_r_r_ex_u1`, `strb_r_r_r_ex_u1` etc. (indexed forms)

Expected: array/class/record tests in test/core pass.

Commit message: `[arm64] implement PtrLoad, PtrStore, PtrAdd, PtrSub, and Alloc`

---

### CP7: Integer type conversions [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `lib/asm/arm64/Arm64Assembler.v3`

What to implement in `visitApply`:
- `IntViewI`: reinterpret integer as different integer type (truncation/extension)
  - Widening: no-op or MOV
  - Narrowing unsigned: AND with mask
  - Sign extension: SBFX (signed bit field extract) or shift+shift (LSL then ASR)
  - See `SsaX86_64Gen.emitIntViewI` for full logic — replicate for arm64
- `IntViewB`: bool to int bit extraction (UBFX for unsigned, SBFX for signed)
- `IntViewP`: ptr to int — MOV (64-bit)
- `FloatViewI(is64)`: move bits from GPR to FP register: `FMOV Sd, Wn` / `FMOV Dd, Xn`
- `IntViewF(is64)`: move bits from FP to GPR: `FMOV Wd, Sn` / `FMOV Xd, Dn`

Assembler additions:
- `sbfx_r_r_u6_u6` — signed bit field extract (for sign extension)
- `ubfx_r_r_u6_u6` — unsigned bit field extract
- `fmovs_r_gpr`, `fmovd_r_gpr` — GPR→FP moves (check existing names)
- `fmovgpr_r_s`, `fmovgpr_r_d` — FP→GPR moves

Expected: test/cast and test/fsi32/fsi64 progress.

Commit message: `[arm64] implement integer type conversions (IntViewI, IntViewB, IntViewP, FloatViewI, IntViewF)`

---

### CP8: Checks, throws, and remaining control flow [ ]

**Files**: `aeneas/src/arm64/SsaArm64Gen.v3`, `aeneas/src/arm64/Arm64Backend.v3`

What to implement:
- `ConditionalThrow(exception)`:
  - Takes a boolean condition; if true, branch to a fatal stub
  - Emit: `CBNZ Rcond, fatal_stub_addr` (or `CBZ` depending on sense)
  - The fatal stub addr comes from `useExSource(exception, i.source)`
  - Mirror the x86-64 `I_THROWC` approach
- `visitThrow(block, i)`:
  - Emit unconditional branch to exception stub
- `genFatalStub(ex, addr)` in Arm64Backend:
  - Emit a small stub: sys_write to stderr (fd=2) the exception name, then sys_exit_group(1)
  - Bind `addr` to the stub's position
- `genSignalHandlerStub()` in Arm64Backend:
  - SIGSEGV handler → NullCheck stub
  - SIGFPE handler → DivideByZero stub
- `genSigHandlerInstall(signo, handler)` in Arm64LinuxBackend:
  - Emit code to call `rt_sigaction` (syscall 134 on arm64-linux)
  - Pass `signo`, pointer to `sigaction` struct with `handler`, flags=SA_SIGINFO
- `asm_exit_r(r)` in Arm64LinuxBackend:
  - `MOV X8, #94; MOV X0, Xr; SVC #0`

Commit message: `[arm64] implement ConditionalThrow, signal handlers, and fatal stubs`

---

### CP9: Floating point arithmetic and comparisons [ ]

**Files**: `aeneas/src/arm64/Arm64RegSet.v3`, `aeneas/src/arm64/SsaArm64Gen.v3`, `lib/asm/arm64/Arm64Assembler.v3`

What to implement:

**FP register allocation** (`Arm64RegSet.v3`):
- Set `sfrCount = 8`
- Add V0–V7 to the allocatable SFR set (all caller-save in Virgil's convention)
- Update `locToSfrArr` to map loc values to `Arm64Sfr` registers
- Update `regClasses`: F32 and F64 map to the SFR set (not ALL)
- Add `toSfr(loc) -> Arm64Sfr` method

**FP calling convention** (`Arm64RegSet.v3`):
- Add `PARAM_SFRS = [V0..V7]` and `RET_SFRS = [V0]`
- Update `Arm64VirgilCallConv.alloc()` to use SFRs for F32/F64 types

**FP in `visitApply`** (`SsaArm64Gen.v3`):
- `FloatAdd(is64)` → `FADD Sd,Sn,Sm` / `FADD Dd,Dn,Dm`
- `FloatSub(is64)` → `FSUB`
- `FloatMul(is64)` → `FMUL`
- `FloatDiv(is64)` → `FDIV`
- `FloatSqrt(is64)` → `FSQRT`
- `FloatAbs(is64)` → `FABS`
- `FloatCeil(is64)` → `FRINTP Sd, Sn`
- `FloatFloor(is64)` → `FRINTM Sd, Sn`
- `FloatRound(is64)` → `FRINTN Sd, Sn` (round to nearest)
- `FloatRoundD` → `FCVT Sd, Dn`
- `FloatPromoteF` → `FCVT Dd, Sn`
- `FloatPromoteI(is64)` → `SCVTF Sd/Dd, Wn/Xn` (signed int→float)
- `FloatRoundI(is64)` → same (with signedness from int type)
- `IntCastF(is64)` / `IntTruncF(is64)` → `FCVTZS Wd/Xd, Sn/Dn` (float→int, truncate toward zero)
- `FloatEq(is64)` → `FCMP + CSET EQ`
- `FloatNe(is64)` → `FCMP + CSET NE`
- `FloatLt(is64)` → `FCMP + CSET MI`
- `FloatLteq(is64)` → `FCMP + CSET LS`

**FP in `genMoveLocLoc`**:
- SFR→SFR: `FMOV Sd, Sn` / `FMOV Dd, Dn`
- Stack spill: `STR Sd, [SP, #offset]` / `LDR Sd, [SP, #offset]`

**Assembler additions** (verify what's already there):
- `frintpd_r_r`, `frintps_r_r` — round toward +inf
- `frintmd_r_r`, `frintms_r_r` — round toward -inf
- `frintnd_r_r`, `frintns_r_r` — round to nearest
- `scvtfd_r_r`, `scvtfs_r_r` — signed int→float (32-bit int src)
- `scvtfqd_r_r`, `scvtfqs_r_r` — signed int→float (64-bit int src)
- `ucvtfd_r_r` etc. — unsigned int→float
- `fcvtzsd_r_r`, `fcvtzss_r_r` — float→signed int
- `fcmpd_r_zero`, `fcmps_r_zero` — compare with zero (already present?)

Expected: test/float passes.

Commit message: `[arm64] implement floating point arithmetic, comparisons, and conversions`

---

### CP10: Runtime (rt/arm64-linux/) [ ]

**Files**: new directory `rt/arm64-linux/` with `DEPS`, `LinuxConst.v3`, `RiOs.v3`, `System.v3`

Port from `rt/x86-64-linux/`. Key differences:

arm64 Linux syscall ABI:
- Syscall number in x8 (not rax)
- Args in x0–x5 (not rdi, rsi, rdx, r10, r8, r9)
- Return in x0
- Instruction: `SVC #0` (not `SYSCALL`)

Key arm64-linux syscall numbers (different from x86-64):
| Name | arm64 | x86-64 |
|------|-------|---------|
| read | 63 | 0 |
| write | 64 | 1 |
| openat | 56 | — |
| close | 57 | 3 |
| fstat | 80 | 5 |
| mmap | 222 | 9 |
| munmap | 215 | 11 |
| brk | 214 | 12 |
| rt_sigaction | 134 | 13 |
| exit | 93 | 60 |
| exit_group | 94 | 231 |

In `RiOs.v3`, the inline syscall assembly uses Virgil's `System.caller*` primitives or `CallKernel` ops. Update register assignments throughout.

Also update `Arm64Backend.genEntryStub()` and related to work with the full runtime (not just test mode).

Expected: test/rt, test/system, and other runtime-dependent tests pass.

Commit message: `[arm64] implement arm64-linux runtime (rt/arm64-linux/)`

---

### CP11: GC support and stack walking [ ]

**Files**: `rt/arm64-linux/`, `aeneas/src/arm64/Arm64Backend.v3`, possibly `rt/gc/`

What to implement:
- Verify GC-related stackmap generation works for arm64 (same data structure as x86-64)
- Implement `ri_gc` path in `Arm64Backend` constructor (currently calls `unimplemented()`)
- Stack walker: use the PC-indexed side-table of frame sizes to walk frames
- Test with `test/gc` suite

Also: implement the `-fp` frame pointer option:
- When `-fp` is enabled, save `{X29, X30}` at frame entry, restore at exit
- Emit `STP X29, X30, [SP, #-16]!` at entry, `LDP X29, X30, [SP], #16` at exit
- Update `computeFrameSize` to account for this

Commit message: `[arm64] GC support and optional frame pointer (-fp)`

---

## Progress Log

| CP | Title | Status | Commit | test/core | test/cast | test/float |
|----|-------|--------|--------|-----------|-----------|------------|
| 1 | Register alloc basics + imm12 fix | [ ] | — | 0/3903 | — | — |
| 2 | Integer arithmetic | [ ] | — | — | — | — |
| 3 | Comparisons + visitSwitch | [ ] | — | — | — | — |
| 4 | Constant pool (REL_IMM19) | [ ] | — | — | — | — |
| 5 | Direct/indirect calls | [ ] | — | — | — | — |
| 6 | Load/store, PtrAdd/Sub, Alloc | [ ] | — | — | — | — |
| 7 | Integer type conversions | [ ] | — | — | — | — |
| 8 | Checks, throws, signal handlers | [ ] | — | — | — | — |
| 9 | Floating point | [ ] | — | — | — | — |
| 10 | Runtime (rt/arm64-linux/) | [ ] | — | — | — | — |
| 11 | GC + frame pointer | [ ] | — | — | — | — |
