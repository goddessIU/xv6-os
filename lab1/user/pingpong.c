#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char* argv[]) {
    int p[2];
    pipe(p);

    int pid;
    // char* buf[1];

    if (fork() == 0) {
        pid = getpid();
        char* buf[1];
        
        while (read(p[0], buf, 1) <= 0);
            
        printf("%d: received ping\n", pid);
        close(p[0]);
        write(p[1], "", 1);
        close(p[1]);
        
        exit(0);
    } else {
        pid = getpid();
        char* buf[1];
        write(p[1], "", 1);
        close(p[1]);
        wait(0);
        if (read(p[0], buf, 1) <= 0) {
            printf("something wrong\n");
            exit(0);
        } else {
            printf("%d: received pong\n", pid);
        }
        close(p[0]);

        exit(0);   
    }
}