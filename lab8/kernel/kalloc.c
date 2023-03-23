// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

// #define CPUMEM   (PHYSTOP-(uint64)end)/NCPU

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmems[NCPU];

struct spinlock nomemlock;

int pagenums[NCPU];
int cond;

void
kinit()
{
  // initlock(&kmem.lock, "kmem");
  // init the lock
  for (int i = 0; i < NCPU; i++) {
    initlock(&((kmems[i]).lock), "kmem");
    pagenums[i] = 0;
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  push_off();
  int idx = cpuid();
  pop_off();

  acquire(&(kmems[idx].lock));
  r->next = kmems[idx].freelist;
  kmems[idx].freelist = r;
  pagenums[idx]++;
  release(&(kmems[idx].lock));
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  push_off();
  int idx = cpuid();
  pop_off();

  acquire(&(kmems[idx].lock));
  if (pagenums[idx] == 0) {
    int tdx = (idx + 1) % NCPU ;
    // for (int i = 0; i < NCPU; i++) {
    //   if (kmems[i].pagenum > kmems[tdx].pagenum && i != idx) {
    //     tdx = i;
    //   }
    // }
    while (1) {
      // if (tdx == idx) {
      //   int flag = 0;
      //   for (int i = 0; i < NCPU; i++) {
      //     if (kmems[i].freelist) {
      //       flag = 1;
      //     }
      //   }
      //   if (flag == 0) {
      //     printf("no memory.\n");
      //   }
      // }
      if (idx == tdx) {
        break;
      }
      if (pagenums[tdx] > 0) {
        break;
      } else {
        tdx = (tdx + 1) % NCPU;
      }
    }


    if (idx != tdx) {
      struct run *r;
      acquire(&(kmems[tdx].lock));

      r = kmems[tdx].freelist;
      kmems[tdx].freelist = r->next;
      pagenums[tdx]--;

      release(&(kmems[tdx].lock));

      r->next = kmems[idx].freelist;
      kmems[idx].freelist = r;
      pagenums[idx]++;
    }
  }
  r = kmems[idx].freelist;
  if(r) {
    kmems[idx].freelist = r->next;
    pagenums[idx]--;
  }
  release(&(kmems[idx].lock));

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
