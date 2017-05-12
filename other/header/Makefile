test : header test.py.gz
	cat header test.py.gz > test
	chmod +x test
	wc -c test

test.py.gz : test.py Makefile
	cat test.py | gzip -c > test.py.gz
	wc -c test.py.gz

header : header.s Makefile
	nasm -f bin -o header header.s
	chmod +x header
	wc -c header