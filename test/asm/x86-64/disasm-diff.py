#!/usr/bin/env python3
# Copyright 2024 Virgil authors. All rights reserved.
# See LICENSE for details of Apache 2.0 license.
#
# Differential test for lib/asm/x86-64/X86_64Disassembler.v3.
#
# Reads the output of X86_64DisassemblerDump.v3 (one instruction per fixed-size
# slot, together with this disassembler's rendering), reconstructs the raw byte
# blob, runs it through two independent disassemblers -- GNU binutils objdump and
# NASM's ndisasm -- and reports every place where the three disagree about either
# the length or the meaning of an instruction.
#
# The three tools print in different dialects, so both sides are reduced to a
# canonical form before comparison: size keywords are unified, integers are
# compared by value (allowing for signed/unsigned rendering of the same bits),
# and mnemonic aliases that denote the same encoding are folded together.

import argparse, os, re, subprocess, sys, tempfile

SLOT = 16

# ---------------------------------------------------------------------------
# Reading our own dump
# ---------------------------------------------------------------------------

class Insn:
    __slots__ = ('off', 'length', 'raw', 'text')
    def __init__(self, off, length, raw, text):
        self.off, self.length, self.raw, self.text = off, length, raw, text

def read_dump(path):
    insns = []
    with open(path) as f:
        for line in f:
            parts = line.rstrip('\n').split(' ', 3)
            if len(parts) < 3:
                continue
            try:
                off = int(parts[0], 16)
                length = int(parts[1])
            except ValueError:
                continue
            raw = bytes.fromhex(parts[2])
            text = parts[3] if len(parts) > 3 else ''
            insns.append(Insn(off, length, raw, text))
    return insns

# ---------------------------------------------------------------------------
# Canonicalization
# ---------------------------------------------------------------------------

PTR_SIZES = [
    ('xmmword ptr', 'oword'), ('ymmword ptr', 'yword'), ('tbyte ptr', 'tword'),
    ('qword ptr', 'qword'), ('dword ptr', 'dword'), ('fword ptr', 'fword'),
    ('word ptr', 'word'), ('byte ptr', 'byte'), ('oword ptr', 'oword'),
]

SEG_RE = re.compile(r'\b(cs|ds|es|ss|fs|gs):')
NUM_RE = re.compile(r'-?\b0x[0-9a-f]+\b|-?\b\d+\b')

