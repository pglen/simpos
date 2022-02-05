
;********************************************************************;
;*                      x86 Master partition Record                 *;
;*                   github.com/egormkn/bootloader                  *;
;*                       edited by peter glen                       *;
;********************************************************************;

; Sat 29.Jan.2022 adapted from original
; Sun 30.Jan.2022 cleared [bypassed] 0x42 check
; Sun 30.Jan.2022 filled DAP

; This is re-written to have more verbose error reporting; and yeah
; the ugly delay to read the screen was in the way of instant boot;
; Also, the extended bios int 13h test does not work on virtual
; platforms - all good

%define BASE 0x7C00             ; Address at which BIOS will load MBR
%define DEST 0x0600             ; Address at which MBR should be copied
%define SIZE 512                ; MBR sector size (default: 512 bytes)
%define ENTRY_SIZE 16           ; Partition table entry size
%define ENTRY_NUM 4             ; Number of partition entries
%define DISK_ID 0x00000000      ; NT Drive Serial Number (4 bytes)
%define SHIFT_MEM (BASE-DEST)   ; This many bytes for memory shift to target

%define  DAP_SECTORS        1
%define  DAP_ADDRESS        0x7c00
%define  DAP_SEGMENT        0
%define  DAP_STARTSECTOR    1

;********************************************************************;
;*                           NASM settings                          *;
;********************************************************************;

[BITS 16]                   ; Enable 16-bit real mode
[ORG BASE]                  ; Set the base address for MBR

;********************************************************************;
;*                         Prepare registers                        *;
;********************************************************************;

begin:

    xor ax, ax                  ; Zero out the Accumulator register
    mov ss, ax                  ; Zero out Stack Segment register
    mov sp, BASE                ; Set Stack Pointer to BASE
    mov es, ax                  ; Zero out Extra Segment register
    mov ds, ax                  ; Zero out Data Segment register

    mov [drive_number], dl

;********************************************************************;
;*                  Copy MBR to DEST and jump there                 *;
;********************************************************************;

    mov si, BASE                ; Source Index to copy code from
    mov di, DEST                ; Destination Index to copy code to
    mov cx, SIZE                ; Number of bytes to be copied

    cld                         ; clear Direction Flag (move forward)
    rep movsb                   ; Repeat MOVSB instruction for CX times

    ; Invalidate the buffer by putting bad opcode in it
    ;mov  word [BASE], 0x0B0F

    push ax                     ; Push continuation address to stack
    push SKIP + DEST            ;  to jump to SKIP in the copied code
    retf                        ; jump to copied code skipping part above

align 4

SKIP: EQU ($ - $$)              ; Go here in copied code

;********************************************************************;
;*                   Check for an Active partition                  *;
;********************************************************************;

    sti                         ; enable interrupts

    ;mov     si, sign_on
    ;call    print_string_16

    ;mov     al, [drive_number]
    ;call    print_num_16

    mov cx, ENTRY_NUM           ; Maximum of four entries as loop counter
    mov bp, TABLE_OFFSET + DEST ; Location of first entry in the table

find_active:

    cmp byte [bp], 0            ; Subtract 0 from first byte of entry at
                                ; SS:[BP]. Anything from 80h to FFh has 1
                                ; in highest bit (Sign Flag will be set)

    jl boot_partition           ; Active partition found (SF set), boot
    jnz print_partition         ; Active flag is not zero, show an error
                                ; Otherwise, we found a zero, check other

    add bp, ENTRY_SIZE          ; Switch to the next partition entry
    loop find_active            ; Check next entry unless CL = 0

    mov     si, invalid_error
    call    print_string_16

    ;int 0x18                    ; Start ROM-BASIC or display an error
    jmp halt

boot_partition:                 ; Boot from selected partition
                                ; bp holds the entry pointer

;********************************************************************;
;*              Select the way of working with the disk             *;
;********************************************************************;

