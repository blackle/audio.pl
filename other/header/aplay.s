; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

%include "syscalls.s"

;2 bytes smaller than mov!
%macro  minimov 2
	push %2
	pop %1
%endmacro

ehdr:									; Elf64_Ehdr
		db	0x7F, "ELF", 2, 1, 1, 0		; e_ident

;hide this shit in the padding lmao
__padding:
		db 'blackle',0

		dw	2							; e_type
		dw	0x3e						; e_machine
		dd	1							; e_version
		dq	_start						; e_entry
		dq	phdr - $$					; e_phoff
		dq	0							; e_shoff
		dd	0							; e_flags
		dw	ehdrsize					; e_ehsize
		dw	phdrsize					; e_phentsize
		; dw	1							; e_phnum
		; dw	0							; e_shentsize
		; dw	0							; e_shnum
		; dw	0							; e_shstrndx

ehdrsize	equ	 $ - ehdr

phdr:									; Elf64_Phdr
		dd	1							; p_type
		dd	0xf							; p_flags
		dq	0							; p_offset
		dq	$$							; p_vaddr
		dq	$$							; p_paddr
		dq	filesize					; p_filesz
		dq	filesize					; p_memsz
		dq	0x10						; p_align

phdrsize	equ	 $ - phdr

_start:
		;close stderr
		minimov rax, sys_close
		minimov rdi, 2
		syscall

		push rax
		; pipe with fds on stack
		minimov rax, sys_pipe
		minimov rdi, rsp
		syscall

		; fork 
		minimov rax, sys_fork
		syscall
		pop	rdi
		test rax,rax
		jz __parent

__child:
		;dup2 read->stdin
		minimov rax, sys_dup2
		; pop	rdi
		; xor rsi,rsi
		syscall

		;close the write end
		minimov rax, sys_close
		shr rdi, 32
		syscall

		;assume argc = 1
		; envp -> rdx
		; pop rdx ;argc
		; inc rdx ;argc + 1
		; shl rdx, 3 ; (argc+1)*8
		minimov rdx, 16
		add rdx,rsp

		;setup argv
		push 0
		push __aplay

		; call aplay
		minimov rax, sys_execve
		minimov	rdi, __aplay
		minimov	rsi, rsp
		syscall

	; anything can go here

__parent:
		;get pipe write fd
		shr rdi, 32

		; mov r15, 0xff00ff00ff00ff00

__reset:
		xor r14, r14
__sampleloop:
		inc r14
		
		push r15
		xor r13, r14
		xor r15, r13
		ror r15, 8
		shr r13, 2

		cmp r14, 1024*10
		jnz __sampleloop

		minimov rsi, rsp
		minimov rdx, 1024*10*8

__writeloop:
		;write some stuff
		minimov rax, sys_write
		; minimov rdi, 1
		syscall

		sub rsp, rdx
		jmp __reset

__aplay:
		db '/usr/bin/aplay'

__end_of_file:

filesize	equ	$ - $$
