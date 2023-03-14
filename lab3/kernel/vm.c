#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

/*
 * create a direct-map page table for the kernel.
 */
void
kvminit()
{
  kernel_pagetable = (pagetable_t) kalloc();
  memset(kernel_pagetable, 0, PGSIZE);

  // uart registers
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // CLINT
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // PLIC
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Used for uesr kernel page to get kernel stack
uint64
walkaddrforuser(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// translate a kernel virtual address to
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(pagetable_t kpagetable, uint64 va)
{
  uint64 off = va % PGSIZE;
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kpagetable, va, 0);
  if(pte == 0)
    panic("kvmpa 1");
  if((*pte & PTE_V) == 0)
    panic("kvmpa 2");
  pa = PTE2PA(*pte);
  return pa+off;
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    // if (*pte != 0)
    // printf("pte is %p\n", *pte);
    if(*pte & PTE_V) {
      // printf("paget %p is  remap va is %p, pa is %p\n", pagetable, va, pa);
      panic("remap");
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
// for process kernel page table
void
uvminit_kpagetable(pagetable_t pagetable, pagetable_t kpagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  mappages(kpagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X);

  memmove(mem, src, sz);
}
// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}


// copy from user table to process kernel table 
void 
copy_table(pagetable_t pagetable, pagetable_t kpagetable, int oldsz, int start)  {
  for (; start < oldsz; start += PGSIZE) {
    uint64 mem = walkaddr(pagetable, start);
    if(mappages(pagetable, start, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R) != 0){
      // kfree(mem);
      // uvmdealloc(pagetable, start, oldsz);
      // return 0;
    }
  }
}

// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc_kpagetable(pagetable_t pagetable, pagetable_t kpagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc_kpagetable(pagetable, kpagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    int ans1 = mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U);
    int ans2 = mappages(kpagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R);
    if (ans1 != 0 || ans2 != 0) {
      kfree(mem);
      uvmdealloc_kpagetable(pagetable, kpagetable, a, oldsz);
      return 0;
    }
    // if (ans1 != 0) {
    //   kfree(mem);
    //   uvmdealloc(pagetable, a, oldsz);
    //   return 0;
    // } else {
    //   int ans2 = mappages(kpagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R);
    //   if(ans2 != 0){
    //     kfree(mem);
    //     uvmdealloc(kpagetable,a, oldsz);
    //     return 0;
    //   }
    // }
    
    // printf("the va is %p, the pa is %p\n", a, mem);
    // printf("the user va is %p, the pa is %p\n", a, mem);
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
// for both page table
uint64
uvmdealloc_kpagetable(pagetable_t pagetable, pagetable_t kpagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(kpagetable, PGROUNDUP(newsz), npages, 0);
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Recursively free page-table pages without free physical page
void
freewalk_withoutpyhfree(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk_withoutpyhfree((pagetable_t)child);
      pagetable[i] = 0;
    } else if (pte & PTE_V) {
      pagetable[i] = 0;
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

void
uvmfree_exec(pagetable_t pagetable, pagetable_t kpagetable, uint64 sz)
{
  if(sz > 0) {
    uvmunmap(kpagetable, 0, PGROUNDUP(sz)/PGSIZE, 0);
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  }
  freewalk(pagetable);
  // printf("ok3\n");
  freewalk_withoutpyhfree(kpagetable);
  // printf("ok6\n");
  
  
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
// for process kernel page table
int
uvmcopy_kpagetable(pagetable_t old, pagetable_t new, 
                    pagetable_t kold, pagetable_t knew, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags, kflags;
  char *mem;
  pte_t *kpte;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if ((kpte = walk(kold, i, 0)) == 0) 
      panic("uvmcopy: kpte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    if((*kpte & PTE_V) == 0)
      panic("uvmcopy: kpage not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    kflags = PTE_FLAGS(*kpte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    // int ans1 = mappages(new, i, PGSIZE, (uint64)mem, flags);
    // int ans2 = mappages(knew, i, PGSIZE, (uint64)mem, kflags);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0 || mappages(knew, i, PGSIZE, (uint64)mem, kflags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  uvmunmap(knew, 0, i / PGSIZE, 1);
  return -1;
}

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}


// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  return copyin_new(pagetable, dst, srcva, len);
  // uint64 n, va0, pa0;

  // while(len > 0){
  //   va0 = PGROUNDDOWN(srcva);
  //   pa0 = walkaddr(pagetable, va0);
  //   if(pa0 == 0)
  //     return -1;
  //   n = PGSIZE - (srcva - va0);
  //   if(n > len)
  //     n = len;
  //   memmove(dst, (void *)(pa0 + (srcva - va0)), n);

  //   len -= n;
  //   dst += n;
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  return copyinstr_new(pagetable, dst, srcva, max);
  // uint64 n, va0, pa0;
  // int got_null = 0;

  // while(got_null == 0 && max > 0){
  //   va0 = PGROUNDDOWN(srcva);
  //   pa0 = walkaddr(pagetable, va0);
  //   if(pa0 == 0) {
  //     return -1;
  //   }
      
  //   n = PGSIZE - (srcva - va0);
  //   if(n > max)
  //     n = max;

  //   char *p = (char *) (pa0 + (srcva - va0));
  //   while(n > 0){
  //     if(*p == '\0'){
  //       *dst = '\0';
  //       got_null = 1;
  //       break;
  //     } else {
  //       *dst = *p;
  //     }
  //     --n;
  //     --max;
  //     p++;
  //     dst++;
  //   }

  //   srcva = va0 + PGSIZE;
  // }
  // if(got_null){
  //   return 0;
  // } else {
  //   return -1;
  // }
}

// helper vmprint, for recursion
int
walk_vmprint(pagetable_t pagetable, int level) {
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    uint64 child = PTE2PA(pte);

    if ((pte & PTE_V) == 0) {
      continue;
    }

    // print the format header
    if (level == 1) {
      printf("..%d: ", i);
    } else if (level == 2) {
      printf(".. ..%d: ", i);
    } else if (level == 3) {
      printf(".. .. ..%d: ", i);
    }

    // if (level == 3 && (child == 0x0000000080007000 || child >= 0x0000000087000000)) 
    printf("pte %p pa %p\n", pte, child);


    if (level < 3) 
      walk_vmprint((pagetable_t)child, level + 1);
  }
  return 0;
}

// print page table
int 
vmprint(pagetable_t pagetable) {
  printf("page table %p\n", pagetable);
  if (walk_vmprint(pagetable, 1) == 0) {
    return 0;
  } else {
    return -1;
  }
  return 0;
}

/*
 * create a modified kvminit for per-process kernal page table
 */
pagetable_t
pvminit()
{
  pagetable_t p_kernel_pagetable = (pagetable_t) kalloc();
  memset(p_kernel_pagetable, 0, PGSIZE);

  // uart registers
  uvmmap(p_kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  uvmmap(p_kernel_pagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // CLINT
  // uvmmap(p_kernel_pagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // PLIC
  uvmmap(p_kernel_pagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  uvmmap(p_kernel_pagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  uvmmap(p_kernel_pagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  uvmmap(p_kernel_pagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
  // vmprint(p_kernel_pagetable);
  return p_kernel_pagetable;
}

/*
 * get kernal page table
 */
pagetable_t
get_kernel_pagetable() {
  return kernel_pagetable;
}

// add a mapping to the per-process kernel page table.
void
uvmmap(pagetable_t pagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(pagetable, va, sz, pa, perm) != 0) {
    // printf("uvmmap pgtable is %p, va is %p ,  pa is %p\n", pagetable, va, pa);
    panic("uvmmap");
  }
}

void 
free_kernel_pagetable_helper(pagetable_t pagetable, uint64 va, uint64 sz, int dofree) {
  uint64 a = PGROUNDDOWN(va);
  uint64 last = PGROUNDDOWN(va + sz - 1);
  uvmunmap(pagetable, va, (last - a)/PGSIZE , dofree);
}

// Free a process's kernel page table, and optionally free the
// physical memory it refers to.
void
free_kpagetable(pagetable_t pagetable)
{
  free_kernel_pagetable_helper(pagetable, UART0, PGSIZE, 0);
  free_kernel_pagetable_helper(pagetable, VIRTIO0, PGSIZE, 0);
  // free_kernel_pagetable_helper(pagetable, CLINT, 0x10000, 0);
  free_kernel_pagetable_helper(pagetable, PLIC, 0x400000, 0);
  // free_kernel_pagetable_helper(pagetable, KERNBASE, (uint64)etext-KERNBASE, 0);
  // free_kernel_pagetable_helper(pagetable, (uint64)etext, PHYSTOP-(uint64)etext, 0);
  free_kernel_pagetable_helper(pagetable, TRAMPOLINE, (uint64)trampoline - TRAMPOLINE, 0);
}

// Free a process's kernel page table, and optionally free the
// physical memory it refers to.
void
free_kpagetable_exec(pagetable_t pagetable)
{
  free_kernel_pagetable_helper(pagetable, UART0, PGSIZE, 0);
  free_kernel_pagetable_helper(pagetable, VIRTIO0, PGSIZE, 0);
  free_kernel_pagetable_helper(pagetable, CLINT, 0x10000, 0);
  free_kernel_pagetable_helper(pagetable, PLIC, 0x400000, 0);
  // free_kernel_pagetable_helper(pagetable, KERNBASE, (uint64)etext-KERNBASE, 0);
  // free_kernel_pagetable_helper(pagetable, (uint64)etext, PHYSTOP-(uint64)etext, 0);
  free_kernel_pagetable_helper(pagetable, TRAMPOLINE, (uint64)trampoline - TRAMPOLINE, 0);
  // printf("free exec is ok\n");
}