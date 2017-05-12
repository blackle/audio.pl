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
		dw	1							; e_phnum
		dw	0							; e_shentsize
		dw	0							; e_shnum
		dw	0							; e_shstrndx

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
		db '/tmp/demo',0

__gzip_args:
		dq __gzip
		dq __gzip_a1
		dq 0

_start:
		; get environ into rdx
		pop rsi ;argc
		inc rsi ;argc + 1
		mov rdx,8
		imul rdx,rsi ; (argc + 1)*8
		add rdx,rsp

		; make arg[0] be /tmp/demo
		mov qword [rsp], __demo

		; execve demo 
		mov rax, 59 ;execve
		mov	rdi, __demo
		mov	rsi, rsp ;use our args as args
		syscall

		; open self 
		mov	rdi, __proc
		mov rax, 2
		xor rsi, rsi
		xor rdx, rdx
		syscall

		mov	rdi, filesize
		mov rax, 60
		syscall

		align 16

filesize	equ	 $ - $$