# Mnemonics that denote the same encoding in different dialects. Everything is
# mapped to the name this disassembler prints.
ALIASES = {
    # 0xCC: binutils gives it a distinct mnemonic; handled specially below.
    'repz': 'rep', 'repnz': 'repne',
    'retq': 'ret', 'retf': 'retf', 'leaveq': 'leave', 'iretq': 'iret',
    'callq': 'call', 'jmpq': 'jmp', 'pushq': 'push', 'popq': 'pop',
    'cltd': 'cdq', 'cqto': 'cqo', 'cwtl': 'cwde', 'cltq': 'cdqe',
    'movsxd': 'movsxd', 'movslq': 'movsxd',
    'setna': 'setbe', 'setnae': 'setb', 'setnb': 'setae', 'setnbe': 'seta',
    'setc': 'setb', 'setnc': 'setae', 'setz': 'sete', 'setnz': 'setne',
    'setng': 'setle', 'setnge': 'setl', 'setnl': 'setge', 'setnle': 'setg',
    'setpe': 'setp', 'setpo': 'setnp',
    'jna': 'jbe', 'jnae': 'jb', 'jnb': 'jae', 'jnbe': 'ja', 'jc': 'jb',
    'jnc': 'jae', 'jz': 'je', 'jnz': 'jne', 'jng': 'jle', 'jnge': 'jl',
    'jnl': 'jge', 'jnle': 'jg', 'jpe': 'jp', 'jpo': 'jnp',
    'cmovna': 'cmovbe', 'cmovnae': 'cmovb', 'cmovnb': 'cmovae',
    'cmovnbe': 'cmova', 'cmovc': 'cmovb', 'cmovnc': 'cmovae',
    'cmovz': 'cmove', 'cmovnz': 'cmovne', 'cmovng': 'cmovle',
    'cmovnge': 'cmovl', 'cmovnl': 'cmovge', 'cmovnle': 'cmovg',
    'cmovpe': 'cmovp', 'cmovpo': 'cmovnp',
    'sal': 'shl',
    'sysexitd': 'sysexit', 'sysexitq': 'sysexit', 'sysretd': 'sysret', 'sysretq': 'sysret',
    'xlat': 'xlatb',
    'fwait': 'fwait', 'wait': 'fwait',
    'movabs': 'mov',        # NASM does not distinguish the imm64 form of mov
    'ud2a': 'ud2',
    'loopne': 'loopne', 'loopnz': 'loopne', 'loope': 'loope', 'loopz': 'loope',
    'pushf': 'pushfq', 'pushfw': 'pushfq', 'popf': 'popfq', 'popfw': 'popfq',
    'pushw': 'push', 'popw': 'pop', 'retw': 'ret', 'retfw': 'retf', 'retfq': 'retf',

    'nopw': 'nop', 'nopl': 'nop', 'nopq': 'nop',
    'fnstsw': 'fnstsw', 'fstsw': 'fnstsw',
    'fnclex': 'fnclex', 'fclex': 'fnclex',
    'fninit': 'fninit', 'finit': 'fninit',
    'fnstcw': 'fnstcw', 'fstcw': 'fnstcw',
    'fnstenv': 'fnstenv', 'fstenv': 'fnstenv',
    'fnsave': 'fnsave', 'fsave': 'fnsave',
    'fxsave64': 'fxsave', 'fxrstor64': 'fxrstor',
    'xsave64': 'xsave', 'xrstor64': 'xrstor', 'xsaveopt64': 'xsaveopt',
    'jpo': 'jnp', 'jpe': 'jp', 'setnc': 'setae', 'hint_nop48': 'nop',
    'enterw': 'enter', 'enterq': 'enter', 'jmpw': 'jmp', 'callw': 'call',
    'xrstors64': 'xrstors', 'xsaves64': 'xsaves', 'xsavec64': 'xsavec',
    'lcall': 'callf', 'ljmp': 'jmpf',
    'leavew': 'leave', 'leaveq': 'leave', 'wait': 'fwait',
}

# NASM's names for the reserved multi-byte nop encodings of 0F 18-0F 1F.
HINT_NOP_RE = re.compile(r'^hint_nop\d+$')

# binutils writes an indirect far call/jump as "call FWORD PTR"; NASM writes
# "call far". Both are the /3 and /5 forms of group 5.
FAR_RE = re.compile(r'^(call|jmp)f?$')

# Branch targets wrap to the operand size, so binutils and this disassembler may
# print the same target modulo 2**16 or 2**32.
BRANCHES_RE = re.compile(r'^(j[a-z]+|call|loop(ne|e)?|xbegin)$')

# Prefix words that may appear ahead of the mnemonic and that carry meaning.
PREFIX_WORDS = {'lock', 'rep', 'repe', 'repz', 'repne', 'repnz', 'bnd',
                'xacquire', 'xrelease',
                'cs', 'ds', 'es', 'ss', 'fs', 'gs'}

# Prefix bytes that have no effect on the instruction they precede. binutils prints
# them; this disassembler folds them into the instruction silently.
IGNORED_PREFIX_RE = re.compile(
    r'^(rex(\.[bwrx]+)?|data16|addr32|notrack|o16|o32|o64|a16|a32|a64)$')

def is_prefix_only(text):
    """True if binutils rendered a run of prefix bytes with no opcode."""
    words = strip_comment(text).strip().lower().split()
    return bool(words) and all(
        w in PREFIX_WORDS or IGNORED_PREFIX_RE.match(w) for w in words)

def strip_comment(s):
    for c in ('#', ';'):
        i = s.find(c)
        if i >= 0:
            s = s[:i]
    return s

