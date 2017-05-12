; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

%macro  minimov 2
        push    %2
        pop 	%1
%endmacro

ehdr:									; Elf64_Ehdr
		db	0x7F, "ELF", 2, 1, 1, 0		; e_ident

__gzip_a1:
		db '-d',0
__demo:
		db '.x',0

		times 2 db	0					; e_pad
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

_start:
		; fork 
		minimov rax, 57
		syscall

		; move to child or parent
		test rax,rax
		jz _child
_parent:
		;move pid into param1 for wait4 syscall
		minimov rdi, rax
		xor rsi, rsi ;null
		xor rdx, rdx ;null
		xor r10, r10 ;null
		minimov rax, 61
		syscall

		; get environ pointer from stack into rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp

		; execve demo 
		minimov rax, 59 ;execve
		minimov	rdi, __demo
		minimov	rsi, rsp ;use our args as args
		syscall

_child:
		; open self 
		minimov	rdi, __proc
		minimov rax, 2 ;open
		xor rsi, rsi
		xor rdx, rdx
		syscall

		;fd1
		minimov r14, rax

		;seek
		minimov	rdi, __proc
		minimov rax, 8 ;lseek
		minimov rdi, r14
		minimov rsi, filesize
		xor rdx, rdx
		syscall

		; open demo 
		minimov	rdi, __demo
		minimov rax, 2 ;open
		minimov rsi, 0o1101 ;O_WRONLY | O_CREAT | O_TRUNC
		minimov rdx, 0o755
		syscall

		;fd2
		minimov r15, rax

		;dup2 demo->stdout
		minimov rax, 33 ;dup2
		minimov	rdi, r15
		minimov rsi, 1
		syscall

		;dup2 self->stdin
		minimov rax, 33 ;dup2
		minimov	rdi, r14
		minimov rsi, 0
		syscall

		;setup arguments to gzip
		push 0
		push __gzip_a1
		push __gzip

		;execve
		minimov rax, 59 ;execve
		minimov	rdi, __gzip
		minimov	rsi, rsp
		xor rdx, rdx ;empty environ
		syscall

		align 4

filesize	equ	 $ - $$