; This needed to updated, as the virtual systems do not implement
; this check, as it is assumed the the ah=0x42 is present.
; In 2020 this is a reasonable assumption

    jmp int13_extended           ; all the hard work ... going around

                                 ; used as disk number (first HDD = 80h)
    ;push bp                     ; save Base Pointer on Stack
    ;mov byte [bp+0x11], 5       ; Number of attempts of reading the disk
    ;mov byte [bp+0x10], 0       ; Used as a flag for the INT13 Extensions
    ;
    ;mov ah, 0x41                ;/ INT13h BIOS Extensions check
    ;mov bx, 0x55aa              ;| AH = 41h, BX = 55AAh, DL = 80h
    ;int 0x13                    ;| if CF flag cleared and [BX] changes to
    ;                            ;| aa55h, they are installed
    ;                            ;| major version is in AH: 01h=1.x;
    ;                            ;| 20h=2.0/edd-1.0; 21h=2.1/edd-1.1;
    ;                            ;| 30h=EDD-3.0.
    ;                            ;| CX = API subset support bitmap.
    ;                            ;| If bit 0 is set, extended disk access
    ;                            ;| functions (AH=42h-44h,47h,48h) are
    ;                            ;| supported. Only if no extended support
    ;                            ;\ is available, will it fail TEST
    ;
    ;pop bp                      ; Get back original Base Pointer.
    ;jb no_int13                 ; Below? If so, CF=1 (not cleared)
    ;                            ;   so no INT 13 Ext. & do jump!
    ;cmp bx, 0xaa55              ; Did contents of BX change?  If
    ;jnz no_int13                ;   not, jump to offset 0659.
    ;test cx, 0001               ; Final test for INT 13 Extensions!
    ;                            ; if bit 0 not set, this will fail,
    ;jz no_int13                 ;   then we jump over next line...
    ;inc byte [bp+0x10]          ; or increase [BP+10h] by one.
    ;
    ;no_int13:
    ;pushad                      ; Save all 32-bit Registers on the stack
    ;                            ; (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI)
    ;
    ;cmp byte [bp+0x10], 00      ; Compare [BP+0x10] to zero;
    ;jz int13_basic              ; If 0, can't use Extensions

;********************************************************************;
;*                 Read VBR with INT13 Extended Read                *;
;********************************************************************;

