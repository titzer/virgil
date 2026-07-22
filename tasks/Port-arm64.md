# Porting task for Virgil to arm64

Objective: complete the arm64-linux (and later arm64-darwin) compilation targets in the Virgil compiler and runtime system.
Primary modifications: arm64 assembler library (`lib/asm/arm64/`), compiler backend (`aeneas/src/arm64/`), and runtime system (`rt/arm64-linux/`).

Focus: arm64-linux first. arm64-darwin later (shares most backend code; only OS stubs differ).

## Current Status

**Working:**
- Assembler (`lib/asm/arm64/Arm64Assembler.v3`, 692 lines): integer instructions, most load/store forms, branch instructions, some FP instructions, patching for REL_IMM26 (BL) and ABS_IMM16 (MOVZ/MOVK)
- Assembler test suite: `test/asm/arm64/` compares against native `as` output
- Code generator (`aeneas/src/arm64/SsaArm64Gen.v3`, 381 lines): IntAdd, IntSub, CBZ/CBNZ, B (unconditional branch), ARCH_ENTRY/ARCH_BLOCK/ARCH_RET
- `genMoveConstReg`: emits MOVZ+MOVK for 32-bit and 64-bit constants
- Backend driver (`aeneas/src/arm64/Arm64Backend.v3`): frame setup, genTestInputs, genTestOutput (for arm64-linux-test target), asm_exit_code
- Test runner: `test/bin/test-arm64-linux` and Docker runner exist
- PatchKind enum already includes ARM64_REL_IMM19, ARM64_ABS_IMM16, ARM64_REL_IMM26

**Missing — code generator:**
- `genMoveLocLoc` — register-to-register moves (critical for register allocator)
- `genMoveConstStack` — constant to stack slot
- All integer ops except Add/Sub: Mul, Div, Mod, And, Or, Xor, Shl, Sar, Shr
- All comparisons: IntEq, IntLt, IntLteq, BoolEq, BoolNot, BoolAnd, BoolOr, RefEq
- visitSwitch (switch/match dispatch)
- visitThrow
- Address constants in SSA (method pointers, record pointers): need constant pool
- Direct and indirect calls: CallAddress
- PtrLoad, PtrStore (loads/stores to memory)
- PtrAdd, PtrSub, Alloc
- All type conversions: IntViewI, IntViewB, IntViewP, FloatViewI/IntViewF, etc.
- ConditionalThrow, NullCheck, BoundsCheck
- All floating point: FP register allocation, FP arithmetic, FP comparisons, FP conversions
- KillRegisters, CallerIp, CallerSp, CallKernel, TupleGetElem

**Missing — backend:**
- `genSignalHandlerStub` (signal handler stub)
- `genFatalStub` (fatal exception stub)
- `asm_exit_r` (exit with register value)
- Signal handler installation logic
- Constant pool management (flush pool between method chunks)

**Missing — runtime:**
- `rt/arm64-linux/` directory does not exist (no DEPS, LinuxConst.v3, RiOs.v3, System.v3)

**Known issues / fixmes in existing code:**
- `tryUseImm32`: comment says "imm32 is incorrect" (line 268, SsaArm64Gen.v3) — ARM64 immediate for ADD/SUB is 12-bit unsigned, not 32-bit
- `sfrCount = 0` in Arm64RegSet: FP registers not allocated (line 11)
- CALLER_SPILL_START / CALLEE_SPILL_START need to work with 31-bit limit
- `Arm64AddrPatcher.patch()` handles REL_IMM26 and ABS_IMM16, but ARM64_REL_IMM19 case in MachDataWriter falls through to error

## Architecture Overview

The backend pipeline:
1. `SsaArm64Gen.visitApply/visitIf/visitGoto/etc.` — selects instructions, emits operand lists
2. Register allocator (`SimpleRegAlloc`, `LocalRegAlloc`, or `GlobalRegAlloc`) — assigns registers
3. `SsaArm64Gen.assemble()` — converts abstract instructions to actual machine code via `Arm64Assembler`
4. `MachDataWriter.patchWithCallback()` — final patching of all Addr references

