# The call frame information must let the debugger walk out of the innermost
# method through every caller and read each caller's locals.
break frames.v3:6
run
if t == 8 && n == 4
  printf "ok: leaf frame\n"
end
select-frame 1
if m == 4
  printf "ok: middle frame\n"
end
select-frame 2
if o == 3
  printf "ok: outer frame\n"
end
select-frame 3
if r == 0
  printf "ok: main frame\n"
end
kill