; The following code uses INT 13, Function 42h ("Extended Read")
; by first pushing the "Disk Address Packet" onto the Stack in
; reverse order of how it will read the data
;
; Offset Size	       Description of DISK ADDRESS PACKET's Contents
; ------ -----  ------------------------------------------------------
;   00h  BYTE	Size of packet (10h or 18h; 16 or 24 bytes).
;   01h  BYTE	Reserved (00).
;   02h  WORD	Number of blocks to transfer (Only 1 sector for us)
;   04h  DWORD	Points to -> Transfer Buffer (00007C00 for us).
;   08h  QWORD	Starting Absolute Sector (get from Partition Table:
;                (00000000 + DWORD PTR [BP+08]). Remember, the
;                Partition Table Preceding Sectors entry can only be
;                a max. of 32 bits!
;   10h  QWORD   (EDD-3.0, optional) 64-bit flat address of transfer
;                buffer; only used if DWORD at 04h is FFFF:FFFF

int13_extended:

    mov     si, booting - SHIFT_MEM
    call    print_string_16

    ;push strict dword 0x0       ; Push 4 zero-bytes (32-bits) onto
                                 ; stack to pad VBR's Starting Sector
    mov     eax,  [BP+0x08]
    mov     [DAP + 0x08], eax

    ; Dump DAP
    ;mov     si, DAP
    ;add     si, 8
    ;mov     cx, 16
    ;call    dump_mem

    ; Copy it over
    mov     dl, [drive_number]
    mov     [drive_number - SHIFT_MEM], dl

    ; Show drive number
    ;mov     si, drive_number - SHIFT_MEM
    ;mov     cx, 1
    ;call    dump_mem

    mov     ah, 0x42                ; Function 42h
    mov     dl, [drive_number]
    mov     si, DAP
    int     0x13                    ; Try to get VBR Sector from disk

    ; If successful, CF is cleared (0) and AH set to 00h.
    jnc     jump_final

    ; If any errors, CF is set to 1    and AH = error code. In either case,
    ; DAP's block count field is set to number of blocks actually transferred

    push    ax
    mov     si, newline - SHIFT_MEM
    call    print_string_16

    mov     si, loading_error - SHIFT_MEM
    call    print_string_16
    pop     ax

    mov     al, ah
    call    print_num_16

    mov     si, space  - SHIFT_MEM
    call    print_string_16

    mov     al, [drive_number]
    call    print_num_16

    jmp     halt

jump_final:

    cmp     word [BASE + SIZE -2], 0xaa55
    je      final_go

    mov     si, nosig - SHIFT_MEM
    call    print_string_16

    jmp     halt

final_go:

    mov     si, final - SHIFT_MEM
    call    print_string_16

    mov     dl, [drive_number - SHIFT_MEM]

    ;mov     dl, 0x80
    ;mov     al,dl
    ;call    print_num_16 - SHIFT_MEM

    ;xor     ax,ax
    ;push    ax                 ; Push continuation address to stack
    ;push    BASE               ;  to jump to the loaded code
    ;retf                       ; jump to copied code skipping part above

    jmp 0x0000:0x7c00           ; Jump to Volume Boot Record code
                                ; loaded into Memory by this MBR.


    ;int 0x18              ; Is this instruction here to meet some specification of TPM v 1.2 ?
    ;                      ; The usual 'INT18 if no disk found' is in the code above at 0632.



; ------------------------------------------------------------------------
; si to point to memory, cx number of bytes to dump

dump_mem:

    ;mov      al, [si]
    ;inc      si
    lodsb
    call     print_num_16
    push     si
    mov      si, space
    call     print_string_16
    pop si
    loop     dump_mem
    ret

;********************************************************************;
;*          Trusted Platform Module support (hardcoded here)        *;
;********************************************************************;

; deleted Sun 30.Jan.2022

;; =====================================================================
;;   All of the code from 06C6 through 0726 is related to discovering if
;; TPM version 1.2 interface support is operational on the system, since
;; it could be used by  BitLocker for validating the integrity of a PC's
;; early startup components before allowing the OS to boot. The spec for
;; the TPM code below states "There MUST be no requirement placed on the
;; A20 state on entry to these INT 1Ah functions." (p.83) We assume here
;; Microsoft understood this to mean access to memory over 1 MiB must be
;; made available before entering any of the TPM's INT 1Ah functions.
;
;; The following code is actually a method for gaining access to Memory
;; locations above 1 MiB (also known as enabling the A20 address line).
;;
;; Each address line allows the CPU to access ( 2 ^ n ) bytes of memory:
;; A0 through A15 can give access to 2^16 = 64 KiB. The A20 line allows
;; a jump from 2^20 (1 MiB) to 2^21 = 2 MiB in accessible memory.  But
;; our computers are constructed such that simply enabling the A20 line
;; also allows access to any available memory over 1 MiB if both the CPU
;; and code can handle it (once outside of "Real Mode"). Note: With only
;; a few minor differences, this code at 06C6-06E1 and the Subroutine at
;; A20_CHECK_WAIT ff. are the same as rather old sources we found on the Net.
;
;06C6 e88d00        CALL   0756
;06C9 7517          JNZ    A20_CHECK_WAIT
;
;06CB FA            CLI           ; Clear IF, so CPU ignores maskable interrupts.
;06CC B0D1          MOV    AL,D1
;06CE E664          OUT    64,AL
;06D0 E88300        CALL   A20_CHECK_WAIT
;
;06D3 B0DF          MOV    AL,DF
;06D5 E660          OUT    60,AL
;06D7 E87C00        CALL   A20_CHECK_WAIT
;
;06DA B0FF          MOV    AL,FF
;06DC E664          OUT    64,AL
;06DE E87500        CALL   A20_CHECK_WAIT
;06E1 FB            STI           ; Set IF, so CPU can respond to maskable interrupts
;                                 ; again, after the next instruction is executed.
;
;; Comments below checked with the document, "TCG PC Client Specific
;; Implementation Specification For Conventional BIOS" (Version 1.20
;; FINAL/Revision 1.00/July 13, 2005/For TPM Family 1.2; Level 2), �
;; 12.5, pages 85 ff.  TCG and "TCG BIOS DOS Test Tool" (MSDN).
;
;06E2 B800BB        MOV    AX,BB00   ; With AH = BBh and AL = 00h
;06E5 CD1A          INT    1A        ; Int 1A ->  TCG_StatusCheck
;
;06E7 6623C0      * AND    EAX,EAX  ;/   If EAX does not equal zero,
;06EA 753B          JNZ    0727     ;\ then no BIOS support for TCG.
;
;06EC 6681FB544350+  * CMP  EBX,41504354   ; EBX must also return ..
;                                         ; the numerical equivalent
;; of the ASCII character string "TCPA" ("54 43 50 41") as a further
;; check. (Note: Since hex numbers are stored in reverse order on PC
;; media or in Memory, a TPM BIOS would put 41504354h in EBX.)
;
;06F3 7532             JNZ    0727       ;  If not, exit TCG code.
;06F5 81F90201         CMP    CX,0102    ; Version 1.2 or higher ?
;06F9 722C             JB     0727       ;  If not, exit TCG code.
;
;; If TPM 1.2 found, perform a: "TCG_CompactHashLogExtendEvent".
;
;06FB 666807BB0000   * PUSH   0000BB07   ; Setup for INT 1Ah AH = BB,
;                                        ; AL = 07h command (p.94 f).
;0701 666800020000   * PUSH   00000200   ;
;0707 666808000000   * PUSH   00000008   ;
;070D 6653           * PUSH   EBX        ;
;070F 6653           * PUSH   EBX        ;
;0711 6655           * PUSH   EBP        ;
;0713 666800000000   * PUSH   00000000   ;
;0719 6668007C0000   * PUSH   00007C00   ;
;071F 6661           * POPAD             ;
;0721 680000         * PUSH   0000       ;
;0724 07               POP    ES         ;
;0725 CD1A             INT    1A
;
;; On return, "(EAX) = Return Code as defined in Section 12.3" and
;;            "(EDX) = Event number of the event that was logged".
;; =====================================================================

