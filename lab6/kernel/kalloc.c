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

int refcount[(PHYSTOP - KERNBASE) / PGSIZE];
// int freepage = 0;
struct spinlock reflock;

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&reflock, "ref");
  // char *p = (char*)end;
  // for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE) {
  //   refcount[(uint64)(p - end) / PGSIZE] = 1;
  // } 
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    // refcount[(uint64)(p - KERNBASE) / PGSIZE] = 1;
    // freepage++;
    kfree(p);
    // printf("the ref is %d\n", refcount[(uint64)(p - end) / PGSIZE]);
  } 
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

  // refcount[((uint64)(pa) - KERNBASE) / PGSIZE] -= 1;
  // ref_minus((void*)pa);
  // // refcount[((uint64)(pa) - KERNBASE) / PGSIZE] -= 1;
  // int num = refcount[(uint64)(pa - KERNBASE) / PGSIZE];
  // if (num > 1) {
  //   ref_minus((void*)pa);
  //   return;
  // } else if (num == 1) {
  //   // Fill with junk to catch dangling refs.
  //   memset(pa, 1, PGSIZE);
    
  //   r = (struct run*)pa;

  //   acquire(&kmem.lock);
  //   refcount[((uint64)(pa) - KERNBASE) / PGSIZE] = 0;
  //   r->next = kmem.freelist;
  //   kmem.freelist = r;
  //   release(&kmem.lock);
  // } else if (num < 1) {
  //   printf("the pa is %d and %d, %p\n", (uint64)((uint64)pa - KERNBASE) / PGSIZE, (uint64)(((char*)PGROUNDUP((uint64)PHYSTOP)) - KERNBASE) / PGSIZE, pa);
  //   panic("ref should >= 0\n");
  // } 
  acquire(&reflock);
  
  refcount[((uint64)(pa) - KERNBASE) / PGSIZE]--;
  int num = refcount[(uint64)(pa - KERNBASE) / PGSIZE];
  if (num <= 0) {
    memset(pa, 1, PGSIZE);
    
    r = (struct run*)pa;
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
  release(&reflock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r) {
    kmem.freelist = r->next;
  }
    
  release(&kmem.lock);

  if(r) {
    refcount[((uint64)(r) - KERNBASE) / PGSIZE] = 1;
    memset((char*)r, 5, PGSIZE); // fill with junk
  }
    
  return (void*)r;
}

void
ref_plus(void *r)
{
  // acquire(&kmem.lock);
  acquire(&reflock);
  refcount[((uint64)(r) - KERNBASE) / PGSIZE] += 1;
  // release(&kmem.lock);
  release(&reflock);
}

char*
ref_minus(void *r) 
{
          
          
  char* mem;
  acquire(&reflock);
  if (refcount[((uint64)(r) - KERNBASE) / PGSIZE] == 1) {
    release(&reflock);
    return r;
  }
  
  if((mem = kalloc()) == 0) {
    release(&reflock);
    return 0;
  }
  memmove(mem, (char*)r, PGSIZE);
  refcount[((uint64)(r) - KERNBASE) / PGSIZE] -= 1;
  // release(&kmem.lock);
  release(&reflock);
  return mem;
}

int
ref_canwrite(void *r)
{
  return refcount[((uint64)(r) - KERNBASE) / PGSIZE];
  // if (refcount[((uint64)(r) - KERNBASE) / PGSIZE] == 1) {
  //   return 1;
  // } else {
  //   return 0;
  // }
}

void 
get_freepage()
{
  // printf("free page num is %d\n", freepage);
}
