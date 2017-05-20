; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

%include "syscalls.s"

%define mapsize 4096

;2 bytes smaller than mov!
%macro  minimov 2
	push %2
	pop %1
%endmacro

ehdr:									; Elf64_Ehdr
		db	0x7F, "ELF", 2, 1, 1, 0		; e_ident

;hide this shit in the padding lmao
__padding:
__aplay_a1:
		db '-r',0
__aplay_a2:
		db '5500',0

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
bigfilesize equ 800
		dq	bigfilesize*2					; p_filesz
		dq	bigfilesize*2					; p_memsz
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
		test rax,rax
		jz __child
		; jmp __child

__parent:
		;get pipe write fd
		pop	rdi
		shr rdi, 32

__genloop:

		;write some stuff
		minimov rax, sys_write
		minimov rsi, ehdr
		minimov rdx, bigfilesize
		syscall
		minimov rax, sys_write
		syscall
		minimov rsi, __end_of_file
		minimov rax, sys_write
		syscall
		minimov rax, sys_write
		syscall

		jmp __genloop


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

		; envp -> rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp

		;setup argv
		push 0
		push __aplay_a2
		push __aplay_a1
		push __aplay

		; call aplay
		minimov rax, sys_execve
		minimov	rdi, __aplay
		minimov	rsi, rsp
		syscall

__aplay:
		db '/usr/bin/aplay'

__end_of_file:
filesize	equ	 $ - $$