Key files:
- `aeneas/src/arm64/SsaArm64Gen.v3` — instruction selector + assembler
- `aeneas/src/arm64/Arm64Backend.v3` — frame management, entry stub, OS stubs
- `aeneas/src/arm64/Arm64Linux.v3` — Linux-specific backend (syscalls, target registration)
- `aeneas/src/arm64/Arm64RegSet.v3` — register allocation configuration
- `aeneas/src/arm64/Arm64AddrPatcher.v3` — address patching
- `lib/asm/arm64/Arm64Assembler.v3` — low-level instruction emitter
- `aeneas/src/mach/MachDataWriter.v3` — PatchKind enum and patch handler
- `aeneas/src/x86-64/SsaX86_64Gen.v3` — reference implementation (1816 lines)

## Implementation Plan

Work in this order. Each phase should be tested before starting the next.

---

### Phase 1: Fix register allocation basics

These two methods are called by the register allocator and must work before any non-trivial program can compile.

**1a. Fix `tryUseImm32` and immediate handling**

The current code uses `AM_R_R_I_I` addressing mode for ADD/SUB with a comment saying "imm32 is incorrect". ARM64 ADD/SUB immediates are 12-bit unsigned (0–4095) with an optional LSL#12. Fix:
- In `tryUseImm32`, for integers, only accept values fitting in u12 (0–4095) for ADD/SUB
- For larger immediates, fall through to register form
- Rename/document the function more clearly

**1b. Implement `genMoveLocLoc`**

This is called by the register allocator when it needs to move a value from one location to another (e.g., spilling, parallel move resolution).

In `assemble()`, add new opcodes:
```
I_MOVR = 0x50 (move GPR→GPR, 32-bit: MOV Wd, Wn / ORR Wd, WZR, Wn)
I_MOVRQ = 0x60 (move GPR→GPR, 64-bit: MOV Xd, Xn / ORR Xd, XZR, Xn)
```
In `genMoveLocLoc`:
- If src and dst are both GPRs: emit `MOV` (encoded as `ORR Xd, XZR, Xs`)
- If src is a stack slot and dst is a GPR: emit `LDR Xd, [SP, #offset]`
- If src is a GPR and dst is a stack slot: emit `STR Xs, [SP, #offset]`
- RegClass matters: I32 uses 32-bit forms (W registers), I64/REF use 64-bit forms (X registers)

Check how `SsaMachGen` (base class) encodes spill locations vs GPRs. The `loc` is either a physical register loc (< CALLER_SPILL_START) or a spill slot index. Use `MRegs.toGpr(loc)` to distinguish.

**1c. Implement `genMoveConstStack`**

Emit constant to stack slot. Load constant to scratch register (R16), then STR to stack.

Note: `genTestInputs` loads primitive integer values (test inputs are always primitives) via inline MOVZ+MOVK sequences, so the 32-bit address limit on the table pointer is acceptable for test binaries.

**Test after Phase 1:** Compile `test/core/add00.v3` with `v3c-dev -target=arm64-linux-test -output=/tmp add00.v3`. Run via Docker or native arm64.

---

### Phase 2: Integer arithmetic and comparisons

**2a. Add opcodes for all integer binary ops**

Add to SsaArm64Gen.v3:
```
I_MULD/MULQ  — MUL (for IntMul)
I_DIVD/DIVQ  — SDIV or UDIV (for IntDiv)
I_REMD/REMQ  — no native MOD; implement as SDIV/UDIV + MSUB
I_ANDD/ANDQ  — AND (for IntAnd, BoolAnd)
I_ORD/ORQ    — ORR (for IntOr, BoolOr)
I_XORD/XORQ  — EOR (for IntXor)
I_LSLD/LSLQ  — LSLV (for IntShl, variable shift)
I_ASRD/ASRQ  — ASRV (for IntSar)
I_LSRD/LSRQ  — LSRV (for IntShr)
I_NEGD/NEGQ  — NEG (for unary negate, needed for sub-with-zero)
```

For IntMod: emit `SDIV/UDIV Rtmp, Rn, Rm` then `MSUB Rd, Rtmp, Rm, Rn` (Rd = Rn - Rtmp * Rm).
This requires a temporary register; use a `newTmp`.

**2b. Add comparisons: CMP + CSET**

ARM64 comparisons:
- `CMP Rn, Rm` (sets condition flags)
- `CSET Rd, cond` (Rd = 1 if cond, else 0)

