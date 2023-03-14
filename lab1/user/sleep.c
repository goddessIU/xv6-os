#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char* argv[]) {
    char *wrong_message = "wrong, you should give a number to sleep.\n";
    int i;

    if (argc <= 1) {
        write(1, wrong_message, strlen(wrong_message));
        exit(0);
    }

    i = atoi(argv[1]);
    sleep(i);
    exit(0);
}