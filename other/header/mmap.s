; shamelessly adapted from the 32-bit version at http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
BITS 64

		org	 0x00400000

%include "syscalls.s"

%define mapsize 1024

;2 bytes smaller than mov!
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

		;close the write end
		minimov rax, sys_close
		pop	rdi
		push	rdi
		shr rdi, 32
		syscall
		pop rdi

		;mmap an executable area to decompress into
		minimov rax, sys_mmap
		; xor rdi,rdi ;addr
		minimov	rsi, mapsize ;length
		minimov rdx, 7 ; rwx
		minimov	r10, 0x22 ;MAP_ANONYMOUS | MAP_PRIVATE
		; minimov	r8, 0 ;fd
		; minimov	r9, 0 ;offset
		syscall

		;remember that mapping, buckaroo
		push rax
		minimov rsi, rax

__read_loop:
		;read from gzip into mapping
		minimov rax, sys_read
		; xor rdi,rdi ;fd = 0
		; minimov rsi, r15
		minimov rdx, mapsize
		syscall

		add rsi, rax

		; keep reading until rax = 0
		test rax,rax
		jnz __read_loop

		; jump to mapping
		pop rax
		jmp rax

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

		;close read end
		; minimov rax, sys_close
		; syscall

		;dup2 pipe->stdout
		minimov rax, sys_dup2
		pop	rdi
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

		; align 4

filesize	equ	 $ - $$