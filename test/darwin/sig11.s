;;  /usr/local/bin/nasm -f macho64 64.asm && ld -macosx_version_min 10.7.0 -lSystem -o 64 64.o && ./64

	global start
	global handler


	section .text

handler:
	    mov     rax, 0x2000001 ; exit
	    mov     rdi, 10
	    syscall


start:
	;;  handler install
	push qword 0x04000000
	push qword 0
	lea rax, [rel handler]
	push rax
	push rax
	mov rax, 0x200002E	; sigaction
	mov rdi, 11		; signo
	mov rsi, rsp		; handler
	mov rdx, 0		; old handler
	mov r10, 8
	syscall

	mov rax, 0x112233a0
	mov rbx, 0x112233a1
	mov rcx, 0x112233a2
	mov rdx, 0x112233a3
	mov rsi, 0x112233a4
	mov rdi, 0x112233a5
	mov rsi, 0x112233a6

	mov r8, 0x112233b0
	mov r9, 0x112233b1
	mov r10, 0x112233b2
	mov r11, 0x112233b3
	mov r12, 0x112233b4
	mov r13, 0x112233b5
	mov r14, 0x112233b6
	mov r15, 0x112233b7

	mov [r15], rax 		; trap

	    mov     rax, 0x2000004 ; write
	    mov     rdi, 1	   ; stdout
	    mov     rsi, msg
	    mov     rdx, msg.len
	    syscall

	    mov     rax, 0x2000001 ; exit
	    mov     rdi, 0
	    syscall


	section .data

msg:	    db      "Hello, world!", 10
	.len:   equ     $ - msg
