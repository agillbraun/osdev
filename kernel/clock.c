//
// Created by Aaron Gill-Braun on 2022-06-29.
//

#include <clock.h>

#include <printf.h>
#include <panic.h>
#include <atomic.h>

LIST_HEAD(clock_source_t) clock_sources;
clock_source_t *current_clock_source;
clock_t kernel_time_ns;
uint64_t clock_ticks;

void register_clock_source(clock_source_t *source) {
  kassert(source != NULL);
  LIST_ENTRY_INIT(&source->list);
  LIST_ADD(&clock_sources, source, list);

  if (current_clock_source == NULL) {
    current_clock_source = source;
  } else if (source->scale_ns < current_clock_source->scale_ns) {
    current_clock_source = source;
  }

  kprintf("clock: registering clock source '%s'\n", source->name);
}

//

void clock_init() {
  if (current_clock_source == NULL) {
    panic("no clock sources registered");
  }

  kprintf("using %s as clock source\n", current_clock_source->name);
  current_clock_source->enable(current_clock_source);
  current_clock_source->last_tick = current_clock_source->read(current_clock_source);
}

clock_t clock_now() {
  if (current_clock_source == NULL) {
    return 0;
  }

  uint64_t last = current_clock_source->last_tick;
  uint64_t current = current_clock_source->read(current_clock_source);
  current_clock_source->last_tick = current;
  atomic_fetch_add(&clock_ticks, current - last);
  uint64_t current_ns = current * current_clock_source->scale_ns;
  kernel_time_ns += current_ns;
  return current_ns;
}

clock_t clock_kernel_time() {
  return kernel_time_ns;
}

uint64_t clock_current_ticks() {
  return clock_ticks;
}

void clock_update_ticks() {
  if (current_clock_source == NULL) {
    return;
  }

  uint64_t last = current_clock_source->last_tick;
  uint64_t current = current_clock_source->read(current_clock_source);
  current_clock_source->last_tick = current;
  uint64_t delta = current - last;
  atomic_fetch_add(&clock_ticks, delta);
  uint64_t current_ns = current * current_clock_source->scale_ns;
  kernel_time_ns += current_ns;
}
