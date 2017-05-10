all : audio

audio.py.gz.h : audio.py Makefile
	cat audio.py | grep -v '^\t*#' | gzip -c > audio.py.gz
	xxd -i audio.py.gz > audio.py.gz.h
	wc -c audio.py.gz

audio : audio.c audio.py.gz.h Makefile
	gcc -S -s -c -g0 audio.c -Os -nostartfiles -nostdlib -static -fno-builtin

	#process the assembly
	sed -i '/\.file/ d' audio.s
	#this is debugging I think
	sed -i '/\.cfi_/ d' audio.s
	sed -i '/\.ident/ d' audio.s
	sed -i '/\.note\.GNU-stack/ d' audio.s
	# sed -i '/^\.LFB7/,+2 d' audio.s
	#remove useless _start return stuff
	# sed -i '/^\.L22/,+3 d' audio.s
	#jump to return
	sed -i '/ret/ d' audio.s
	#remove all sections??
	sed -i '/^\t\.section/ d' audio.s
	sed -i '/\.globl\t[^_]/ d' audio.s
	#WHY DOES THIS WORK???
	sed -i '/\.align/ d' audio.s

	#??????????????
	sed -i '/orq.*-1,/ d' audio.s

	gcc -c audio.s
	ld -s -N -x -X -static audio.o -o audio
	strip -R .shstrtab -R .note -R .comment -R .eh_frame -R .eh_frame_hdr -s audio
	./strip_section_header.py
	sed -i 's/\.shstrtab\|\.text\|\.rodata\|\.data//g' audio
	wc -c audio