Add opcodes:
```
I_CMPD/CMPQ  — CMP (sets flags, no result register)
I_CSETD/CSETQ — CSET Rd, cond (condition encoded in arg)
```

Conditions to support: EQ, NE, LT (signed), LE (signed), LO (unsigned <), LS (unsigned <=), GT, GE, HI, HS.

For visitIf with a comparison input (like `if(a < b)`): instead of emitting a CSET + CBZ, emit `CMP` + `B.cond` directly. See how `SsaX86_64Gen.emitCmp` feeds into `visitIf`.

In `visitApply`:
- `IntEq` → CMP + CSET EQ
- `IntLt` (signed) → CMP + CSET LT; (unsigned) → CMP + CSET LO
- `IntLteq` (signed) → CMP + CSET LE; (unsigned) → CMP + CSET LS
- `BoolEq` → CMP + CSET EQ (byte compare)
- `BoolNot` → EOR Rd, Rs, #1
- `BoolAnd` → AND
- `BoolOr` → ORR
- `RefEq` → CMP + CSET EQ (64-bit)

In `visitIf`: check if the condition input is a comparison in the same block (like x86-64 does). If so, emit `CMP + B.cond` directly. Otherwise fall back to `CBZ/CBNZ`.

**2c. Add `visitSwitch`**

Implement switch/match:
- Emit CMP + B.cond for each case (linear search for small switch)
- For larger switches, a jump table via LDR+BR is more efficient but complex; start with linear

**2d. Add `visitThrow`**

Emit a `BL` to the appropriate fatal stub address (stored as a pool entry).

**Test after Phase 2:** Run `test/core/*.v3` with `TEST_TARGETS=arm64-linux AENEAS_TEST=v3c-dev`.

---

### Phase 3: Constant pool for address constants

This is needed before implementing calls and loads/stores, since both require loading 64-bit addresses (method addresses, record/global addresses).

**3a. Design: shared constant pool per code chunk**

The constant pool is a list of 8-byte entries (Addr values). A chunk is a contiguous region of code + pool, flushed when approaching 1MB (the ±1MB limit of 19-bit PC-relative LDR).

Key rule: every `LDR Xn, [PC, #offset]` must reach its pool entry (within ±1MB = 19-bit offset in 4-byte units). In practice, flush the pool before generating 800KB of code to leave margin.

**3b. Implementation in Arm64Backend / SsaArm64Gen**

Add a `Arm64ConstPool` class (or fields in `SsaArm64Gen`) that:
- Maintains a list of `(Addr, forward_patch_positions)` entries
- `addPoolEntry(addr: Addr) -> int` — adds `addr` to pool, returns an index
- `flushPool()` — emits pool entries inline and patches all forward LDR references
- Called at: end of each method (via `ARCH_END`), or periodically if a method is very large

For loading a pool entry in code:
```
LDR Xn, [PC, #offset]  ; ARM64_REL_IMM19 patch
```
This is a 32-bit instruction where bits [23:5] are the 19-bit signed offset in 4-byte units.

**3c. Add ARM64_REL_IMM19 handler in MachDataWriter.patchWithCallback**

The enum case already exists but falls through to error. Add:
```
ARM64_REL_IMM19 => {
    var offset = int.!((absAddr - posAddr) / 4);
    var old = read_b32(pos);
    put_b32((old & 0xFF00001F) | ((offset & 0x7FFFF) << 5));
}
```

The LDR literal encoding: bits [31:30] = size, [29:27] = 011, [26] = V, [25:24] = 00, [23:5] = imm19, [4:0] = Rt.

**3d. Add assembler support**

The assembler already has `ldrliteralq_r_i19` and `ldrliterald_r_i19`. Expose a marker-based version:
```
ldrq_pool(reg: Arm64Gpr, marker: i19) -> void  ; emits LDR Xn, [PC, #marker*4]
```
The patcher will fix up the marker. Or just use the existing `ldrliteralq_r_i19` with 0 and record a patch.

**3e. Update `genMoveConstReg` for Addr values**

Currently `genMoveConstReg` handles Box<int> and Box<long> via MOVZ+MOVK. For Addr values (Address<IrMethod>, Address<Record>):
- Add the Addr to the constant pool
- Emit `LDR Xn, [PC, #pool_offset]` with ARM64_REL_IMM19 patch

