; =============================================================================
; Pure64 MBR -- a 64-bit OS/software loader written in Assembly for x86-64 systems
; Copyright (C) 2008-2020 Return Infinity -- see LICENSE.TXT
;
; This Master Boot Record will load Pure64 from a pre-defined location on the
; hard drive without making use of the file system.
;
; In this code we are expecting a BMFS-formatted drive. With BMFS the Pure64
; binary is required to start at sector 16 (8192 bytes from the start). A small
; check is made to make sure Pure64 was loaded by comparing a signiture.
; =============================================================================

; Default location of the second stage boot loader. This loads
; 32 KiB from sector 16 into memory at 0xe000

%include "../common/common.inc"

%define DAP_SECTORS 16
;%define DAP_STARTSECTOR 0x18
%define DAP_STARTSECTOR 0x1c
%define DAP_ADDRESS BUFF_ADDR
;%define DAP_ADDRESS 0x8000
%define DAP_SEGMENT 0x0000

BITS 16
org 0x7C00

entry:
    cli                 ; Disable interrupts
    cld                 ; Clear direction flag
    xor ax, ax
    mov ss, ax
    mov es, ax
    mov ds, ax
    ;mov cs, ax         ;??
    mov sp, 0x7C00
    sti             ; Enable interrupts

    mov [DriveNumber], dl       ; BIOS passes drive number in DL

    mov ah, 0
    mov al, 11100011b       ; 9600bps, no parity, 1 stop bit, 8 data bits
    mov dx, 0           ; Serial port 0
    int 0x14            ; Configure serial port

    mov si, msg_Init
    call print_string_16


; Get the BIOS E820 Memory Map
; use the INT 0x15, eax= 0xE820 BIOS function to get a memory map
; inputs: es:di -> destination buffer for 24 byte entries
; outputs: bp = entry count, trashes all registers except esi
do_e820:
    mov edi, 0x00006000     ; location that memory map will be stored to
    xor ebx, ebx            ; ebx must be 0 to start
    xor bp, bp          ; keep an entry count in bp
    mov edx, 0x0534D4150        ; Place "SMAP" into dx
    mov eax, 0xe820
    mov [es:edi + 20], dword 1  ; force a valid ACPI 3.X entry
    mov ecx, 24         ; ask for 24 bytes
    int 0x15
    jc nomemmap         ; carry set on first call means "unsupported function"
    mov edx, 0x0534D4150        ; Some BIOSes apparently trash this register?
    cmp eax, edx            ; on success, eax must have been reset to "SMAP"
    jne nomemmap
    test ebx, ebx           ; ebx = 0 implies list is only 1 entry long (worthless)
    je nomemmap
    jmp jmpin
e820lp:
    mov eax, 0xe820         ; eax, ecx get trashed on every int 0x15 call
    mov [es:di + 20], dword 1   ; force a valid ACPI 3.X entry
    mov ecx, 24         ; ask for 24 bytes again
    int 0x15
    jc memmapend            ; carry set means "end of list already reached"
    mov edx, 0x0534D4150        ; repair potentially trashed register
jmpin:
    jcxz skipent            ; skip any 0 length entries
    cmp cl, 20          ; got a 24 byte ACPI 3.X response?
    jbe notext
    test byte [es:di + 20], 1   ; if so: is the "ignore this data" bit clear?
    je skipent
notext:
    mov ecx, [es:di + 8]        ; get lower dword of memory region length
    test ecx, ecx           ; is the qword == 0?
    jne goodent
    mov ecx, [es:di + 12]       ; get upper dword of memory region length
    jecxz skipent           ; if length qword is 0, skip entry
goodent:
    inc bp              ; got a good entry: ++count, move to next storage spot
    add di, 32
skipent:
    test ebx, ebx           ; if ebx resets to 0, list is complete
    jne e820lp
nomemmap:
;   mov byte [cfg_e820], 0      ; No memory map function
memmapend:
    xor eax, eax            ; Create a blank record for termination (32 bytes)
    mov ecx, 8
    rep stosd

    ;mov si, msg_Init2
    ;call print_string_16

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

    mov si, msg_Init3
    call print_string_16