def canon(text, target_base=None):
    """Reduce one rendered instruction to a comparable canonical form.

    Returns (prefixes, mnemonic, [operands]) or None when the text denotes an
    invalid or unrecognized encoding."""
    s = strip_comment(text).strip().lower()
    if not s:
        return None
    if ('(bad)' in s or s.startswith('bad') or 'unsupported' in s
            or s == 'db' or s.startswith('db ')):
        return None
    s = s.replace('\t', ' ')
    for a, b in PTR_SIZES:
        s = s.replace(a, b)
    # NASM writes memory sizes without "ptr" already; unify the 128-bit spelling.
    s = re.sub(r'\bxmmword\b', 'oword', s)

    # Segment overrides: "fs:[rax]" -> prefix "fs" + "[rax]"; "ds:0x10" -> "[0x10]".
    segs = []
    def seg_sub(m):
        segs.append(m.group(1))
        return ''
    # An absolute address written as "seg:0x..." needs brackets added.
    s = re.sub(r'\b(cs|ds|es|ss|fs|gs):(-?0x[0-9a-f]+)\b',
               lambda m: (segs.append(m.group(1)) or '') + '[' + m.group(2) + ']', s)
    s = SEG_RE.sub(seg_sub, s)

    words = s.split(None, 1)
    prefixes = []
    while words and (words[0] in PREFIX_WORDS or IGNORED_PREFIX_RE.match(words[0])):
        w = words[0]
        if IGNORED_PREFIX_RE.match(w):
            rest = words[1] if len(words) > 1 else ''
            words = rest.split(None, 1)
            continue
        prefixes.append({'repe': 'rep', 'repz': 'rep', 'repnz': 'repne',
                         'bnd': 'repne', 'xacquire': 'repne',
                         'xrelease': 'rep'}.get(w, w))
        rest = words[1] if len(words) > 1 else ''
        words = rest.split(None, 1)
    if not words:
        return None
    mnem = ALIASES.get(words[0], words[0])
    if HINT_NOP_RE.match(mnem):
        mnem = 'nop'
    rest = words[1] if len(words) > 1 else ''

    prefixes.extend(segs)
    # "fs" as an operand-position prefix and as a leading word are the same thing.
    prefixes = sorted(set(prefixes) - {'ds', 'cs', 'ss', 'es'})

    ops = [o.strip() for o in rest.split(',')] if rest.strip() else []

    # binutils renders the implicit operands of the string instructions and puts the
    # width in an operand; NASM (and this disassembler) put it in the mnemonic.
    if FAR_RE.match(mnem) and ('fword' in rest or 'tword' in rest or 'far' in rest):
        mnem += 'f' if not mnem.endswith('f') else ''
        rest = rest.replace('far', '').strip()
    if mnem == 'int3':                  # binutils spells 0xCC without an operand
        mnem, ops = 'int', ['3']
    if mnem in ('xlat', 'xlatb'):
        mnem, ops = 'xlatb', []
    # The SSE4.1 variable blends take an implicit xmm0 that binutils spells out.
    if mnem in ('pblendvb', 'blendvps', 'blendvpd') and len(ops) == 3 and ops[2] == 'xmm0':
        ops = ops[:2]
    if mnem in STRING_OPS and ops:
        for w in ('byte', 'word', 'dword', 'qword'):
            if any(o.lower().startswith(w) for o in ops):
                mnem += {'byte': 'b', 'word': 'w', 'dword': 'd', 'qword': 'q'}[w]
                ops = []
                break

    ops = [normalize_operand(o, target_base) for o in ops]

    # pinsrb/pinsrw take r32/m8 and r32/m16 in the Intel manual and in binutils;
    # NASM prints the register at the width actually inserted. Compare by register
    # number so that both spellings agree.
    if mnem in ('pinsrb', 'pinsrw'):
        ops = [regnum(o) for o in ops]
    return (tuple(prefixes), mnem, ops)

STRING_OPS = {'movs', 'cmps', 'stos', 'lods', 'scas', 'ins', 'outs'}

