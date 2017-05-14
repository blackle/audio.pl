mmap_test: payload.gz mmap Makefile
	cat mmap payload.gz > mmap_test
	chmod +x mmap_test
	wc -c mmap_test

mmap : mmap.s payload.gz Makefile
	nasm -f bin -o mmap mmap.s -l mmap.list
	chmod +x mmap
	wc -c mmap

payload.gz : payload
	cat payload | gzip -9 -c > payload.gz
	wc -c payload.gz

payload : payload.s Makefile
	nasm -f bin -o payload payload.s -l payload.list
	chmod +x payload
	wc -c payload

test : mmap test.py.gz
	-rm /tmp/-d
	cat mmap test.py.gz > test
	chmod +x test
	wc -c test

test.py.gz : test.py Makefile
	cat test.py | gzip -9 -c > test.py.gz
	# truncate -s "-4" test.py.gz
	wc -c test.py.gz

header : header.s Makefile
	nasm -f bin -o header header.s -l header.list
	chmod +x header
	wc -c header

python : python.s Makefile
	nasm -f bin -o python python.s -l python.list
	chmod +x python
	wc -c python

