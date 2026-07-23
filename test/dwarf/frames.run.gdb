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
# main has no local to read here: its own locals are all assigned after the call
# chain returns, so they are correctly reported as unavailable. Assert instead
# that the unwind reaches main, which is what the call frame information buys.
# $_caller_is counts from the selected frame, so reset it to the innermost one.
select-frame 0
if $_caller_is("main", 3)
  printf "ok: unwound to main\n"
end
kill
