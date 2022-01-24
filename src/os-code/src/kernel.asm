; =============================================================================
; SimpOS -- a 64-bit OS written in Assembly for x86-64 systems
;
; Copyright (C) 2021 Peter Glen -- see LICENSE.TXT
; Copyright (C) 2008-2020 Return Infinity -- see LICENSE.TXT
;
; The BareMetal exokernel
; =============================================================================

%include "../../common/common.inc"

BITS 64                	                ; Specify 64-bit
ORG     0x0000000000100000              ; The kernel needs to be loaded at this address
STACK   equ 0x0000000000110000          ; Where to start?

KERNELSIZE equ 8192            ; Pad the kernel to this length

kernel_start:
    jmp start              ; Skip over the function call index
    nop
    db  'SimpOS   '        ; Kernel signature

align 16
    dq b_input             ; 0x0010
    dq b_output            ; 0x0018
    dq b_net_tx            ; 0x0020
    dq b_net_rx            ; 0x0028
    dq b_disk_read         ; 0x0030
    dq b_disk_write        ; 0x0038
    dq b_config            ; 0x0040
    dq b_system            ; 0x0048
    dq b_output            ; 0x0050
    dq b_dummy             ; 0x0058
    dq b_dummy             ; 0x0058
    dq b_dummy             ; 0x0058
    dq b_dummy             ; 0x0058
    dq b_dummy             ; 0x0058
    dq b_dummy             ; 0x0058

align 16
start:

    ; Estabilish stack
    ;mov   rsp, STACK

    ;mov   rax, rsp
    ;call os_debug_dump_rax
    ;mov rsi, newline
    ;mov rcx, 2
    ;call b_output

    push rsi
    push rcx
    mov rsi, readymsg0
    mov rcx, 5
    call b_output
    pop rcx
    pop rsi

    mov ax, [0x100000 + KERNELSIZE + 3]      ; Payload starts right after the kernel
    ;call os_debug_dump_ax
    cmp ax, 0x6953
    je  good_sig

    mov rsi, badsig
    mov rcx, 5
    call b_output

  good_sig:
    ;mov rsi, 0x100000 + KERNELSIZE + 3
    ;mov rcx, 32
    ;call os_debug_dump_mem

    call init_64            ; After this point we are in a working 64-bit environment

    mov rsi, readymsg1
    mov rcx, 5
    call b_output

    jmp xstart

    ; provoke exception -- test OK
    ;mov rsi, 0x1ffffffff
    ;mov byte [rsi], 0

    call init_pci            ; Initialize the PCI bus

    cmp byte [os_PCIEnabled], 0
    je  nopci

    mov rsi, readymsg2
    mov rcx, 5
    call b_output

    ;jmp hdinit

nopci:
    mov rsi, nopcimsg
    call b_output

hdinit:

    call init_hdd            ; Initialize the disk
    mov rsi, readymsg3
    call b_output

    ;call init_net            ; Initialize the network
    ;mov rsi, readymsg4
    ;call b_output

    ;mov rsi, newline
    ;mov rcx, 2
    ;call b_output
    ;jmp print_pci

print_pci:

    ; Print PCI
    mov edi, 0

  again_pci_bus:

    ;mov     rsi, bus
    ;mov     rcx, 5
    ;call    b_output

    ;mov     eax, edi
    ;call    os_debug_dump_eax

    ;mov     rsi, newline
    ;mov     rcx, 1
    ;call    b_output

    mov word [dev_cnt], 0

  again_pci:

    ;0x 00 BS DF RG
    xor  edx, edx
    mov  dx, word [dev_cnt]
    shl  edx, 8

    push    rdi
    shl     edi, 16             ; bus number
    or      edx,edi
    pop     rdi

    ;mov     eax, edx
    ;call    os_debug_dump_eax
    ;push    rsi
    ;mov     rsi, colonspace
    ;call    b_output

    call    os_pci_read

    cmp     eax, 0xFFFFFFFF
    je      noslot

    push    rax
    push    rcx

    ;mov     eax, ecx
    ;call    os_debug_dump_eax

    ;mov     rsi, colonspace
    ;mov     rcx, 2
    ;call    b_output

    pop     rcx
    pop     rax

    ;call    os_debug_dump_eax

    ;push    rcx
    ;mov     rsi, space
    ;mov     rcx, 1
    ;call    b_output
    ;pop     rcx

  noslot:
    inc     word [dev_cnt]
    cmp     word [dev_cnt], 255
    jb      again_pci

    ;push    rcx
    ;mov     rsi, newline
    ;mov     rcx, 1
    ;call    b_output
    ;pop     rcx

    inc  edi
    cmp  edi, 4
    jb   again_pci_bus

xstart:
    ; Sign on
    mov rsi, readymsg
    ;mov rcx, 11
    call b_output

    ; Copy the payload after the kernel to the proper address
    mov rsi, 0x100000 + KERNELSIZE      ; Payload starts right after the kernel
    cmp qword [rsi], 0x00               ; Is there a payload after the kernel?
    jne  ap_copy                        ; If not, skip to ap_clear

    ;call os_debug_dump_mem
    ;mov rsi, 0x100000 + KERNELSIZE      ; Payload starts right after the kernel

    push rsi
    mov rsi, noload_msg
    mov rcx, 15
    call b_output
    pop rsi
    hlt

  ap_copy:

    cld
    mov rdi, 0x1E0000
    mov rcx, 2048
    rep movsq            ; Copy 16384 bytes

    push rsi
    mov rsi, copied_mon
    call b_output
    pop  rsi

    ; Set the payload to run
    mov qword [os_ClockCallback], init_process

    ; Fall through to ap_clear as align fills the space with No-Ops
    ; At this point the BSP is just like one of the AP's

    ;mov rsi, call_init
    ;call b_output

    ;mov rsi, 0x100000
    ;mov rcx, 128
    ;call os_debug_dump_mem

