#include <x86_64-linux-gnu/asm/unistd_64.h>
#include "syscalls.h"
#include "audio.py.gz.h"

#define NULL 0

char *const gzip[3] = {"/bin/gzip", "-d", NULL};
char *const perl[2] = {"/usr/bin/python2.7", NULL};

void _start(){
	asm volatile (
		"pop %rsi\n"
	);
	register int argc asm ("rsi");
	register char** rsp asm ("rsp");
	//I'm 80% sure this is the correct way to get the environment pointer on x86_64
	char **envp = 8+8*argc+rsp;

	//define some pipes
	int gzip_to_perl[2];
	int source_to_gzip[2];
	int pid;
	
	// pipe(gzip_to_perl);
	INLINE_SYSCALL(pipe, 1, gzip_to_perl);
	
	pid = INLINE_SYSCALL(fork, 0);
	if(pid == 0){
		//close read end, but not really needed
		// INLINE_SYSCALL(close, 1, gzip_to_perl[0]);
		
		INLINE_SYSCALL(pipe, 1, source_to_gzip);
		
		pid = INLINE_SYSCALL(fork, 0);
		if(pid == 0){
			//we should be closing some pipes here, but they'll be closed on exit anyway
		
			INLINE_SYSCALL(write, 3, source_to_gzip[1], audio_py_gz, audio_py_gz_len);

			INLINE_SYSCALL(exit, 1, 0);
		} else {
			//gzip
			//close write end
			INLINE_SYSCALL(close, 1, source_to_gzip[1]);
			
			//copy pipe to stdin
			INLINE_SYSCALL(dup2, 2, source_to_gzip[0], 0);
			//copy pipe to stdout
			INLINE_SYSCALL(dup2, 2, gzip_to_perl[1], 1);

			INLINE_SYSCALL(execve, 3, gzip[0], gzip, envp);
		}
	} else {
		//perl
		//close write end
		INLINE_SYSCALL(close, 1, gzip_to_perl[1]);
		
		//copy pipe to stdin
		INLINE_SYSCALL(dup2, 2, gzip_to_perl[0], 0);

		INLINE_SYSCALL(execve, 3, perl[0], perl, envp);
	}
}
