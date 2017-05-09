audio : audio.c audio.pl.gz.h Makefile
	gcc -s -c -g0 audio.c -o audio.o -Os -nostartfiles -nostdlib -static -fno-builtin
	ld -s -static audio.o -o audio
	strip -R .note -R .comment -R .eh_frame -R .eh_frame_hdr -s audio