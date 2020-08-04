if exists("b:did_indent")
   finish
endif
let b:did_indent = 1

" virgil indenting is similar to C
setlocal cindent

let b:undo_indent = "setl cin<"
