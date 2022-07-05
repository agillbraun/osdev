%include "base.inc"

; Interrupts

global cpu_disable_interrupts
cpu_disable_interrupts:
  cli
  ret

global cpu_enable_interrupts
cpu_enable_interrupts:
  sti
  ret

global cpu_save_clear_interrupts
cpu_save_clear_interrupts:
  pushfq
  pop rax
  cli
  ret

global cpu_restore_interrupts
cpu_restore_interrupts:
  push rdi
  popfq
  ret

global cli
cli:
  cli
  ret

global sti
sti:
  sti
  ret

global cli_save
cli_save:
  pushfq
  pop rax
  cli
  ret

global sti_restore
sti_restore:
  push rdi
  popfq
  ret

; Registers

global __read_tsc
__read_tsc:
  mov eax, 0x1
  cpuid
  rdtsc
  mov cl, 32
  shl rdx, cl
  or rax, rdx
  ret

global __read_tscp
__read_tscp:
  mfence
  rdtscp
  lfence
  mov cl, 32
  shl rdx, cl
  or rax, rdx
  ret

global read_tsc
read_tsc:
  rdtsc
  mov cl, 32
  shl rdx, cl
  or rax, rdx
  ret


global __read_msr
__read_msr:
  mov ecx, edi
  rdmsr

  shl rdx, 32
  or rax, rdx
  ret

global __write_msr
__write_msr:
  mov rax, rsi
  mov rdx, rsi
  shr rdx, 32

  mov ecx, edi
  wrmsr
  ret

global read_msr
read_msr:
  mov ecx, edi
  rdmsr

  mov cl, 32
  shl rdx, cl
  or rax, rdx
  ret

global write_msr
write_msr:
  mov rax, rsi
  mov rdx, rsi
  mov cl, 32
  shr rdx, cl

  mov ecx, edi
  wrmsr
  ret


global read_fsbase
read_fsbase:
  mov rdi, FS_BASE_MSR
  call read_msr
  ret

global write_fsbase
write_fsbase:
  mov rsi, rdi
  mov rdi, FS_BASE_MSR
  call write_msr
  ret

global __write_fsbase
__write_fsbase:
  mov rsi, rdi
  mov rdi, FS_BASE_MSR
  call write_msr
  ret

global read_gsbase
read_gsbase:
  mov rdi, GS_BASE_MSR
  call read_msr
  ret

global write_gsbase
write_gsbase:
  mov rsi, rdi
  mov rdi, GS_BASE_MSR
  call write_msr
  ret

global read_kernel_gsbase
read_kernel_gsbase:
  mov rdi, KERNEL_GS_BASE_MSR
  call read_msr
  ret

global write_kernel_gsbase
write_kernel_gsbase:
  mov rsi, rdi
  mov rdi, KERNEL_GS_BASE_MSR
  call write_msr
  ret

global swapgs
swapgs:
  swapgs
  ret

; GDT/IDT

global __load_gdt
__load_gdt:
  lgdt [rdi]
  ret

global load_gdt
load_gdt:
  lgdt [rdi]
  ret

global __load_idt
__load_idt:
  lidt [rdi]
  ret

global load_idt
load_idt:
  lidt [rdi]
  ret

global __load_tr
__load_tr:
  ltr di
  ret

global load_tr
load_tr:
  ltr di
  ret

global __flush_gdt
__flush_gdt:
  push 0x08
  lea rax, [rel .reload]
  push rax
  retfq
.reload:
  mov ax, 0x10
  mov ss, ax
  mov ax, 0x00
  mov ds, ax
  mov es, ax
  ret

  ; set up the stack frame so we can call
  ; iretq to set our new cs register value
  push qword 0x10 ; new ss
  push rbp        ; rsp
  pushfq          ; flags
  push qword 0x08 ; new cs
  push rax        ; rip
  iretq
__flush_gdt_end:
  pop rbp


global flush_gdt
flush_gdt:
  push rbp
  mov rbp, rsp

  mov ax, 0x00
  mov ds, ax
  mov es, ax

  lea rax, [rel .flush]

  ; set up the stack frame so we can call
  ; iretq to set our new cs register value
  push qword 0x10 ; new ss
  push rbp        ; rsp
  pushfq          ; flags
  push qword 0x08 ; new cs
  push rax        ; rip
  iretq
.flush:
  pop rbp


; General Registers

global cpu_read_stack_pointer
cpu_read_stack_pointer:
  mov rax, rsp
  ret

global cpu_write_stack_pointer
cpu_write_stack_pointer:
  mov rsp, rdi
  ret

; Control Registers

global read_cr0
read_cr0:
  mov rax, cr0
  ret

global write_cr0
write_cr0:
  mov cr0, rdi
  ret

global __read_cr0
__read_cr0:
  mov rax, cr0
  ret

global __write_cr0
__write_cr0:
  mov cr0, rdi
  ret

global __read_cr2
__read_cr2:
  mov rax, cr2
  ret

global __read_cr3
__read_cr3:
  mov rax, cr3
  ret

global __write_cr3
__write_cr3:
  mov cr3, rdi
  ret

global __read_cr4
__read_cr4:
  mov rax, cr4
  ret

global __write_cr4
__write_cr4:
  mov cr4, rdi
  ret

global __xgetbv
__xgetbv:
  mov ecx, edi
  xgetbv
  mov cl, 32
  shl rdx, cl
  or rax, rdx
  ret

global __xsetbv
__xsetbv:
  mov ecx, edi
  mov rax, rsi
  mov rdx, rsi
  mov cl, 32
  shr rdx, cl
  xsetbv
  ret

; Paging/TLB

global cpu_flush_tlb
cpu_flush_tlb:
  mov rax, cr3
  mov cr3, rax
  ret

global tlb_invlpg
tlb_invlpg:
  invlpg [rdi]
  ret

global tlb_flush
tlb_flush:
  mov rax, cr3
  mov cr3, rax
  ret

; Syscalls

global syscall
syscall:
  mov rax, rdi ; code
  syscall

global sysret
sysret:
  mov [KERNEL_SP], rsp
  mov rsp, [USER_SP]
  swapgs

  mov rcx, rdi ; rip
  mov rsp, rsi ; rsp
  mov r11, 0   ; rflags
  o64 sysret