---

### Phase 4: Direct and indirect calls

**4a. Direct calls: CallAddress (static methods)**

For direct calls to known methods:
```
BL imm26   ; ARM64_REL_IMM26 patch
```
If the offset might exceed ±128MB (26-bit * 4), use the constant pool:
```
LDR X16, [PC, #pool_offset]  ; load address from pool
BLR X16                       ; indirect call
```
For now, use BL and `context.fail` if too far. Later, switch to pool+BLR when needed.

In `visitApply` for `CallAddress`:
- Use existing calling convention (Arm64VirgilCallConv): args in X0-X7, return in X0
- Emit parameter moves (handled by register allocator)
- Emit `BL target` or pool+BLR
- Kill caller-saved registers after the call (X0-X15)
- Use `refmap` to record the GC reference map for the call site

**4b. Indirect calls**

For virtual dispatch (CallClassVirtual) or closure calls (CallClosure):
```
LDR X16, [Xvtable, #method_offset]  ; load method pointer from vtable
BLR X16
```
Or if target is already in a register: just `BLR Xreg`.

**4c. CallerIp, CallerSp**

`CallerIp`: emit `BL next_instruction; LDR Xd, [SP, -8]` (or use `ADR Xd, next`). Actually on arm64, after a BL, the return address is in X30 (LR). But for CallerIp we need the instruction pointer — use `ADR Xd, .` at the call site.

`CallerSp`: `MOV Xd, SP`

**Test after Phase 4:** Run call-heavy tests in test/core.

---

### Phase 5: Load/Store operations

**5a. PtrLoad**

ARM64 load instructions by size:
- 1 byte unsigned: `LDRB Wd, [Xn, #offset]` (zero-extends to 32-bit)
- 1 byte signed: `LDRSB Xd, [Xn, #offset]` or `LDRSB Wd, [Xn, #offset]`
- 2 byte: `LDRH` / `LDRSH`
- 4 byte: `LDR Wd, [Xn, #offset]`
- 8 byte: `LDR Xd, [Xn, #offset]`
- 4 byte float: `LDR Sd, [Xn, #offset]`
- 8 byte float: `LDR Dd, [Xn, #offset]`

The assembler already has `ldrunsignedd/q` for unsigned offset forms. Use `i9` (signed) forms for negative offsets.

Pattern: `matchMrrsd(i.input0())` returns an addressing mode (base register + offset). Arm64 doesn't have the x86 MRRSD (base + reg*scale + disp) mode natively, so simplify:
- Use `[Xbase + #imm12*scale]` for constant offsets (most common case)
- Use `[Xbase + Xindex, LSL #scale]` for variable index (for array element access)

**5b. PtrStore**

Symmetric to PtrLoad. Use `STR`, `STRB`, `STRH`.

**5c. PtrAdd, PtrSub**

`ADD Xd, Xn, Xm` / `SUB Xd, Xn, Xm` (same as IntAdd/Sub but 64-bit).

**5d. Alloc**

If `mach.allocStub != null`: emit a call to the allocation stub (like x86-64: call with size in X1, returns object in X0).
Otherwise: emit `TEST_ALLOC` (no-op for test target).

**Test after Phase 5:** Run array/class tests in test/core. Try test/layout.

---

### Phase 6: Type conversions and views

These are mostly needed for cast/fsi32/fsi64 test suites.

**6a. IntViewI (integer reinterpret)**

Truncation/extension between integer types. No instruction needed for same-width or widening. For narrowing:
- Sub-32-bit to 32-bit unsigned: AND with mask
- Signed extension: use SBFX (signed bit field extract) or shift-shift (LSL then ASR)

See `SsaX86_64Gen.emitIntViewI` for the full logic.

**6b. IntViewB (bool to int)**

Extract bit field. Use UBFX for unsigned, SBFX for signed.

**6c. FloatViewI / IntViewF**

Move bits between GPR and FP registers:
- `FMOV Wd, Sn` / `FMOV Xd, Dn` (FP → GPR, bit reinterpret)
- `FMOV Sd, Wn` / `FMOV Dd, Xn` (GPR → FP, bit reinterpret)

**6d. FloatPromoteI, FloatRoundI (int-to-float conversions)**

