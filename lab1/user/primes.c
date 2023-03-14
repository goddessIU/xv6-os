#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// func task(int num)
// p = get left
// print p
// pipe(p)
// int p
// loop:
//   n = get left
//   fork() = 0{
//     task(n)
//   } else {
//     write(p[1], n, 4);
//   }

// void recur_prime(int num) {

// }

void 
task(int *p) {
    close(p[1]);
    int buf[1];
    int initial_num = 0;
    int pp[2];
    pipe(pp);

    if (fork() == 0) {
        task(pp);
    } else {
        close(pp[0]);

        while (read(p[0], buf, 4) > 0) {
            if (initial_num == 0) {
                initial_num = buf[0];
                printf("prime %d\n", buf[0]);
            } else {
                if (buf[0] % initial_num == 0) {
                    continue;
                }

                write(pp[1], buf, 4);
            }
        }
    }

    close(p[0]);
    close(pp[1]);

    wait(0);
    exit(0);
}

int
main(int argc, char *argv[])
{
  int p[2];
  pipe(p);

  if (fork() == 0) {
    task(p);
    
  } else {
    close(p[0]);

    for(int i = 2; i <= 35; i++){
        write(p[1], &i, 4);
    }
    close(p[1]);

    wait(0);
  }

  exit(0);
}

