# Stepping must advance one source statement at a time, and the local defined by
# each statement must hold the right value once that statement has run.
break lines.v3:4
run
# Read the parameters at the breakpoint, before stepping: with register
# allocation on, {x}'s register is reused by a later local and its location
# list is not narrowed, so reading it further into the method is not reliable.
# See the known gaps in ./README.
if x == 20 && y == 3
  printf "ok: parameters readable\n"
end
next
if s == 23
  printf "ok: line 4 ran, s == 23\n"
end
next
if d == 17
  printf "ok: line 5 ran, d == 17\n"
end
kill
