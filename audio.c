#include <x86_64-linux-gnu/asm/unistd_64.h>
#include "syscalls.h"
#include "audio.pl.gz.h"

#define NULL 0

inline _syscall0(int, fork)
inline _syscall1(int, pipe, int*, args)
inline _syscall1(int, close, int, fd)
inline _syscall1(int, exit, int, ret)
inline _syscall1(void, wait4, void*, uhh)
inline _syscall2(int, dup2, int, fd1, int, fd2)
inline _syscall3(int, write, int, fd, const void *,buf, int, size)
inline _syscall3(int, execve, const char *,filename, char *const *, argv, char *const*, envp)

char *const aplay[9] = {"/usr/bin/aplay", "-q", "-c", "1", "-r", "22050", "-f", "S16_LE", NULL};
char *const gzip[3] = {"/bin/gzip", "-d", NULL};
char *const perl[2] = {"/usr/bin/perl", NULL};

void _start(){
	asm volatile (
		"pop %rsi\n"
	);
	register int argc asm ("rsi");
	register char** rsp asm ("rsp");
	char **envp = 8+8*argc+rsp;

    //define some pipes
	int gzip_to_perl[2];
	int source_to_gzip[2];
	int perl_to_aplay[2];
    int pid;
    
	pipe(perl_to_aplay);
    
    pid = fork();
	if(pid == 0){
		//close read end
		close(perl_to_aplay[0]);

		pipe(gzip_to_perl);
		
		pid = fork();
		if(pid == 0){
			//close pipe we don't need
			close(perl_to_aplay[1]);
			//close read end
			close(gzip_to_perl[0]);
			
		    pipe(source_to_gzip);
			
			pid = fork();
			if(pid == 0){
				//parent gzip feeder
				//close pipe we don't need
				close(gzip_to_perl[1]);
				
				//close read end
				close(source_to_gzip[0]);
			
				write(source_to_gzip[1], audio_pl_gz, audio_pl_gz_len);

				//done writing
				close(source_to_gzip[1]);

				// exit(0);
				exit(0);
			} else {
				//gzip
				//close write end
				close(source_to_gzip[1]);
				
		        //copy pipe to stdin
		        dup2(source_to_gzip[0], 0);
		        //copy pipe to stdout
		        dup2(gzip_to_perl[1], 1);
		        

				// exit(0);
		        execve(gzip[0], gzip, envp);
			}
		} else {
			//perl
			//close write end
			close(gzip_to_perl[1]);
			
	        //copy pipe to stdin
	        dup2(gzip_to_perl[0], 0);
	        //copy pipe to stdout
	        dup2(perl_to_aplay[1], 1);
	        

			// exit(0);
	        execve(perl[0], perl, envp);
		}
	} else {
		//aplay
		
		//close write end
		close(perl_to_aplay[1]);
		
		//copy pipe to stdin
		dup2(perl_to_aplay[0], 0);
	
		execve(aplay[0], aplay, envp);
		//pulseaudio fallback
		// (*execvp)("paplay", "paplay", "-p", "--raw", "--channels=1", "--rate=22050", NULL);

		// exit(0);
	}
}
