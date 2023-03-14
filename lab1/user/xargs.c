#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if (argc < 2) {
    printf("arguments not enough\n");
    exit(0);
  }

  char *paras[MAXARG];
  int i = 0;
  for (int j = 1; j < argc; j++) {
    paras[i] = argv[j];
    i++;
  }
  
  char arg[100] = "";
  char *t = arg;
  char ch;
  while (read(0, &ch, 1) > 0) {
    if (ch == ' ' || ch == '\n') {
      *(t++) = '\0';
      printf("the arg is %s\n", arg);
      paras[i] = malloc(strlen(arg) + 1);
      strcpy(paras[i++], arg);
      t = arg;
      continue;
    } else {
      *(t++) = ch;
    }
  }

  char *exename = "./";
  strcpy(exename + 2, argv[1]);
  
  if (fork() == 0) {
    exec(exename, paras);
    printf("wrong something!\n");
    exit(-1);
  }
  
  wait(0);
  exit(0);
}
