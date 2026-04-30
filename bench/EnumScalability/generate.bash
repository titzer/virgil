#!/usr/bin/env bash
# Generate a Virgil enum with N cases (default 1000), 4 params each,
# plus methods exercising virtual dispatch, for scalability testing.
# Usage: ./generate.bash [num_cases] > BigEnum.v3

N=${1:-1000}

cat <<'HDR'
// Generated benchmark: large enum for compilation/space overhead comparison.
// Measures: compile time, binary size, runtime RSS.

enum Big(a: int, b: int, c: int, d: int) {
HDR

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

# Generate the array of all cases
echo "def allCases() -> Array<Big> {"
printf "\treturn ["
for (( i=0; i<N; i++ )); do
    if (( i > 0 )); then printf ", "; fi
    if (( i > 0 && i % 10 == 0 )); then printf "\n\t\t"; fi
    printf "Big.C%04d" $i
done
echo "];"
echo "}"

cat <<'MAIN'

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
			for (i < n) s += all[i].sum();
		}
		1 => {
			for (i < n) s += all[i].prod();
		}
		2 => {
			for (i < n) s += all[i].hash();
		}
		3 => {
			for (j < 1000) {
				for (i < n) s += all[i].sum();
			}
		}
		4 => {
			for (i < n) s += all[i].a + all[i].d;
		}
	}
	return s & 0xFFFF;
}

def main(args: Array<string>) -> int {
	var r = run(parseArg(args));
	return r - r;
}
MAIN