;wait_for_user:
;    mov  cx, 0x5ff
;  wait_some:
;    push cx
;    mov cx, 0xffff
;  inner:
;    loop inner
;    pop  cx
;    loop wait_some

    mov di, VBEModeInfoBlock    ; VBE data will be stored at this address
    mov ax, 0x4F01          ; GET SuperVGA MODE INFORMATION - http://www.ctyme.com/intr/rb-0274.htm
    ; CX queries the mode, it should be in the form 0x41XX as bit 14 is set for LFB and bit 8 is set for VESA mode
    ; 0x4112 is 640x480x24bit, 0x4129 should be 32bit
    ; 0x4115 is 800x600x24bit, 0x412E should be 32bit
    ; 0x4118 is 1024x768x24bit, 0x4138 should be 32bit
    ; 0x411B is 1280x1024x24bit, 0x413D should be 32bit
    mov cx, 0x4118          ; Put your desired mode here
    ;mov cx, 0x411b         ; Put your desired mode here
    mov bx, cx          ; Mode is saved to BX for the set command later
    int 0x10

    cmp ax, 0x004F          ; Return value in AX should equal 0x004F if command supported and successful
    jne halt
    cmp byte [VBEModeInfoBlock.BitsPerPixel], 24    ; Make sure this matches the number of bits for the mode!
    jne halt            ; If set bit mode was unsuccessful then bail out
    or bx, 0x4000           ; Use linear/flat frame buffer model (set bit 14)
    mov ax, 0x4F02          ; SET SuperVGA VIDEO MODE - http://www.ctyme.com/intr/rb-0275.htm
    int 0x10
    cmp ax, 0x004F          ; Return value in AX should equal 0x004F if supported and successful
    je  wait_disp

    mov si, msg_ERR
    call print_string_16
    jmp halt

wait_disp:
    hlt                         ; this was needed for the display to settle

    mov si, msg_OK
    call print_string_16

    call     cont_exec

copy_to_e000:
    ; ON ISO copy it to 0x9000
    ;cld
    ;mov si, 0x7C00+0x200
    ;mov di, 0xe000
    ;mov cx, 4096+8192 ;+4096+8192
    ;mov cx, 4096
    ;rep movsb

    ;mov si, msg_OK
    ;call print_string_16

    ;mov ax, [0x7C00+512 - 2]
    ;cmp ax, 0xaa55         ; Match against the loader
    ;jne sig_fail

    ; Verify that the 2nd stage boot loader was read.
    ;mov ax, [0xe000+6]
    ;cmp ax, 0x3436         ; Match against the Pure64 binary beginning
    ;jne sig_fail

    ;mov al, [0xe000+4096 - 2]
    ;cmp al, 0x90           ; Match against the Pure64 binary end
    ;jne sig_fail

    mov si, msg_Prot
    call print_string_16

msg:
    mov si, msg_OK
    call print_string_16
    ;jmp  msg                  ; test skip mode set

    ; At this point we are done with real mode and BIOS interrupts. Jump to 32-bit mode.
    cli                        ; No more interrupts
    lgdt [cs:GDTR32]           ; Load GDT register
    mov eax, cr0
    or al, 0x01              ; Set protected mode bit
    mov cr0, eax

   jmp  no_prefetch
   nop

  no_prefetch:

align 16
;BITS 32
    ;jmp 8:0xe000             ; Jump to 32-bit protected mode
    jmp 8:DAP_ADDRESS

;BITS 16

read_fail:
    mov si, msg_ReadFail
    call print_string_16
    jmp halt
sig_fail:
    mov si, msg_SigFail
    call print_string_16
halt:
    hlt
    jmp halt
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; 16-bit function to output a string to the serial port
; IN:   SI - Address of start of string
print_string_16:            ; Output string in SI to screen
    pusha
    mov dx, 0             ; Port 0
 .repeat:
    mov ah, 0x01          ; Serial - Write character to port
    lodsb                 ; Get char from string
    cmp al, 0
    je .done              ; If char is zero, end of string
    int 0x14              ; Output the character
    jmp short .repeat
 .done:
    popa
    ret
;------------------------------------------------------------------------------

