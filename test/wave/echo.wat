(module
  (func $arg_len (import "wave" "arg_len") (param i32) (result i32))
  (func $arg_copy (import "wave" "arg_copy") (param i32 i32 i32) (result i32))
  (func $fs_write (import "wave" "fs_write") (param i32 i32 i32) (result i32))
  
  (memory (export "mem") 1)

  (func (export "main") (param $argc i32) (result i32)
    (local $x i32)
    (block
    (loop
        local.get $x
        local.get $argc
        i32.ge_u
        br_if 1

        ;; copy in the argument and print it to stdout
        (i32.const 1)
        (i32.const 100)
        (call $arg_copy (local.get $x) (i32.const 100) (i32.const 64000))
        call $fs_write
        drop

        call $print_sp

        local.get $x
        i32.const 1
        i32.add
        local.set $x
        br 0
    ))
    call $print_ln
    i32.const 0
  )
  (func $print_sp
        i32.const 1
        i32.const 10
        i32.const 1
        call $fs_write
        drop
  )
  (func $print_ln
        i32.const 1
        i32.const 20
        i32.const 1
        call $fs_write
        drop
  )

  (data (i32.const 10) " ")
  (data (i32.const 20) "\n")
)
