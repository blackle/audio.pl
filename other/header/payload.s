BITS 64

filesize equ 264

		org	 0x00400000+filesize

%include "syscalls.s"

%macro  minimov 2
	push %2
	pop %1
%endmacro

bufsize equ 1024*2
bufsize_bytes equ bufsize

__start:
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
		; jmp __child

__parent:
		;get pipe write fd
		pop	r13
		shr r13, 32

__reset:
		minimov r15, __chords
__inc_chords:
		call __make_chords
		inc r15

__genloop:
		cmp r15, __chords_end
		je __reset

		;write some stuff
		minimov rax, sys_write
		minimov rdi, r13
		; push rdi
		minimov rsi, __buffer
		minimov rdx, bufsize_bytes
		syscall
		minimov rax, sys_write
		syscall

		jmp __inc_chords

; __exit:
; 		minimov rax, sys_exit
; 		minimov	rdi, 0
; 		syscall


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

		;setup argv
		push 0
		push __aplay

		; call aplay
		minimov rax, sys_execve
		minimov	rdi, __aplay
		minimov	rsi, rsp
		syscall

; rdi = rate, rsi = value
__make_tone:
		minimov rdx, __buffer
__make_tone_loop:
		mov [rdx], word rsi

		add rdx, rdi
		cmp rdx, __buffer+bufsize/2
		jl __make_tone_loop
		ret

__make_chords:
		xor rsi, rsi
		minimov rdi, 1
		call __make_tone

		minimov rsi, 32
		mov dil, [r15]
		call __make_tone

		inc r15
		mov dil, [r15]

		call __make_tone

		ret

__aplay:
	db "/usr/bin/aplay",0
; __aplay_a1:
; 	db "-c",0
; __aplay_a2:
; 	db "1",0
; __aplay_a3:
; 	db "-r",0
; __aplay_a4:
; 	db "8000",0
; __aplay_a5:
; 	db "-f",0
; __aplay_a6:
; 	db "FLOAT_LE",0

__chords:
	db 21, 18
	db 21, 18
	db 21, 18
	db 21, 18

	db 23, 18
	db 23, 18
	db 23, 18
	db 23, 18

	db 25, 20
	db 25, 20
	db 25, 20
	db 25, 22

	db 21, 18
	db 21, 18
	db 21, 18
	db 21, 18

	db 23, 18
	db 23, 18
	db 23, 18
	db 23, 18

	db 25, 20
	db 25, 20
	db 25, 22
	db 29, 38

	db 21, 18
	db 21, 18
	db 21, 18
	db 21, 18

	db 23, 18
	db 23, 18
	db 23, 18
	db 23, 18

	db 25, 20
	db 25, 22
	db 27, 34
	db 29, 38

	db 25, 20
	db 3, 2
	db 3, 2
	db 3, 2

	db 27, 34
	db 3, 2
	db 3, 2
	db 3, 2

	db 25, 22
	db 3, 2
	db 3, 2
	db 3, 2

	db 29, 38
	db 3, 2
	db 5, 4
	db 9, 8
	db 17, 16

__chords_end:
	db 3, 2


chordsize	equ	 $ - __chords

__buffer:
; 	times bufsize_bytes db 0