GPR_NAMES = {}
for _i, _row in enumerate([
        ('al', 'ax', 'eax', 'rax'), ('cl', 'cx', 'ecx', 'rcx'),
        ('dl', 'dx', 'edx', 'rdx'), ('bl', 'bx', 'ebx', 'rbx'),
        ('spl', 'sp', 'esp', 'rsp'), ('bpl', 'bp', 'ebp', 'rbp'),
        ('sil', 'si', 'esi', 'rsi'), ('dil', 'di', 'edi', 'rdi')]):
    for _n in _row:
        GPR_NAMES[_n] = _i
for _i in range(8, 16):
    for _sfx in ('b', 'w', 'd', ''):
        GPR_NAMES['r%d%s' % (_i, _sfx)] = _i

def regnum(op):
    if isinstance(op, tuple) and len(op) == 1 and isinstance(op[0], str):
        n = GPR_NAMES.get(op[0])
        if n is not None:
            return ('reg', n)
    return op

def normalize_operand(op, target_base):
    op = op.replace(' ', '')
    op = op.replace('%', '')            # AT&T register sigil, if it leaks through
    # "st(3)" (objdump/NASM) and "st3" (ours) name the same x87 register.
    op = re.sub(r'\bst\((\d)\)', r'st\1', op)
    if op == 'st':
        op = 'st0'
    # "$-5" is our relative-branch notation; convert to an absolute target.
    if op.startswith('$') and target_base is not None:
        return ('int', target_base + int(op[1:]))
    # An explicit size keyword is carried alongside rather than inside the operand,
    # because the three tools disagree about when it is redundant.
    for w in SIZE_WORDS:
        if op.startswith(w) and re.match(r'^[-+\[0-9]|^$', op[len(w):]):
            op = op[len(w):]
            break
    # NASM writes a RIP-relative address as its absolute target: "[rel 0x1234]".
    m = re.fullmatch(r'\[rel(-?(0x[0-9a-f]+|\d+))\]', op)
    if m and target_base is not None:
        op = '[rip+%d]' % (parse_int(m.group(1)) - target_base)
    # A zero displacement and a scale of one are implicit in some dialects.
    op = re.sub(r'\+0x0(?=\])', '', op)
    op = re.sub(r'\+0(?=\])', '', op)
    op = op.replace('*1', '')
    if op.startswith('+'):              # NASM writes "byte +0x7f" for a small immediate
        op = op[1:]
    if NUM_RE.fullmatch(op):
        return ('int', parse_int(op))
    # split into pieces so that embedded numbers compare by value
    parts = []
    pos = 0
    for m in NUM_RE.finditer(op):
        parts.append(op[pos:m.start()])
        parts.append(('int', parse_int(m.group(0))))
        pos = m.end()
    parts.append(op[pos:])
    return tuple(p for p in parts if p != '')

def parse_int(t):
    neg = t.startswith('-')
    if neg:
        t = t[1:]
    v = int(t, 16) if t.startswith('0x') else int(t, 10)
    return -v if neg else v

def fits(v, w):
    return -(1 << (w - 1)) <= v < (1 << w)

def int_eq(a, b):
    if a == b:
        return True
    for w in (8, 16, 32, 64):
        if fits(a, w) and fits(b, w) and (a - b) % (1 << w) == 0:
            return True
    return False

def part_eq(a, b):
    if isinstance(a, tuple) and isinstance(b, tuple):
        if len(a) == 2 and a[0] == 'int' and len(b) == 2 and b[0] == 'int':
            return int_eq(a[1], b[1])
        return len(a) == len(b) and all(part_eq(x, y) for x, y in zip(a, b))
    return a == b

# The operands of these instructions are rendered in either order depending on
# the dialect; both spellings denote the same encoding.
COMMUTATIVE = {'xchg', 'test'}

def same(x, y):
    """Compare two canonical forms."""
    if x is None or y is None:
        return x is None and y is None
    (xp, xm, xo), (yp, ym, yo) = x, y
    if xm != ym or len(xo) != len(yo) or xp != yp:
        return False
    if all(part_eq(a, b) for a, b in zip(xo, yo)):
        return True
    if BRANCHES_RE.match(xm) and len(xo) == 1:
        a, b = xo[0], yo[0]
        if (isinstance(a, tuple) and a[:1] == ('int',)
                and isinstance(b, tuple) and b[:1] == ('int',)):
            return any((a[1] - b[1]) % (1 << w) == 0 for w in (16, 32, 64))
    if xm in COMMUTATIVE and len(xo) == 2:
        return part_eq(xo[0], yo[1]) and part_eq(xo[1], yo[0])
    return False

