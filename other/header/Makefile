test : header test.py.gz
	-rm /tmp/-d
	cat header test.py.gz > test
	chmod +x test
	wc -c test

test.py.gz : test.py Makefile
	cat test.py | gzip -c > test.py.gz
	wc -c test.py.gz

header : header.s Makefile
	nasm -f bin -o header header.s -l annotated.list
	chmod +x header
	wc -c header

python : python.s Makefile
	nasm -f bin -o python python.s -l annotated.list
	chmod +x python
	wc -c python