- Signed int → float: `SCVTF Sd, Wn` / `SCVTF Dd, Xn`
- Unsigned int → float: `UCVTF Sd, Wn` / `UCVTF Dd, Xn`

**6e. IntCastF, IntTruncF (float-to-int conversions)**

- Float → signed int (with truncation): `FCVTZS Wd, Sn` / `FCVTZS Xd, Dn`
- Float → unsigned int (with truncation): `FCVTZU Wd, Sn` / `FCVTZU Xd, Dn`

**6f. FloatPromoteF (float32 → float64)**

`FCVT Dd, Sn`

**6g. FloatRoundD (float64 → float32)**

`FCVT Sd, Dn`

---

### Phase 7: Checks and throws

**7a. ConditionalThrow**

`ConditionalThrow(exception)` takes a boolean condition and throws if true.
In x86-64 this is done via `THROWC` (JCC to a throw stub). In arm64:
```
CBZ/CBNZ Rcond, skip_label
BL fatal_stub_addr
skip_label:
```
Or combine with the preceding CMP + B.cond if the condition is a comparison.

**7b. NullCheck**

Handled implicitly by SIGSEGV signal handler (dereferencing null raises SIGSEGV → NullCheck exception). The code generator just marks the load/store as a potential null check source.

For explicit null checks (`i.facts.O_NO_NULL_CHECK` is false), the approach is:
- Either rely on signal handler
- Or emit `CBZ Rptr, throw_null_check_stub`

In x86-64 with the signal handler approach, explicit checks are not emitted; the SIGSEGV handler catches it. For arm64-linux, same approach.

**7c. BoundsCheck**

`BoundsCheck`: compare index against length, throw if out of bounds.
```
CMP Rindex, Rlength
B.HS bounds_check_stub   ; HI-or-same = unsigned >=
```

---

### Phase 8: Floating point

**8a. FP register allocation**