;DB 0xE8, 0x8D, 0x00, 0x75, 0x17, 0xFA, 0xB0, 0xD1, 0xE6, 0x64, 0xE8, 0x83
;DB 0x00, 0xB0, 0xDF, 0xE6, 0x60, 0xE8, 0x7C, 0x00, 0xB0, 0xFF, 0xE6, 0x64
;DB 0xE8, 0x75, 0x00, 0xFB, 0xB8, 0x00, 0xBB, 0xCD, 0x1A, 0x66, 0x23, 0xC0
;DB 0x75, 0x3B, 0x66, 0x81, 0xFB, 0x54, 0x43, 0x50, 0x41, 0x75, 0x32, 0x81, 0xF9
;DB 0x02, 0x01, 0x72, 0x2C, 0x66, 0x68, 0x07, 0xBB, 0x00, 0x00, 0x66, 0x68
;DB 0x00, 0x02, 0x00, 0x00, 0x66, 0x68, 0x08, 0x00, 0x00, 0x00, 0x66, 0x53
;DB 0x66, 0x53, 0x66, 0x55, 0x66, 0x68, 0x00, 0x00, 0x00, 0x00, 0x66, 0x68
;DB 0x00, 0x7C, 0x00, 0x00, 0x66, 0x61, 0x68, 0x00, 0x00, 0x07, 0xCD, 0x1A


;********************************************************************;
;*                        Jump to loaded VBR                        *;
;********************************************************************;

;********************************************************************;
;*                   Print errors by jumping here                   *;
;********************************************************************;

; Note: When the last character of any Error Message has been displayed, the
; instructions at offsets 0748, 0753 and 0754 lock computer's execution into
; a never ending loop! You must reboot the machine.  INT 10, Function 0Eh
; (Teletype Output) is used to display each character of these error messages.

;print_missing:
;    mov si, missing_error
;    jmp print_error
;
;print_loading:
;    mov si,  loading_error
;    jmp print_error
;
print_partition:
    mov si,  invalid_error
    jmp print_error

;********************************************************************;
;*                  Subroutine that prints text                     *;
;********************************************************************;

;print_str:
;    lodsb                   ; Load character into AL from [SI]
;    cmp al, 0               ; Check for end of string
;    je  .end_print
;    mov ah, 0x0e            ; Character print function
;    int 0x10                ;
;    jmp print_str
;  .end_print:
;    ret

