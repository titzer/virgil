#!/usr/bin/env bash
# Generate a Virgil enum with N cases where M cases have per-case
# method overrides and the rest inherit the default.  Measures the
# effect of RaClass elision on binary size (especially jar/wasm-gc).
#
# Usage: ./generate.bash N M > BigEnum.v3
#   N = total enum cases (default 1000)
#   M = number of cases with per-case overrides (default 10)

N=${1:-1000}
M=${2:-10}
if (( M > N )); then M=$N; fi

cat <<'HDR'
// Generated benchmark: enum RaClass elision.
// Only M of N cases have per-case method overrides.

HDR

printf "enum Big(a: int, b: int, c: int, d: int) {\n"

# Compute which cases get overrides (evenly spaced)
if (( M > 0 )); then
    stride=$(( N / M ))
    if (( stride < 1 )); then stride=1; fi
else
    stride=$(( N + 1 ))
fi

for (( i=0; i<N; i++ )); do
    a=$(( (i * 7 + 3) & 0xFFF ))
    b=$(( (i * 13 + 5) & 0xFFF ))
    c=$(( (i * 19 + 11) & 0xFFF ))
    d=$(( (i * 31 + 17) & 0xFFF ))

    has_override=false
    if (( M > 0 )); then
        if (( i % stride == 0 && i / stride < M )); then
            has_override=true
        fi
    fi

    comma=","
    if (( i == N-1 )); then comma=";"; fi

    if $has_override; then
        local_val=$(( (i * 37 + 7) & 0xFFFF ))
        printf "\tC%04d(%d, %d, %d, %d) { def val() -> int { return %d; } }%s\n" \
            $i $a $b $c $d $local_val "$comma"
    else
        printf "\tC%04d(%d, %d, %d, %d)%s\n" $i $a $b $c $d "$comma"
    fi
done

cat <<'MTH'

	def sum() -> int { return a + b + c + d; }
	def val() -> int { return a; }
}

MTH

# Generate allCases() referencing all N cases
echo "def allCases() -> Array<Big> {"
printf "\treturn ["
for (( i=0; i<N; i++ )); do
    if (( i > 0 )); then printf ", "; fi
    if (( i > 0 && i % 10 == 0 )); then printf "\n\t\t"; fi
    printf "Big.C%04d" $i
done
echo "];"
echo "}"

# ~500M total virtual calls
iters=$(( 500000000 / N ))
if (( iters < 1000 )); then iters=1000; fi

cat <<MAIN

def parseArg(args: Array<string>) -> int {
	if (args.length < 1) return 0;
	var s = args[0];
	var r = 0;
	for (i < s.length) {
		var c = s[i];
		if (c >= '0' && c <= '9') r = r * 10 + (c - '0');
	}
	return r;
}

def run(arg: int) -> int {
	var all = allCases();
	var n = all.length;
	var s = 0;
	match (arg) {
		0 => {
			for (j < $iters) {
				for (i < n) s += all[i].sum();
			}
		}
		1 => {
			for (j < $iters) {
				for (i < n) s += all[i].val();
			}
		}
	}
	return s & 0xFFFF;
}

def main(args: Array<string>) -> int {
	var r = run(parseArg(args));
	return r - r;
}
MAIN