align 16
GDTR32:                 ; Global Descriptors Table Register
dw gdt32_end - gdt32 - 1        ; limit of GDT (size minus one)
dq gdt32                ; linear address of GDT

align 16
gdt32:
dw 0x0000, 0x0000, 0x0000, 0x0000   ; Null desciptor
dw 0xFFFF, 0x0000, 0x9A00, 0x00CF   ; 32-bit code descriptor
dw 0xFFFF, 0x0000, 0x9200, 0x00CF   ; 32-bit data descriptor
gdt32_end:

msg_Init      db "M", 0
msg_Init2     db "B", 0
msg_Init3     db "R", 0
msg_ERR       db  "DisErr", 10, 0
msg_Prot      db  "Prot", 0
msg_OK        db  " OK", 10, 0
msg_SigFail   db  "SigErr", 0
msg_ReadFail  db  "RdErr", 0

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

; ------------------------------------------------------------------------
; This is padded at the end to load sys stuff

;BITS 32

added:

align 16
cont_exec:

    ; Read the 2nd stage boot loader into memory.

    ; Read PVD (primary volume descriptor)
    ;mov     ax, 0x10

    call    read_disk

    ;cmp word [DAP_ADDRESS+1], 0x4443
    ;jne  cd_err

    mov esi, DAP_ADDRESS
    ;mov ecx, 600
    ;call debug_dump_mem

    ;mov si, path_table_msg
    ;call print_string_16
    ;
    ;mov     ax, [0xe000 + 140]
    ;call    debug_dump_ax
    ;
    ;mov     si, newline
    ;call    print_string_16

    ;mov     ax, [0xe000 + 140]
    ;;mov     ax, 0
    ;call    read_disk
    ;
    ;mov esi, DAP_ADDRESS
    ;mov ecx, 200
    ;call debug_dump_mem

    mov si, msg_long
    mov  cx, 100
    call print_string_16
    ret

;  ax has sector number
read_disk:

    ;mov esi, DAP
    ;add esi, 6
    ;mov word [esi], DAP
    ;mov [DAP + 16], eax

    mov esi, DAP
    mov ah, 0x42                ; Extended Read
    mov dl, [DriveNumber]       ; http://www.ctyme.com/intr/rb-0708.htm

    int 0x13
    jc read_fail

    ;mov esi, DAP_ADDRESS
    ;mov ecx, 2000
    ;call debug_dump_mem

    ret

cd_err:
    mov si, msg_badcd
    call print_string_16
    jmp halt

; esi is address

dump_sector:


    ret

; -----------------------------------------------------------------------------
; debug_dump_(eax|ax|al) -- Dump content of eax, EAX, AX, or AL
;  IN:  eax = content to dump
; OUT:  Nothing, all registers preserved

align 8

debug_dump_eax:
    rol eax, 8
    call debug_dump_al
    rol eax, 8
    call debug_dump_al
    rol eax, 16
debug_dump_ax:
    rol ax, 8
    call debug_dump_al
    rol ax, 8
debug_dump_al:
    push ebx
    push eax
    mov ebx, hextable
    push eax            ; Save eax since we work in 2 parts
    shr al, 4           ; Shift high 4 bits into low 4 bits
    xlatb
    mov [tchar+0], al
    pop eax
    and al, 0x0f            ; Clear the high 4 bits
    xlatb
    mov [tchar+1], al

    push esi
    push ecx
    mov esi, tchar
    mov ecx, 2
    call serial_out
    pop ecx
    pop esi
    pop eax
    pop ebx
    ret