;********************************************************************;
;*               Subroutine that prints an error text               *;
;********************************************************************;

print_error:
    ;xor ah, ah              ; Zero-out AH
    ;add ax, DEST + 0x100    ; Add 0x700 to offset passed in AL
    mov si, ax              ; Put string offset to SI register

    print_character:
    lodsb                   ; Load character into AL from [SI]
    cmp al, 0               ; Check for end of string
    jz halt                 ; Halt if string is printed
    mov bx, 0x7             ; Display page 0, white on black
    mov ah, 0x0e            ; Character print function
    int 0x10                ;
    jmp print_character     ; Go back for another character...

halt:
    hlt
    jmp halt

; ------------------------------------------------------------------------

print_char_16:              ; Output char in al
    mov ah,0xe
    int 0x10                ; Output the character
    ret

;------------------------------------------------------------------------------

print_num_16:               ; Output value in al

    push    ax

    shr al, 4
    and al, 0xf

    cmp al, 9
    jg  .hexx
    add al, '0'
    jmp .put
  .hexx:
    add al, 'A' - 10
  .put:
    mov ah,0xe
    int 0x10                ; Output the character
    pop ax

    and al, 0xf
    cmp al, 9
    jg  .hexx2
    add al, '0'
    jmp .put2
  .hexx2:
    add al, 'A' - 10
  .put2:
    mov ah,0xe
    int 0x10                ; Output the character
    ret

;------------------------------------------------------------------------------
; 16-bit function to output a string to the serial port
; IN:    SI - Address of start of string
print_string_16:            ; Output string in SI to screen
    pusha
    mov bx, 0
    mov dx, 0                ; Port 0
 .repeat:
    mov ah, 0x01            ; Serial - Write character to port
    lodsb                    ; Get char from string
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

;********************************************************************;
;*              Subroutine of A20 line enablement code              *;
;********************************************************************;

; This routine checks/waits for access to KB controller
;
;a20_check_wait:
;    sub cx, cx                  ; Sets CX = 0  NASM USES ANOTHER INSTRUCTION
;    check_something:
;        in al, 0x64             ; Check port 64h
;        jmp unused_jump         ; Seems odd, but this is how it's done
;        unused_jump:
;        and al, 2                    ; Test for only 'Bit 1' *not* set
;        loopne check_something       ; Continue to check (loop) until
;                                     ; cx = 0 (and ZF=1); it's ready
;    and al, 2
;    ret

nosig           db  'No AA55 sig', 10, 13, 0
final           db  'JMP to OS ', 10, 13, 0
;sign_on        db  'Starting boot sector'
newline         db  10, 13, 0
booting         db  'Booting ... ', 0
space           db  ' ', 0
drive_number:   db  0

;********************************************************************;
;*                          Error messages                          *;
;********************************************************************;

;invalid_error: DB "No patitions.", 10, 13,  0
invalid_error: DB "MBR No bootable patitions found.", 10, 13,  0
loading_error: DB "MBR Error on disk read. ", 10, 13, 0
missing_error: DB "MBR No operating system found. ", 10, 13, 0

DAP:
    db 0x10             ; 0
    db 0x00             ; 1
    dw DAP_SECTORS      ; 2
    dw DAP_ADDRESS      ; 4
    dw DAP_SEGMENT      ; 6
    dq DAP_STARTSECTOR  ; 8

DW 0x0000
DD DISK_ID
DW 0x0000

;********************************************************************;
;*                    Partition Table + Alignment                   *;
;********************************************************************;

TABLE_SIZE: EQU (ENTRY_NUM * ENTRY_SIZE)    ; Should be 4*16 = 64
TABLE_OFFSET: EQU (SIZE - TABLE_SIZE - 2)   ; Should be 512-64-2 = 446

padd:

TIMES TABLE_OFFSET - ($ - $$) DB 0x90       ; Fill up to 446 bytes with 'nop'

endd:

%assign num endd-padd
%warning "padding available" num

TIMES TABLE_SIZE DB 0x00    ; Fill partition table with 0x00

; End of file

DB  0x55, 0xAA               ; Mark sector as bootable

; EOF

