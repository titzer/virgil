# ARM64: Floating point register allocation

Status as of 2026-07-21. All work below is **in the working tree, uncommitted**.
See `tasks/Port-arm64.md` for the overall port and `tasks/Port-arm64-progress.md`
for the port's checkpoint list.

## Goal

The arm64 backend never allocated floating point registers: `Arm64RegSet.sfrCount`
was 0, `RegClass.F32`/`F64` mapped to the GPR set, so floats lived in general
purpose registers and every FP operation was `FMOV` into a hardcoded V0/V1,
compute, `FMOV` back. The calling convention passed and returned floats in x0-x7.

Make the register allocator use V0-V30 as a real register class, and follow the
System-V model for internal calls (independent integer and float argument queues),
as x86-64 does.

## What is done

### Floating point register class and calling convention

`aeneas/src/arm64/Arm64RegSet.v3`

- V0-V30 are allocatable as `SFR_CLASS`; V31 is the FP parallel-move scratch
  (`regSet.scratch[F32/F64]`). Non-argument registers are listed first in both
  class sets, because `MoveSet.getParallelMoveReg` uses elements `[0]` and `[1]`
  of the class as parallel-move temps.
- `ALL` = GPR class + SFR class, so a call kills both register files.
- Reserved GPRs: R16 scratch, R17 BLR target, **R18 new**: materializes float
  constants and shuffles float stack→stack moves. It must not be R16: R16 can be
  holding a cycle value in the middle of a parallel move.
- `Arm64VirgilCallConv`: `PARAM_SFRS` = V0-V7, `RET_SFRS` = V0, with independent
  `iprm`/`fprm` queues in `alloc()`; overflow goes to stack slots.
- `RESERVED = unalloc(...)` placeholder at location `physRegs`. `MachRegSet.isReg()`
  treats `loc <= physRegs` as a register, so without the placeholder the first
  register *set* is mistaken for a physical register and the global allocator
  indexes past its color arrays. (x86-64 has the same latent hazard.)

### Code generation

`aeneas/src/arm64/SsaArm64Gen.v3`

- New addressing modes `AM_V_V_V`, `AM_V_V`, `AM_R_V_V`, `AM_R_V`, `AM_V_R`,
  `AM_V_OP`, `AM_OP_V`, `AM_V_IMM`; new opcodes `I_FLOATBITEQ`, `I_FMOVS`,
  `I_FMOVD`, `I_FCONST`; new memory size args `ARG_FS`/`ARG_FD`.
- FP ops now read and write V registers directly: FADD/FSUB/FMUL/FDIV,
  FSQRT/FABS/FRINT*, FCMP+CSET, FCVT, SCVTF/UCVTF, FCVTZS/FCVTZU, and cross-file
  FMOV for `FloatViewI`/`IntViewF`. `FloatBitEq` compares raw bits through R16/R17.
- Float spill/restore, float stack moves, float constants (`genMoveConstReg`,
  `genMoveConstStack`, `genMoveLocLocFloat`), and float-typed `PtrLoad`/`PtrStore`
  (float fields used to be loaded into GPRs).
- Float memory traffic always uses the **64-bit** LDR/STR D-form, even for F32:
  slots are 8 bytes, the round-trip is exact, and the scaled 32-bit offset only
  reaches 16380 instead of 32760.
- `use()` → `useReg()` for every operand that the assembler needs in a register.
  Only the `AM_R_OP`/`AM_OP_R` move forms tolerate a spill slot. This is what the
  global allocator tripped over ("expected GPR, got spill#N").

`lib/asm/arm64/Arm64Assembler.v3` — added FP load/store: `fldrs/fldrd/fstrs/fstrd`
(scaled) and `fldurs/fldurd/fsturs/fsturd` (unscaled). Encodings are covered by
`test/asm/arm64` (diffed against the system assembler); the test generator was
extended in `test/asm/arm64/Arm64AssemblerTestGen.v3`.

### Shared register allocator fixes (affect x86-64 too)

`aeneas/src/mach/GlobalRegAlloc.v3`

- `addInterferencesFromConstraints` walked the constraint set and the register
  class as two sorted lists. arm64's class sets are ordered non-argument-first, so
  it invented interference edges and coloring failed with "nothing available to
  spill". It now tests membership with `MachRegSet.isInRegSet` (order independent;
  identical result for sorted sets, so x86-64 is unaffected).
