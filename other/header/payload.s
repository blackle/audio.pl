BITS 64

		org	 0x00000000

%include "syscalls.s"

%macro  minimov 2
	push %2
	pop %1
%endmacro

bufsize equ 1024*4
bufsize_bytes equ bufsize

__start:
		minimov r14, rsi

		;close leftover
		minimov rax, sys_close
		syscall

		push rax
		; pipe with fds on stack
		minimov rax, sys_pipe
		minimov rdi, rsp
		syscall

		; fork 
		minimov rax, sys_fork
		syscall
		test rax,rax
		jz __child

__parent:
		;close read end
		; minimov rax, sys_close
		; syscall

		; mmap an area to write bytes to
		minimov rax, sys_mmap
		xor rdi,rdi ;addr
		minimov	rsi, bufsize_bytes ;length
		minimov rdx, 6 ; rw
		minimov	r10, 0x22 ;MAP_ANONYMOUS | MAP_PRIVATE
		; minimov	r8, 0 ;fd
		; minimov	r9, 0 ;offset
		syscall

		minimov r15, rax
		minimov rdx, __finit
		add rdx, r15
		movups xmm1, [rdx]

		xor rdx, rdx
__sampleloop:
		minimov rsi, rdx
		add rsi, r15
		; aesenc xmm1, xmm1
		movups [rsi], xmm1

		add rdx, 16
		cmp rdx, bufsize
		jnz __sampleloop

		;write some stuff
		minimov rax, sys_write
		pop	rdi
		shr rdi, 32
		xor rdi,rdi ;stdout
		inc rdi
		minimov rsi, r15
		minimov rdx, bufsize_bytes
		syscall

		minimov rax, sys_exit
		minimov	rdi, 0
		syscall


__child:
		;dup2 read->stdin
		minimov rax, sys_dup2
		pop	rdi
		xor rsi,rsi
		syscall

		;close the write end
		minimov rax, sys_close
		shr rdi, 32
		syscall

		;close stdout
		minimov rax, sys_close
		minimov rdi, 2
		syscall

		; envp -> rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp

		push 0

		;god all of this for relative offset bullshit
		; minimov r14, r15
		add r14,__aplay_a6
		
		push r14

		sub r14, __aplay_a6-__aplay_a5
		push r14

		sub r14, __aplay_a5-__aplay_a4
		push r14

		sub r14, __aplay_a4-__aplay_a3
		push r14

		sub r14, __aplay_a3-__aplay_a2
		push r14

		sub r14, __aplay_a2-__aplay_a1
		push r14

		sub r14, __aplay_a1-__aplay
		push r14

		minimov rax, sys_execve
		minimov	rdi, r14
		minimov	rsi, rsp
		syscall

__aplay:
	db "/usr/bin/aplay",0
__aplay_a1:
	db "-c",0
__aplay_a2:
	db "1",0
__aplay_a3:
	db "-r",0
__aplay_a4:
	db "22050",0
__aplay_a5:
	db "-f",0
__aplay_a6:
	db "FLOAT_LE",0

__fzero:
	times 4 dw 0.0
__fone:
	times 4 dw 1.0
__finit:
	dw 0.1
	dw 0.2
	dw 0.3
	dw 0.4

; __buffer:
; 	times 256 dq 0
