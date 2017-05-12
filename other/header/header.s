; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

ehdr:									; Elf64_Ehdr
		db	0x7F, "ELF", 2, 1, 1, 0		; e_ident
		times 8 db	0					; e_pad
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
__gzip_a1:
		db '-d',0
__demo:
		db '.x',0

_start:
		; fork 
		mov rax, 57
		syscall

		; move to child or parent
		test rax,rax
		jz _child
_parent:
		;move pid into param1 for wait4 syscall
		mov rdi, rax
		xor rsi, rsi ;null
		xor rdx, rdx ;null
		xor r10, r10 ;null
		mov rax, 61
		syscall

		; get environ pointer from stack into rdx
		pop rdx ;argc
		inc rdx ;argc + 1
		shl rdx, 3 ; (argc+1)*8
		add rdx,rsp

		; execve demo 
		mov rax, 59 ;execve
		mov	rdi, __demo
		mov	rsi, rsp ;use our args as args
		syscall

_child:
		; open self 
		mov	rdi, __proc
		mov rax, 2 ;open
		xor rsi, rsi
		xor rdx, rdx
		syscall

		;fd1
		mov r14, rax

		;seek
		mov	rdi, __proc
		mov rax, 8 ;lseek
		mov rdi, r14
		mov rsi, filesize
		xor rdx, rdx
		syscall

		; open demo 
		mov	rdi, __demo
		mov rax, 2 ;open
		mov rsi, 0o1101 ;O_WRONLY | O_CREAT | O_TRUNC
		mov rdx, 0o755
		syscall

		;fd2
		mov r15, rax

		;dup2 demo->stdout
		mov rax, 33 ;dup2
		mov	rdi, r15
		mov rsi, 1
		syscall

		;dup2 self->stdin
		mov rax, 33 ;dup2
		mov	rdi, r14
		mov rsi, 0
		syscall

		;setup arguments to gzip
		push 0
		push __gzip_a1
		push __gzip

		;execve
		mov rax, 59 ;execve
		mov	rdi, __gzip
		mov	rsi, rsp
		xor rdx, rdx ;empty environ
		syscall

		align 4

filesize	equ	 $ - $$