//
// Created by Aaron Gill-Braun on 2019-04-29.
//

#ifndef KERNEL_MEM_MM_H
#define KERNEL_MEM_MM_H

#include <multiboot.h>
#include <stdbool.h>
#include <stddef.h>

#define KERNEL_BASE 0xC0000000

#define PAGE_SIZE 4096
#define MAX_ORDER 10
#define MIN_MEMORY 0x2000000 // 32 MiB

#define phys_to_virt(addr) (((uintptr_t) addr) + KERNEL_BASE)
#define virt_to_phys(addr) (((uintptr_t) addr) - KERNEL_BASE)

#define addr_to_pde(addr) ((unsigned int) ((uintptr_t) (addr) >> 22))
#define addr_to_pte(addr) ((unsigned int) ((uintptr_t) (addr) >> 12 & 0x03FF))

#define align(value, size) (((value) + (size)) & ~(size))
// #define align(value, size) ((value) + (-(value) & (size)))

#define ZONE_RESRV   0x0
#define ZONE_DMA     0x1
#define ZONE_NORMAL  0x2
#define ZONE_HIGHMEM 0x4

#define PAGE_PRESENT   0x8
#define PAGE_READWRITE 0x16
#define PAGE_USER      0x32

//
//
//

extern uint32_t kernel_image_start;
extern uint32_t kernel_image_end;

#define kernel_start ((uint32_t) &kernel_image_start)
#define kernel_end ((uint32_t) &kernel_image_end)

typedef struct page {
  uintptr_t virt_addr; // virtual address (not constant)
  uintptr_t phys_addr; // physical address (constant)
  union {
    uint16_t raw : 10;
    struct {
      uint16_t free : 1;      // page is free
      uint16_t split : 1;     // page was split
      uint16_t head : 1;      // page is head of split page
      uint16_t tail : 1;      // page is tail of split page
      uint16_t present : 1;   // page is mapped in memory
      uint16_t readwrite : 1; // page is read/write or read-only
      uint16_t user : 1;      // page is for user or supervisor
      uint16_t reserved : 3;
    };
  } flags;
  uint16_t zone : 2;  // the zone this page belongs to
  uint16_t order : 4; // the order (and size) of this page

  struct page *next;
  struct page *prev;

  struct page *parent;
  struct page *head;
  struct page *tail;
} page_t;

typedef struct free_pages {
  int count;
  page_t *first;
} free_pages_t;

typedef struct mem_zone {
  const char *name;
  int type;
  size_t length;
  free_pages_t free_pages[MAX_ORDER + 1];
} mem_zone_t;

//

extern page_t **mem;

void mem_init(uintptr_t base_addr, size_t size);
page_t *alloc_pages(int order, uint8_t flags);
page_t *alloc_page(uint8_t flags);
void free_page(page_t *page);

void mm_print_debug_stats();
void mm_print_debug_page(page_t *page);

#endif // KERNEL_MEM_MM_H
