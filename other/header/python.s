; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

%include "syscalls.s"

%macro  minimov 2
	push %2
	pop %1
%endmacro

ehdr:									; Elf64_Ehdr
		db	0x7F, "ELF", 2, 1, 1, 0		; e_ident

;hide this shit in the padding lmao
__padding:
		times 5 db 0
__gzip_a1:
		db '-d',0

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

__proc:
		db '/proc/self/exe',0
__gzip:
		db '/bin/gzip',0
__python:
		db '/usr/bin/python2.7',0

_start:
		;replace with add rsp,#?
		push rax
		; pipe with fds on stack
		minimov rax, sys_pipe
		minimov rdi, rsp
		syscall

		; fork 
		minimov rax, sys_fork
		syscall

		; move to child or parent
		test rax,rax
		jz _child
_parent:
		;dup2 the read end
		;thank god it only reads the bottom 4 bytes
		minimov rax, sys_dup2
		pop	rdi
		; xor rsi, rsi ;0 = stdin
		syscall

		;close the write end
		minimov rax, sys_close
		shr rdi, 32
		syscall

		; get environ pointer from stack into rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp

		push 0

		; execve demo 
		minimov rax, sys_execve
		minimov	rdi, __python
		minimov	rsi, rsp ;use our args as args
		syscall

_child:
		; open self 
		minimov	rdi, __proc
		minimov rax, sys_open ;open
		; xor rsi, rsi
		; xor rdx, rdx
		syscall

		;fd1
		minimov rdi, rax

		;seek
		minimov rax, sys_lseek ;lseek
		; push rdi ;was set
		minimov rsi, filesize
		; xor rdx, rdx
		syscall

		;dup2 self->stdin
		minimov rax, sys_dup2
		; pop	rdi ;was set
		xor rsi, rsi ;0 = stdin
		syscall

		;close write end
		minimov rax, sys_close
		pop	rdi
		syscall

		;dup2 pipe->stdout
		minimov rax, sys_dup2
		shr rdi, 32
		inc rsi ;1 = stdin
		syscall

		;setup arguments to gzip
		push 0
		push __gzip_a1
		push __gzip

		;execve
		minimov rax, sys_execve
		minimov	rdi, __gzip
		minimov	rsi, rsp
		; xor rdx, rdx ;empty environ
		syscall

		align 4

filesize	equ	 $ - $$