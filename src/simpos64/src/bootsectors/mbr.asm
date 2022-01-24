; =============================================================================
; Pure64 MBR -- a 64-bit OS/software loader written in Assembly for x86-64 systems
; Copyright (C) 2008-2020 Return Infinity -- see LICENSE.TXT
;
; This Master Boot Record will load Pure64 from a pre-defined location on the
; hard drive without making use of the file system.
;
; In this code we are expecting a BMFS-formatted drive. With BMFS the Pure64
; binary is required to start at sector 16 (8192 bytes from the start). A small
; check is made to make sure Pure64 was loaded by comparing a signaiture.
; =============================================================================

; Default location of the second stage boot loader. This loads
; 32 KiB from sector 16 into memory at 0x8000

%include "../../../common/common.inc"

%define DAP_SECTORS 64
%define DAP_STARTSECTOR 16
%define DAP_ADDRESS BUFF_ADDR
;%define DAP_ADDRESS 0xe000
%define DAP_SEGMENT 0x0000

BITS 16
org 0x7C00

entry:
    cli                     ; Disable interrupts
    cld                     ; Clear direction flag
    xor eax, eax
    mov ss, ax
    mov es, ax
    mov ds, ax
    mov sp, 0x7C00
    sti                              ; Enable interrupts

    mov [DriveNumber], dl       ; BIOS passes drive number in DL
    mov ah, 0
    mov al, 11100011b           ; 9600bps, no parity, 1 stop bit, 8 data bits
    mov dx, 0                   ; Serial port 0
    int 0x14                    ; Configure serial port

    mov si, msg_Init
    call print_string_16

; Get the BIOS E820 Memory Map
; use the INT 0x15, eax= 0xE820 BIOS function to get a memory map
; inputs: es:di -> destination buffer for 24 byte entries
; outputs: bp = entry count, trashes all registers except esi
do_e820:
    mov edi, 0x00006000        ; location that memory map will be stored to
    xor ebx, ebx            ; ebx must be 0 to start
    xor bp, bp            ; keep an entry count in bp
    mov edx, 0x0534D4150        ; Place "SMAP" into edx
    mov eax, 0xe820
    mov [es:di + 20], dword 1    ; force a valid ACPI 3.X entry
    mov ecx, 24            ; ask for 24 bytes
    int 0x15
    jc nomemmap            ; carry set on first call means "unsupported function"
    mov edx, 0x0534D4150        ; Some BIOSes apparently trash this register?
    cmp eax, edx            ; on success, eax must have been reset to "SMAP"
    jne nomemmap
    test ebx, ebx            ; ebx = 0 implies list is only 1 entry long (worthless)
    je nomemmap
    jmp jmpin
e820lp:
    mov eax, 0xe820            ; eax, ecx get trashed on every int 0x15 call
    mov [es:di + 20], dword 1    ; force a valid ACPI 3.X entry
    mov ecx, 24            ; ask for 24 bytes again
    int 0x15
    jc memmapend            ; carry set means "end of list already reached"
    mov edx, 0x0534D4150        ; repair potentially trashed register
jmpin:
    jcxz skipent            ; skip any 0 length entries
    cmp cl, 20            ; got a 24 byte ACPI 3.X response?
    jbe notext
    test byte [es:di + 20], 1    ; if so: is the "ignore this data" bit clear?
    je skipent
notext:
    mov ecx, [es:di + 8]        ; get lower dword of memory region length
    test ecx, ecx            ; is the qword == 0?
    jne goodent
    mov ecx, [es:di + 12]        ; get upper dword of memory region length
    jecxz skipent            ; if length qword is 0, skip entry
goodent:
    inc bp                ; got a good entry: ++count, move to next storage spot
    add di, 32
skipent:
    test ebx, ebx            ; if ebx resets to 0, list is complete
    jne e820lp
nomemmap:
;    mov byte [cfg_e820], 0        ; No memory map function
memmapend:
    xor eax, eax            ; Create a blank record for termination (32 bytes)
    mov ecx, 8
    rep stosd

; Enable the A20 gate
set_A20:
    in al, 0x64
    test al, 0x02
    jnz set_A20
    mov al, 0xD1
    out 0x64, al
check_A20:
    in al, 0x64
    test al, 0x02
    jnz check_A20
    mov al, 0xDF
    out 0x60, al

    mov si, msg_OK
    call print_string_16

;wait_for_user:
;    mov  cx, 0x3ff
;  wait_some:
;    push cx
;    mov cx, 0xffff
;  inner:
;    loop inner
;    pop  cx
;    loop wait_some

