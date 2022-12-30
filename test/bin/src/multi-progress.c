#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
}

// usage: multi-progress [-t N] [-s N] -m 'msg1' -c 'command1' <files1> -- -m2 'msg2' -c 'command2' <files2>
//   -t N   sets number of internal threads
//   -s N   sets sharding factor
//
// test1: failure message
// msg1: 100 of 660 passed
// msg2: 33 of 339 passed

// command1 <files> | progress-pipe N command2

// command1 file1 file2
// ##+file1
// ...
// ##-ok: output1
// ##-ok: output2
// ##+file2
// ##-ok

// command2 output1 output2 file2

// command1 <files> | progress-stream command2

// command1 file1 file2
// ##+file1
// ...
// ##-ok: output1
// ##-ok: output2
// ##+file2
// ##-ok

// echo output1 output2 file2 ... | command2
