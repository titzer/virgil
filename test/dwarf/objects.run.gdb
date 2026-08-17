# Class fields and array elements must be reachable through the references, and
# a string must be readable as the byte array it is.
break objects.v3:35
run
if p->x == 3 && p->y == 4
  printf "ok: p == (3, 4)\n"
end
if q->x == 6 && q->y == 8
  printf "ok: q == (6, 8)\n"
end
if l->a->x == 3 && l->b->y == 8
  printf "ok: line endpoints reachable\n"
end
if a->length == 4
  printf "ok: a.length == 4\n"
end
if a->elems[0] == 10 && a->elems[3] == 40
  printf "ok: a[0] == 10, a[3] == 40\n"
end
if t == 100
  printf "ok: t == 100\n"
end
if s->length == 8 && s->elems[0] == 'o'
  printf "ok: string readable\n"
end
kill