set_video:

    mov si, msg_Video
    call print_string_16

    mov edi, VBEModeInfoBlock    ; VBE data will be stored at this address
    mov ax, 0x4F01            ; GET SuperVGA MODE INFORMATION - http://www.ctyme.com/intr/rb-0274.htm
    ; CX queries the mode, it should be in the form 0x41XX as bit 14 is set for LFB and bit 8 is set for VESA mode
    ; 0x4112 is 640x480x24bit, 0x4129 should be 32bit
    ; 0x4115 is 800x600x24bit, 0x412E should be 32bit
    ; 0x4118 is 1024x768x24bit, 0x4138 should be 32bit
    ; 0x411B is 1280x1024x24bit, 0x413D should be 32bit
    mov cx, 0x4118            ; Put your desired mode here
    ;mov cx, 0x413d             ; Put your desired mode here
    ;mov cx, 0x411b            ; Put your desired mode here
    mov bx, cx            ; Mode is saved to BX for the set command later
    int 0x10

    cmp ax, 0x004F            ; Return value in AX should equal 0x004F if command supported and successful
    jne halt
    cmp byte [VBEModeInfoBlock.BitsPerPixel], 24    ; Make sure this matches the number of bits for the mode!
    jne halt            ; If set bit mode was unsuccessful then bail out
    or bx, 0x4000            ; Use linear/flat frame buffer model (set bit 14)
    mov ax, 0x4F02            ; SET SuperVGA VIDEO MODE - http://www.ctyme.com/intr/rb-0275.htm
    int 0x10
    cmp ax, 0x004F            ; Return value in AX should equal 0x004F if supported and successful
    ;jne halt
    jne op_fail

    mov si, msg_OK
    call print_string_16

read_disk:

    mov si, msg_Read
    call print_string_16

    ; Read the 2nd stage boot loader into memory.
    mov ah, 0x42                ; Extended Read
    mov dl, [DriveNumber]        ; http://www.ctyme.com/intr/rb-0708.htm
    mov si, DAP
    int 0x13
    jc op_fail

    mov si, msg_OK
    call print_string_16

    mov si, msg_Sig
    call print_string_16

   ; Verify that the 2nd stage boot loader was read.
    mov ax, [BUFF_ADDR + 6]
    cmp ax, 0x3436            ; Match against the Pure64 binary
    jne op_fail

    mov si, msg_OK
    call print_string_16

    ; At this point we are done with real mode and BIOS interrupts. Jump to 32-bit mode.
    cli                ; No more interrupts
    lgdt [cs:GDTR32]        ; Load GDT register
    mov eax, cr0
    or al, 0x01                 ; Set protected mode bit
    mov cr0, eax
    jmp 8:BUFF_ADDR            ; Jump to 32-bit protected mode

op_fail:

    mov si, msg_ERR
    call print_string_16

halt:
    hlt
    jmp halt
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; 16-bit function to output a string to the serial port
; IN:    SI - Address of start of string
print_string_16:            ; Output string in SI to screen
    pusha
    mov dx, 0                ; Port 0
 .repeat:
    mov ah, 0x01            ; Serial - Write character to port
    lodsb                    ; Get char from string
    cmp al, 0
    je .done                ; If char is zero, end of string
    int 0x14                ; Output the character
    jmp short .repeat
 .done:
    popa
    ret
;------------------------------------------------------------------------------

align 16
GDTR32:                	; Global Descriptors Table Register
dw gdt32_end - gdt32 - 1        ; limit of GDT (size minus one)
dq gdt32                ; linear address of GDT

align 16
gdt32:
dw 0x0000, 0x0000, 0x0000, 0x0000    ; Null desciptor
dw 0xFFFF, 0x0000, 0x9A00, 0x00CF    ; 32-bit code descriptor
dw 0xFFFF, 0x0000, 0x9200, 0x00CF    ; 32-bit data descriptor
gdt32_end:

msg_Init        db "Init  ", 0
msg_Read        db "Read  ", 0
msg_Video       db "Video ", 0
msg_Sig         db "Veri  ", 0

msg_OK          db "OK", 10, 0
msg_ERR         db "ERR", 10, 0

padd:
times 446-$+$$ db 0
endd:

;%assign num endd-padd
;%warning "padding available" num

; False partition table entry required by some BIOS vendors.
db 0x80, 0x00, 0x01, 0x00, 0xEB, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF
DriveNumber db 0x00

times 476-$+$$ db 0

align 4

DAP:
    db 0x10
    db 0x00
    dw DAP_SECTORS
    dw DAP_ADDRESS
    dw DAP_SEGMENT
    dq DAP_STARTSECTOR

times 510-$+$$ db 0

sign dw 0xAA55

; EOF
