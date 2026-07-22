# Stepping must advance one source statement at a time, and the local defined by
# each statement must hold the right value once that statement has run.
break lines.v3:4
run
next
if s == 23
  printf "ok: line 4 ran, s == 23\n"
end
next
if d == 17
  printf "ok: line 5 ran, d == 17\n"
end
if x == 20 && y == 3
  printf "ok: parameters readable\n"
end
kill