align 16
ap_clear:                ; All cores start here on first start-up and after an exception
    cli                ; Disable interrupts on this core

    ;mov rsi, proc_start
    ;mov rcx, 17
    ;call b_output

    ; Get local ID of the core
    mov rsi, [os_LocalAPICAddress]    ; We can't use b_smp_get_id as no configured stack yet
    xor eax, eax            ; Clear Task Priority (bits 7:4) and Task Priority Sub-Class (bits 3:0)
    mov dword [rsi+0x80], eax    ; APIC Task Priority Register (TPR)
    mov eax, dword [rsi+0x20]    ; APIC ID in upper 8 bits
    shr eax, 24            ; Shift to the right and AL now holds the CPU's APIC ID
    mov ebx, eax            ; Save the APIC ID

    ; Set up the stack
    shl rax, 16            ; Shift left 16 bits for an 64 KiB stack
    add rax, [os_StackBase]        ; The stack decrements when you "push", start at 64 KiB in
    add rax, 65536
    mov rsp, rax

    ; Clear the entry in the work table
    mov eax, ebx            ; Restore the APIC ID
    mov rdi, os_SMP
    shl rax, 3            ; Quick multiply by 8 to get to proper record
    add rdi, rax
    xor eax, eax
    or al, 1            ; Set bit 0 for "present"
    stosq                ; Clear the code address

    ; Clear registers. Gives us a clean slate to work with
    xor eax, eax            ; aka r0
    xor ecx, ecx            ; aka r1
    xor edx, edx            ; aka r2
    xor ebx, ebx            ; aka r3
    xor ebp, ebp            ; aka r5, We skip RSP (aka r4) as it was previously set
    xor esi, esi            ; aka r6
    xor edi, edi            ; aka r7
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    sti                ; Enable interrupts on this core

ap_check:
    call b_smp_get            ; Check for an assigned workload
    and al, 0xF0            ; Clear the flags
    cmp rax, 0            ; If 0 then there is nothing to do
    jne ap_process

ap_halt:                    ; Halt until a wakeup call is received
    hlt

    ;mov rsi, proc_unhalt
    ;mov rcx, 7
    ;call b_output

    jmp ap_check            ; Core will jump to ap_check when it wakes up

ap_process:

    ; Raise keyboard interrupt (test)
    int     0x21

    ; Raise mouse interrupt (test)
    int     0x2c

    push    rsi
    push    rcx
    push    rax

    mov rsi, proc_start
    call b_output

    ;call os_debug_dump_rax

    pop rax
    pop rcx
    pop rsi

    ; provoke exception
    ;mov rsi, 0x1ffffffff
    ;mov byte [rsi], 0

    mov rcx, 1            ; Set the active flag
    call b_smp_setflag
    xor ecx, ecx
    call rax                ; Run the code
    jmp ap_clear            ; Reset the stack, clear the registers, and wait for something else to work on

init_process:

    mov qword [os_ClockCallback], 0     ; Clear the callback
    call b_smp_get_id                   ; Get the ID of the current core

    ; provoke exception
    ;mov rsi, 0x1ffffffff
    ;mov byte [rsi], 0

    ;call os_debug_dump_rax

    push rsi
    push rcx

    ;call os_debug_dump_rax
    mov rsi, called_init
    call b_output

    pop rcx
    pop rsi

    mov rcx, rax             ; Copy the APIC ID for b_smp_set
    mov rax, 0x1E0000        ; Payload was copied here
    call b_smp_set

    ; provoke exception
    ;mov rsi, 0x1ffffffff
    ;mov byte [rsi], 0

    ;divide by zero
    ;xor     bl, bl
    ;div     bl

    ret

; ------------------------------------------------------------------------
; Calling from the timer rax has clock count

timer_tick:

    ;push    rax
    ;mov     rsi, timer_msg
    ;mov     rcx, 11
    ;call    b_output
    ;pop     rax
    ;call    os_debug_dump_rax
    ;mov     rsi, newline
    ;mov     rcx, 2
    ;call    b_output

    ret

b_dummy:

    push rsi
    push rcx
    mov rsi, dummymsg
    ;mov rcx, 21
    call b_output
    pop rsi
    pop rcx
    ret

; Includes
%include "init.asm"
%include "syscalls.asm"
%include "drivers.asm"
%include "interrupt.asm"
%include "kernvar.asm"       ; Include this last to keep the read/write variables away from the code

;times KERNELSIZE-($-$$) db 0        ; Set the compiled kernel binary to at least this size in bytes

padd:
; Pad to an even KB file
times KERNELSIZE-($-$$) db 0x90

endd:

;%assign num endd-padd
;%warning "padding available" num

; =============================================================================
; EOF