; -----------------------------------------------------------------------------
; debug_dump_mem -- Dump content of memory in hex format
;  IN:  esi = starting address of memory to dump
;   ecx = number of bytes
; OUT:  Nothing, all registers preserved
debug_dump_mem:

    push esi
    push ecx            ; Counter
    push edx            ; Total number of bytes to display
    push eax

    test ecx, ecx           ; Bail out if no bytes were requested
    jz debug_dump_mem_done

    push ecx
    push esi

    mov esi, debug_dump_mem_chars
    call serial_out

    pop esi
    mov eax, esi            ; Output the memory address
    push esi
    call debug_dump_eax

    mov esi, debspace
    call serial_out

    mov esi, debug_dump_mem_len
    call serial_out

    mov eax, ecx            ; Output the memory len
    call debug_dump_ax

    pop esi
    pop ecx

    call debug_dump_mem_newline

 nextline:
    mov dx, 0
 nextchar:
    cmp ecx, 0
    je debug_dump_mem_done_newline
    push esi            ; Output ' '
    push ecx
    mov esi, debspace
    call serial_out
    pop ecx
    pop esi
    lodsb
    call debug_dump_al

    cmp     dx, 7
    jne     nospace

    push esi            ; Output ' '
    mov     esi, debspace
    call    serial_out
    pop esi

  nospace:

    dec ecx
    inc edx
    cmp dx, 16          ; End of line yet?
    jne nextchar


    ; print ascii after
    push    ecx
    push    esi

    mov     esi, debspace
    call    serial_out

    pop     esi                 ; Refresh esi
    push    esi

    sub     esi, 16
    mov     ecx, 16

 more_16:
    lodsb                       ; Get char from string
    cmp     al, ' '             ; fill dot if unprintable
    ja      do_next_1
    mov     al, '.'
    jmp     put_char
  do_next_1:
    cmp     al, 'z'
    jbe     do_next_2
    mov     al, '.'
    jmp     put_char
  do_next_2:
  put_char:
    call    serial_char
    dec     ecx
    cmp     ecx, 0
    jg      more_16              ; If 16 chars end of string

    pop     esi
    pop     ecx

    call debug_dump_mem_newline
    cmp ecx, 0
    je debug_dump_mem_done
    jmp nextline

 debug_dump_mem_done_newline:
    call debug_dump_mem_newline

 debug_dump_mem_done:
    pop eax
    pop ecx
    pop edx
    pop esi
    ret

 debug_dump_mem_newline:
    push esi            ; Output newline
    mov esi, newline
    call serial_out
    pop esi
    ret

; -----------------------------------------------------------------------------
; serial_out  -- Content description
; Output message via serial port
;
;  IN:  esi = starting address of string
;
; OUT:    Nothing
;
; Date/Time: Fri 29.Oct.2021 12:01:44
; -----------------------------------------------------------------------------
; Use:
;       mov esi, message        ; Location of message
;       mov cx, 11

serial_out:

    cld                   ; Clear the direction flag.. we want to increment through the string

    push    edx
    push    eax

    mov     dx, 0x03F8       ; Address of first serial port

 serial_nextchar:
    add dx, 5           ; Offset to Line Status Register
    in al, dx
    sub dx, 5           ; Back to to base
    lodsb               ; Get char from string and store in AL
    cmp al, 0
    je  serial_done
    out dx, al          ; Send the char to the serial port
    jmp serial_nextchar

 serial_done:
    pop     eax
    pop     edx
    ret

; Char in al

serial_char:

    push    edx
    push    eax

    mov     dx, 0x03F8       ; Address of first serial port
    add     dx, 5                ; Offset to Line Status Register
    push    eax
    in      al, dx
    pop     eax
    sub     dx, 5           ; Back to to base
    out     dx, al          ; Send the char to the serial port

    pop     eax
    pop     edx
    ret

; ------------------------------------------------------
console_out:

    mov eax, [VBEModeInfoBlock.PhysBasePtr]     ; Base address of video memory (if graphics mode is set)
    mov edi,  eax

 con_next:

    lodsb
    cmp     al, 0
    je      con_done
    stosb
    jmp con_next

 con_done:

    ret

debug_dump_mem_chars    db 'Addr: 0x', 0
debug_dump_mem_len      db 'Len: 0x', 0
debspace                db " ", 0
hextable                db '0123456789ABCDEF'
tchar                   db          0, 0, 0
newline                 db  10, 0

; This is how much space is in the el-torrito image

;paddx:
;    times 0x5fff db 'a'

path_table_msg  db  "Path table location: ", 0
msg_badcd   db 10, "Not a CD image", 10, 0
msg_long    db 10, "Long message from el torrito boot sector", 10, 0

;%include "modeinfo.inc"

; EOF
