all : audio

audio.pl.gz.h : audio.pl Makefile
	gzip audio.pl -c > audio.pl.gz
	xxd -i audio.pl.gz > audio.pl.gz.h
	wc -c audio.pl.gz

audio : audio.c audio.pl.gz.h Makefile
	gcc -s -c -g0 audio.c -o audio.o -Os -nostartfiles -nostdlib -static -fno-builtin
	ld -s -static audio.o -o audio
	strip -R .note -R .comment -R .eh_frame -R .eh_frame_hdr -s audio
	wc -c audio