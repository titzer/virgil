(module
  (func $arg_copy (import "wave" "arg_copy") (param i32 i32 i32) (result i32))
  (memory (export "memory") 1)
  (func (export "entry") (param i32) (result i32)
    (call $arg_copy (i32.const 0) (i32.const 100) (i32.const 100))
  )
)
