# A variable that moves between a register and the stack must read correctly at
# a point in the middle of its live range.
break locals.v3:10 if sq == 9
run
if acc == 5
  printf "ok: acc == 5\n"
end
if sq == 9
  printf "ok: sq == 9\n"
end
# Every parameter must read back the value the caller passed.
delete breakpoints
break check
continue
if i == 7
  printf "ok: i == 7\n"
end
if l == 8
  printf "ok: l == 8\n"
end
if b == 1
  printf "ok: b == true\n"
end
if c == 2
  printf "ok: c == BLUE\n"
end
if f == 9
  printf "ok: f == 9\n"
end
if d == 10
  printf "ok: d == 10\n"
end
kill
