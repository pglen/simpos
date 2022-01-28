
; =============================================================================
; This Master Boot Record will load the secondary boot code.
; Some brain damaged engineer allocated 512 bytes for boot code .. useful for
; practically nothing. So we load a secondary boot code from right after
; the boot sector.
; No, really, brain damaged. Even a 1.44 floppy had enoough sectors for 1024
; boot bytes. (2880 sectors / 2) = 0.13 % of total space
; =============================================================================

; Default location of the second stage boot loader is the next two sectors

%include "../../../common/common.inc"

%define DAP_SECTORS 2
%define DAP_STARTSECTOR 1 + 2048
%define DAP_ADDRESS SEC_ADDR
%define DAP_SEGMENT 0x0000

BITS 16
org 0x7C00

entry:
    jmp start

    db  "SimpOS  ", 0

align 4

start:
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

    ;mov si, msg_Init
    ;call print_string_16

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
    ;mov al, [SEC_ADDR + 3]
    ;call print_char_16
    ;mov al, [SEC_ADDR + 4]
    ;call print_char_16
    ;mov al, [SEC_ADDR + 5]
    ;call print_char_16
    ;mov al, [SEC_ADDR + 6]
    ;call print_char_16

    cmp word [SEC_ADDR + 3], 0x4553
    jne op_fail

    mov si, msg_OK
    call print_string_16

success:
    mov si, crlf
    call print_string_16

    mov dl, [DriveNumber]        ; http://www.ctyme.com/intr/rb-0708.htm
    ; jump to secodary boot sector
    jmp SEC_ADDR

; Fail, show error
halt:
    hlt
    jmp halt

;------------------------------------------------------------------------------
; 16-bit function to output a string to the serial port AND to the terminal
; IN:    SI - Address of start of string

print_string_16:            ; Output string in SI to screen
    pusha
    mov bx, 0
    mov dx, 0               ; Port 0
 .repeat:
    mov ah, 0x01            ; Serial - Write character to port
    lodsb                   ; Get char from string
    cmp al, 0
    je .done                ; If char is zero, end of string
    int 0x14                ; Output the character
    mov ah,0xe
    int 0x10                ; Output the character
    jmp short .repeat
 .done:
    popa
    ret

;------------------------------------------------------------------------------
; 16 bit function to output the value of the al register


print_char_16:                  ; Output char in al
    mov     ah,0xe
    int     0x10                ; Output the character
    ret

msg_Init        db "Init ", 0
msg_Read        db "Read ", 0
msg_Sig         db "Signature ", 0

msg_OK          db "OK ", 0
msg_ERR         db "ERR ", 0

crlf            db 10, 13, 0

padd:
times 446-$+$$ db 0
endd:

;%assign num endd-padd
;%warning "padding available" num

; False partition table entry required by some BIOS vendors.
db 0x80, 0x00, 0x01, 0x00, 0xEB, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF
DriveNumber db 0x00

op_fail:

    ;mov     al, ah
    ;call    print_num_16

    mov     si, msg_ERR
    call    print_string_16

    jmp     halt

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
