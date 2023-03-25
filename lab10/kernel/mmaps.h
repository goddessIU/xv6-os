#include "types.h"

#define VMASIZE 16
struct VMA
{
  uint64 address;
  struct file* pt;
  int length;
  int pglength;
  int permissions;
  int flags;
  int used;
  struct proc* pr;
};