Update `Arm64RegSet.v3`:
- Set `sfrCount = 8` (allocate V0-V7 for now; V8-V15 can be added later)
- Add SFR entries: V0 through V7 (all caller-save in Virgil's convention)
- Update `locToSfrArr` mapping
- Update `regClasses` to map F32 and F64 to the FP register set (not ALL)

Update `Arm64VirgilCallConv.v3`:
- `PARAM_SFRS = [R.V0, R.V1, ..., R.V7]` (FP parameter passing)
- `RET_SFRS = [R.V0]` (FP return value)
- Update `alloc()` to use SFRs for F32/F64 types

**8b. FP arithmetic opcodes in SsaArm64Gen**

```
I_FADDS/FADDD  — FADD Sd,Sn,Sm / FADD Dd,Dn,Dm
I_FSUBS/FSUBD  — FSUB
I_FMULS/FMULD  — FMUL
I_FDIVS/FDIVD  — FDIV
I_FSQRTS/FSQRTD — FSQRT
I_FABSS/FABSD  — FABS
I_FNEGS/FNEGD  — FNEG
```

Rounding modes (FRINTN, FRINTP, FRINTM, FRINTZ) for FloatCeil/Floor/Round.

**8c. FP comparisons**

```
FCMP Sn, Sm (or FCMP Dn, Dm) — sets FP condition flags
CSET Rd, EQ / MI / LO / LS etc.
```

Note: ARM64 FP comparisons use different flag bits from integer comparisons. After FCMP:
- EQ: both equal and neither is NaN
- NE: not equal or one is NaN
- Unordered check: after FCMP, VS condition is set if either operand is NaN

For FloatEq: FCMP + CSET EQ (NaN inputs → not equal, which is correct Virgil semantics)
For FloatNe: FCMP + CSET NE
For FloatLt: FCMP + CSET MI (minus flag)
For FloatLteq: FCMP + CSET LS

**8d. genMoveLocLoc for FP registers**

- FP→FP: `FMOV Sd, Sn` / `FMOV Dd, Dn`
- Stack spill: `STR Sd, [SP, #offset]` / `LDR Sd, [SP, #offset]`

---

### Phase 9: Runtime (rt/arm64-linux/)

Create `rt/arm64-linux/` with:
- `DEPS` — list the source files
- `LinuxConst.v3` — Linux arm64 syscall numbers (from `<asm/unistd.h>`)
- `RiOs.v3` — OS interface: `syscall`, signal handler installation, etc.
- `System.v3` — System class (file I/O, etc.)

**Key differences from x86-64-linux:**

Linux syscall ABI on arm64:
- Syscall number: x8 (not rax)
- Parameters: x0–x5 (not rdi, rsi, rdx, r10, r8, r9)
- Return value: x0 (same as x86-64 rax)
- Instruction: `SVC #0` (not SYSCALL)

Most syscall numbers differ between arm64 and x86-64; use arm64-specific numbers from the kernel headers.

The arm64 syscall numbers relevant for Virgil runtime:
- `sys_exit` = 93 (not 60)
- `sys_exit_group` = 94
- `sys_write` = 64 (not 1)
- `sys_read` = 63 (not 0)
- `sys_mmap` = 222 (not 9)
- `sys_munmap` = 215 (not 11)
- `sys_brk` = 214 (not 12)
- `sys_sigaction` / `sys_rt_sigaction` = 134
- `sys_open` = 1024 (openat = 56)
- `sys_close` = 57
- `sys_fstat` = 80

Port `Linux.syscall` to use arm64 register convention. Check the x86-64-linux RiOs.v3 for what needs porting.

**Signal handler:**

The arm64 Linux signal handler receives `(signo, siginfo, ucontext)` in x0, x1, x2.
The `ucontext` struct layout differs from x86-64 but the principle is the same.

For `genSignalHandlerStub` (minimal implementation):
- On SIGSEGV: write NullCheck exception to stdout, exit with code 1
- On SIGFPE: write DivideByZero exception, exit with code 1
- Use sigaction to install (call `genSigHandlerInstall`)

**Stack walker (for GC and stack traces):**

The runtime uses a PC-indexed side-table of frame sizes for stack walking (not the standard arm64 X29 frame pointer chain). This means X29 does not need to be saved in function prologues.

The runtime looks up the frame size from this table by PC to walk the stack one frame at a time. The same approach is used on x86-64-linux. The side-table is populated by `rtsrc.recordMethodStart` and `rtsrc.recordFrameEnd` calls in `genCodeFromSsa`, which are already present in `Arm64Backend`.

Defer full GC stack walking validation to after basic test/core passes. The GC test suite (`test/gc`) is a later milestone.

---

### Phase 10: Backend stubs and polish

**10a. `asm_exit_r`**

Exit with the value in a register:
```
MOV X8, #93         // sys_exit_group
// X0 already has the exit code
SVC #0
```

**10b. `genFatalStub`**

For each fatal exception (NullCheck, BoundsCheck, DivideByZero):
1. Generate a stub that writes the exception string to stderr (sys_write fd=2)
2. Call sys_exit_group with exit code 1
3. Bind the stub's Addr

**10c. `genSigHandlerInstall`**

Generate code that calls `rt_sigaction` to install the signal handler stub for the given signal number.

---

## Testing Strategy

**Single test (fast iteration with v3c-dev):**
```bash
v3c-dev -target=arm64-linux-test -output=/tmp test/core/add00.v3
# Then run on arm64 (Docker or native):
# docker run --rm -v /tmp:/tmp arm64v8/ubuntu /tmp/add00
```

**Test suite (use bootstrap for speed):**
```bash
# After making compiler changes:
make bootstrap

# Run specific suite with arm64-linux target:
cd test/core && TEST_TARGETS=arm64-linux ./test.bash

# Or with docker runner:
cd test/core && TEST_TARGETS=arm64-linux AENEAS_TEST=current ./test.bash
```

**Progress order for test suites:**
1. `test/core` — integer arithmetic, variables, control flow, calls, classes
2. `test/cast` — integer and float casts
3. `test/fsi32` — 32-bit integer edge cases
4. `test/fsi64` — 64-bit integer edge cases
5. `test/variants` — ADTs
6. `test/enums` — enums
7. `test/float` — floating point arithmetic
8. `test/layout` — struct/record layout
9. `test/large` — large programs
10. `test/gc` — garbage collector (requires full runtime)
11. `test/stacktrace` — stack traces (requires stack walker)

**Diagnosing failures:**
```bash
# See SSA for a failing method:
v3c-dev -target=arm64-linux-test -print-ssa=MyClass.myMethod output=/tmp foo.v3

# See machine code:
v3c-dev -target=arm64-linux-test -print-mach=MyClass.myMethod -output=/tmp foo.v3

# See binary + addresses:
v3c-dev -target=arm64-linux-test -print-bin -output=/tmp foo.v3

# Disassemble the output:
objdump -d /tmp/foo
```

For debugging miscompilation, inject `asm.udf()` (undefined instruction → SIGILL) at suspected locations to test whether code reaches a given point.

---

## Key Design Decisions (Summary)

**Constant pool:** Shared pool per 1-2MB chunk. Load via `LDR Xn, [PC, #offset]` (19-bit signed offset in 4-byte units = ±1MB range). Pool entries are 8-byte Addr values. Pool is flushed at ARCH_END (end of method) and whenever the code position approaches 800KB into a chunk. ARM64_REL_IMM19 patch kind in MachDataWriter handles the final patching.

**Calls:** Direct calls use `BL imm26` (REL_IMM26 patch); `context.fail` if offset > 128MB. Later, use constant pool + BLR for very large binaries.

**Immediate operands for ADD/SUB:** ARM64 supports 12-bit unsigned immediate (0–4095) with optional LSL#12 shift. Larger immediates require a register move first. Fix `tryUseImm32` to reflect this.

**FP register allocation:** Add V0-V7 to allocatable SFRs. All registers are caller-save in Virgil's convention, so no save/restore needed. V8-V15 can be added later. F32 and F64 reg classes map to the FP register set.

**Signal handlers:** Minimal approach — SIGSEGV → NullCheck, SIGFPE → DivideByZero. Write exception string to stderr, exit 1.

**Runtime:** Adapt x86-64-linux runtime, updating syscall numbers and register conventions for arm64 Linux.

**arm64-darwin:** Deferred. Will reuse the same backend with a new `Arm64DarwinBackend`. Darwin differences: Mach-O file format (already supported), different syscall convention (inline syscalls differ), different signal handler format.

---

## Calling Convention Notes

Virgil's arm64 calling convention deliberately deviates from the System-V ARM64 ABI:
- **All registers are caller-save.** No callee-save save/restore is needed in prologues or epilogues. The register allocator can freely use any register.
- **Stack walking** uses a PC-indexed side-table of frame sizes, not the X29 frame pointer chain. X29 and X30 do not need to be saved.

This is consistent with the other Virgil native backends (x86-64, x86).

The system ABI still applies at the boundary with the OS: `CallKernel` (syscalls) uses x0–x5 for args and x8 for syscall number; signal handlers receive arguments in x0–x2 per the OS ABI.

**Frame pointer (`-fp` flag):** When the `-fp` compiler option is enabled, the backend should save `{X29, X30}` at frame entry and restore them at exit (standard arm64 frame record). Without `-fp`, no frame pointer is saved — the runtime's PC-indexed side-table handles stack walking. The `-fp` path is useful for gdb unwinding and future stack-allocated data structures.

## Open Issues / Questions

1. **Patching design (cross-backend):** The three backends (x86, x86-64, arm64) each record patches differently. `Arm64AddrPatcher` is a redundant layer: `MachDataWriter.patchWithCallback` already handles ARM64_REL_IMM26 and ARM64_ABS_IMM16. The right long-term fix is a unified patch-recording design across all assemblers, but this is a cross-cutting refactor that should be done separately and not block the arm64 port. For now, leave `Arm64AddrPatcher` in place; keep it in mind when the unified patching design is undertaken.

2. **Spill slot encoding:** `CALLER_SPILL_START = 100000000` and `CALLEE_SPILL_START = 200000000` are large numbers. Verify these don't interfere with the 31-bit limit comment in `Arm64RegSet`. The spill slot → stack offset calculation needs to be verified.

3. **Frame pointer (`-fp` compiler option):** A `-fp` compiler flag enables saving/restoring X29 (frame pointer) and X30 (link register) in function prologues/epilogues. When enabled, the standard arm64 frame record `{X29, X30}` is pushed at entry. This is useful for gdb stack unwinding and will be needed for future stack-allocated data structures. The runtime's PC-indexed side-table approach works without `-fp`; the flag is additive. Implement the `-fp` prologue/epilogue in `Arm64Backend` as a separate, optional path controlled by the flag.