- `emitParMoves` sent every parallel-move destination to the variable's colored
  register, so stack-located return values were never written to the caller's
  frame (symptom: `core/big_ret*` returned garbage). It now honours `vreg.spill`
  when that is a caller-frame slot.

`aeneas/src/mach/MachBackend.v3`

- `visitReturn` emits its ARCH_PARMOVE only when a stack return slot actually
  aliases a parameter slot. HEAD emitted it for *every* stack return, which
  regressed x86-64 `-O2` on `core/big_ret00`/`big_ret03` (verified: those pass at
  cee4afd51, fail at HEAD, pass again with this change).

### New tests

- `test/float/fp_regalloc0{0..3}.v3` — spilling under FP pressure, float arguments
  beyond V0-V7, a parallel-move cycle between double arguments, float32 pressure
  with heap fields.
- `test/regalloc/pressure_{int,float,mixed}00.v3` — register pressure that forces
  operands into spill slots for each class, and across a call that clobbers both
  files.
- `test/regalloc/pressure_ret00.v3` — multi-value returns in caller-frame slots,
  including a callee whose return slots alias its parameter slots.

Each new test was verified to fail with the corresponding fix reverted:
reverting the `GlobalRegAlloc` interference fix or the `use()`→`useReg()` fix
each makes one of the pressure tests fail to compile; at HEAD all three crash the
global allocator outright.

## Test status

Passing:

- `test/asm/arm64` (assembler encodings diffed against `as`).
- arm64-linux, **default flags**, full sweep: unit asm/arm64 core regalloc cast
  variants enums fsi32 fsi64 float range layout funexpr readonly large rt
  stacktrace gc system link apps bench — 119 groups, 0 failures.
- arm64-linux, **`V3C_OPTS=-O2`** (implies global register allocation), same
  sweep — 119 groups, 0 failures. (Ran before the final `hasStackRet` →
  `aliasedStackRet` rename, which is a pure rename.)
- x86-64-darwin, default and `-O2`: core, cast, variants, float, regalloc, enums,
  range, layout, large, fsi32, fsi64 — all pass except `float/fp_callconv01` at
  `-O2`, which also fails at cee4afd51 (pre-existing, unrelated, still open).
- v3i and jvm: regalloc and float suites, default and `-O2`.

Known pre-existing failures, unrelated to this work:

- `lib` suite on arm64-linux ("System redefined" source-set problem).
- `vmaddr` suite at `-vm-start-addr=0x00911000` (ELF writer `ClassCastException`).
  `test/all.bash` stops there, so later suites must be named explicitly.
- `float/fp_callconv01` on x86-64 at `-O2` ("nothing available to spill").

## What is left

1. **Re-run the final verification sweep.** The last rebuild (the
   `aliasedStackRet` rename) was verified only on the default-flag arm64 sweep
   (core float regalloc cast variants large rt gc stacktrace system apps bench,
   64 groups, 0 failures); the `-O2` re-run was interrupted. Re-run:
   ```bash
   V3C_OPTS=-O2 PROGRESS_ARGS=s TEST_TARGETS=arm64-linux ./test/all.bash \
     core float regalloc cast variants large rt gc stacktrace system apps bench
   ```
   Never run two `test/all.bash` sweeps concurrently — they share
   `/tmp/$USER/virgil-test/<suite>/` and the second reports mass
   "not executable" failures that look like a compiler bug.
2. **Commit.** Nothing is committed yet. Suggested split: (a) assembler + FP
   register class + codegen + float tests, (b) shared allocator fixes +
   `test/regalloc` pressure tests, since (b) fixes an x86-64 `-O2` regression.
3. Optional follow-ups: `float/fp_callconv01` at `-O2` on x86-64; the `lib` and
   `vmaddr` suite failures; `main(a: int)` argv marshalling on arm64 (garbage
   argument, hidden by the `-test` target embedding inputs).

## Recovery

If the working tree is reset, the full diff and the new tests are saved at:

- `<scratchpad>/fp-regalloc.patch` (`git apply` it)
- `<scratchpad>/new-tests.tgz` (untracked test files, extract at the repo root)

where `<scratchpad>` is
`/private/tmp/claude-501/-Users-titzer-Code-claude-arm64-port-virgil/facee146-9726-488f-a566-2717e2b60c51/scratchpad`.
Rebuild with `make bootstrap` after applying.
