#!/usr/bin/env bash
# Generate a Virgil enum with N cases and 3 shared methods, where only
# K cases are actually referenced in code.  Measures the effect of
# per-case liveness analysis on binary size and compile time.
#
# Usage: ./generate.bash N K > BigEnum.v3
#   N = total enum cases (default 1000)
#   K = number of cases actually referenced (default N)

N=${1:-1000}
K=${2:-$N}
if (( K > N )); then K=$N; fi

cat <<'HDR'
// Generated benchmark: enum liveness analysis.
// Only a subset of cases are referenced; the rest are dead.

HDR

printf "enum Big(a: int, b: int, c: int, d: int) {\n"

for (( i=0; i<N; i++ )); do
    a=$(( (i * 7 + 3) & 0xFFF ))
    b=$(( (i * 13 + 5) & 0xFFF ))
    c=$(( (i * 19 + 11) & 0xFFF ))
    d=$(( (i * 31 + 17) & 0xFFF ))
    comma=","
    if (( i == N-1 )); then comma=";"; fi
    printf "\tC%04d(%d, %d, %d, %d)%s\n" $i $a $b $c $d "$comma"
done

cat <<'MTH'

	def sum() -> int { return a + b + c + d; }
	def prod() -> int { return a * b + c * d; }
	def hash() -> int { return (a ^ (b << 3)) + (c ^ (d << 5)); }
}

MTH

# Generate liveCases() referencing only K cases (evenly spaced)
echo "def liveCases() -> Array<Big> {"
printf "\treturn ["
stride=$(( N / K ))
if (( stride < 1 )); then stride=1; fi
count=0
for (( i=0; i<N && count<K; i+=stride )); do
    if (( count > 0 )); then printf ", "; fi
    if (( count > 0 && count % 10 == 0 )); then printf "\n\t\t"; fi
    printf "Big.C%04d" $i
    (( count++ ))
done
echo "];"
echo "}"

# Compute iteration count: ~500M total virtual calls regardless of K
iters=$(( 500000000 / K ))
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
	var live = liveCases();
	var n = live.length;
	var s = 0;
	match (arg) {
		0 => {
			for (j < $iters) {
				for (i < n) s += live[i].sum();
			}
		}
		1 => {
			for (j < $iters) {
				for (i < n) s += live[i].prod();
			}
		}
		2 => {
			for (j < $iters) {
				for (i < n) s += live[i].hash();
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
