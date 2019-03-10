(module
  (func $arg_len (import "wave" "arg_len") (param i32) (result i32))
  (func (export "export") (param i32) (result i32)
    (call $arg_len (i32.const 0))
  )
)