SIZE_WORDS = ('xmmword', 'ymmword', 'oword', 'tword', 'tbyte', 'qword', 'dword',
              'fword', 'word', 'byte',
              # NASM branch-distance hints, which carry no extra information
              'near', 'short', 'far')

# ---------------------------------------------------------------------------
# External disassemblers
# ---------------------------------------------------------------------------

OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')

def run_objdump(blob_path, tool):
    out = subprocess.run(
        [tool, '-D', '-b', 'binary', '-m', 'i386:x86-64', '-Mintel', blob_path],
        capture_output=True, text=True, check=True).stdout
    res = {}
    prev = None
    carry = None
    for line in out.splitlines():
        m = OBJDUMP_RE.match(line)
        if not m:
            continue
        off = int(m.group(1), 16)
        nbytes = len(m.group(2).split())
        text = m.group(3).strip()
        if not text and prev is not None:
            # objdump wraps encodings longer than seven bytes onto a bare
            # continuation line; those bytes belong to the preceding instruction.
            n, t = res[prev]
            res[prev] = (n + nbytes, t)
            continue
        if is_prefix_only(text):
            # A run of prefix bytes that binutils could not attach to an opcode,
            # because a later prefix cancelled it. It belongs to whatever follows.
            if carry is None:
                carry = (off, nbytes, text)
            else:
                carry = (carry[0], carry[1] + nbytes, carry[2] + ' ' + text)
            continue
        if carry is not None:
            off, nbytes, text = carry[0], carry[1] + nbytes, carry[2] + ' ' + text
            carry = None
        res[off] = (nbytes, text)
        prev = off
    return res

NDISASM_RE = re.compile(r'^([0-9A-F]+)\s+([0-9A-Fa-f]+)\s+(.*)$')

