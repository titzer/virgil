sub    $0x40,%rsp
mov    %rsi,(%rsp)
mov    (%rsp),%rax
testq  $0x0,(%rax)
mov    (%rsp),%rdi
call   0x80005c8 <B.id>
mov    %eax,0x8(%rsp)
mov    (%rsp),%rdi
call   0x80005d8 <B.index>
mov    %eax,0x10(%rsp)
mov    0x8(%rsp),%eax
add    0x10(%rsp),%eax
mov    %eax,0x18(%rsp)
mov    (%rsp),%rdi
call   0x80005c8 <B.id>
mov    %eax,0x20(%rsp)
mov    0x18(%rsp),%eax
sub    0x20(%rsp),%eax
mov    %eax,0x28(%rsp)
mov    (%rsp),%rdi
call   0x80005d8 <B.index>
mov    %eax,0x30(%rsp)
mov    0x28(%rsp),%eax
add    0x30(%rsp),%eax
mov    %eax,0x38(%rsp)
mov    0x38(%rsp),%eax
add    $0x40,%rsp
ret    