BITS 64

		org	 0x00400000

%include "syscalls.s"

%macro  minimov 2
	push %2
	pop %1
%endmacro

__start:
		; get environ pointer from stack into rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp
		mov [__environment], rdx

		minimov rax, sys_exit
		minimov	rdi, 69
		
		syscall

__environment:
	dq 0