def run_ndisasm(blob_path, tool):
    out = subprocess.run([tool, '-b', '64', blob_path],
                         capture_output=True, text=True, check=True).stdout
    res = {}
    pending = None
    carry = None
    for line in out.splitlines():
        if line.lstrip().startswith('-'):  # continuation: more bytes of the previous
            if pending is not None and pending in res:
                n, t = res[pending]
                res[pending] = (n + len(line.strip()[1:].strip()) // 2, t)
            continue
        m = NDISASM_RE.match(line)
        if not m:
            continue
        off = int(m.group(1), 16)
        nbytes = len(m.group(2)) // 2
        text = m.group(3).strip()
        if not text:                     # trailing bytes of a long encoding
            if pending is not None and pending in res:
                n, t = res[pending]
                res[pending] = (n + nbytes, t)
            continue
        if is_prefix_only(text):
            # A prefix NASM could not attach to an opcode; it belongs to what follows.
            if carry is None:
                carry = (off, nbytes)
            else:
                carry = (carry[0], carry[1] + nbytes)
            continue
        if carry is not None:
            off, nbytes = carry[0], carry[1] + nbytes
            carry = None
        res[off] = (nbytes, text)
        pending = off
    return res

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('dump', help='output of X86_64DisassemblerDump.v3')
    ap.add_argument('--objdump', default='objdump')
    ap.add_argument('--ndisasm', default='ndisasm')
    ap.add_argument('--blob', help='where to write the raw byte blob')
    ap.add_argument('--max', type=int, default=40, help='mismatches to print per tool')
    ap.add_argument('--only', help='only report instructions whose text matches this regex')
    ap.add_argument('--skip-unsupported', action='store_true',
                    help='ignore instructions this disassembler reports as unsupported')
    ap.add_argument('--baseline',
                    help='file of known disagreement counts; fail only if they grow')
    ap.add_argument('--update-baseline', action='store_true',
                    help='rewrite the baseline file with the current counts')
    args = ap.parse_args()

    insns = read_dump(args.dump)
    if not insns:
        print('no instructions in dump', file=sys.stderr)
        return 2

    blob = bytearray()
    for i in insns:
        assert i.off == len(blob), 'dump is not contiguous at 0x%x' % i.off
        blob += i.raw
    blob_path = args.blob or os.path.join(tempfile.gettempdir(), 'x86-64-corpus.bin')
    with open(blob_path, 'wb') as f:
        f.write(blob)

    oracles = []
    for name, fn, tool in (('objdump', run_objdump, args.objdump),
                           ('ndisasm', run_ndisasm, args.ndisasm)):
        try:
            oracles.append((name, fn(blob_path, tool)))
        except (OSError, subprocess.CalledProcessError) as e:
            print('  skipping %s: %s' % (name, e), file=sys.stderr)

    only = re.compile(args.only) if args.only else None
    totals = {}
    failures = 0
    for name, table in oracles:
        shown = 0
        counts = {'agree': 0, 'differ': 0, 'both-bad': 0,
                  'ours-only-bad': 0, 'theirs-only-bad': 0, 'length': 0, 'desync': 0}
        for i in insns:
            if only and not only.search(i.text):
                continue
            if args.skip_unsupported and 'unsupported' in i.text:
                continue
            entry = table.get(i.off)
            if entry is None:
                counts['desync'] += 1
                continue
            their_len, their_text = entry
            base = i.off + i.length
            mine = canon(i.text, base)
            theirs = canon(their_text, i.off + their_len)
            if mine is None and theirs is None:
                counts['both-bad'] += 1
                continue
            if mine is None:
                counts['ours-only-bad'] += 1
            elif theirs is None:
                counts['theirs-only-bad'] += 1
            elif same(mine, theirs) and i.length == their_len:
                counts['agree'] += 1
                continue
            elif i.length != their_len:
                counts['length'] += 1
            else:
                counts['differ'] += 1
            failures += 1
            if shown < args.max:
                shown += 1
                print('%08x %-32s ours(%d): %-40s %s(%d): %s' % (
                    i.off, i.raw[:i.length].hex() or i.raw.hex(),
                    i.length, i.text, name, their_len, their_text))
        totals[name] = counts

    print()
    for name, c in totals.items():
        print('%-8s agree=%-7d differ=%-6d length=%-6d ours-bad=%-6d theirs-bad=%-6d '
              'both-bad=%-7d desync=%d' % (
                  name, c['agree'], c['differ'], c['length'],
                  c['ours-only-bad'], c['theirs-only-bad'], c['both-bad'], c['desync']))

    if args.baseline:
        return check_baseline(totals, args.baseline, args.update_baseline)
    return 1 if failures else 0

# Counts that must not grow. "agree" is checked in the other direction: it must
# not shrink.
TRACKED = ('differ', 'length', 'ours-only-bad', 'desync')

def check_baseline(totals, path, update):
    lines = []
    for name, c in sorted(totals.items()):
        lines.append('%s %s %d' % (name, 'agree', c['agree']))
        for k in TRACKED:
            lines.append('%s %s %d' % (name, k, c[k]))
    text = '\n'.join(lines) + '\n'
    if update or not os.path.exists(path):
        with open(path, 'w') as f:
            f.write(text)
        print('wrote baseline %s' % path)
        return 0
    expected = {}
    with open(path) as f:
        for line in f:
            parts = line.split()
            if len(parts) == 3:
                expected[(parts[0], parts[1])] = int(parts[2])
    bad = []
    for name, c in sorted(totals.items()):
        if (name, 'agree') not in expected:
            continue        # this oracle was not available when the baseline was made
        if c['agree'] < expected[(name, 'agree')]:
            bad.append('%s agree fell from %d to %d'
                       % (name, expected[(name, 'agree')], c['agree']))
        for k in TRACKED:
            if c[k] > expected[(name, k)]:
                bad.append('%s %s rose from %d to %d'
                           % (name, k, expected[(name, k)], c[k]))
    for b in bad:
        print('  regression: %s' % b)
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main())
