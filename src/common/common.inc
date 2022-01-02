; =============================================================================
; SimpOS -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2021 Peter Glen
; Written: Fri 29.Oct.2021
; =============================================================================

; Macros

%macro   SerMsg32 1
    push    esi
    mov     esi, %1
    call    serial_out
    pop     esi
%endmacro

%macro   SerMsg 1
    push    rsi
    mov     rsi, %1
    call    serial_out
    pop     rsi
%endmacro

%macro DumpMem 2
    push    rcx
    push    rsi
    mov     rsi, %1
    mov     rcx, %2
    call    debug_dump_mem
    pop     rsi
    pop     rcx
%endmacro

%macro SerNum64  1
    push    rax
    mov     rax, %1
    call    debug_dump_rax
    pop     rax
%endmacro

%macro SerNum32  1
    push    rax
    mov     eax, %1
    call    debug_dump_eax
    pop     rax
%endmacro

%macro SerNum16  1
    push    rax
    mov     ax, %1
    call    debug_dump_ax
    pop     rax
%endmacro

%macro Space  0
    SerMsg  space
%endmacro

%macro Newline 0
    SerMsg  newline
%endmacro

; Initial Memory Map
;
; |Begin            |Loader   |Buffer   |Graphics  |Text   |BIOS    |End
; ----------------------------------------------------------------------------
; |0x100                                |A000      |B800   | 0xf000  | 0xffff
;                   | 0x7C00  |0x8000
; |256              | 31744   |32768    |40960     |45056  |61440    | 65535

%define BUFF_ADDR 0x8000

VBEModeInfoBlock: equ 0x5C00

; VESA
; Mandatory information for all VBE revisions
VBEModeInfoBlock.ModeAttributes		equ VBEModeInfoBlock + 0	; DW - mode attributes
VBEModeInfoBlock.WinAAttributes		equ VBEModeInfoBlock + 2	; DB - window A attributes
VBEModeInfoBlock.WinBAttributes		equ VBEModeInfoBlock + 3	; DB - window B attributes
VBEModeInfoBlock.WinGranularity		equ VBEModeInfoBlock + 4	; DW - window granularity in KB
VBEModeInfoBlock.WinSize		equ VBEModeInfoBlock + 6	; DW - window size in KB
VBEModeInfoBlock.WinASegment		equ VBEModeInfoBlock + 8	; DW - window A start segment
VBEModeInfoBlock.WinBSegment		equ VBEModeInfoBlock + 10	; DW - window B start segment
VBEModeInfoBlock.WinFuncPtr		equ VBEModeInfoBlock + 12	; DD - real mode pointer to window function
VBEModeInfoBlock.BytesPerScanLine	equ VBEModeInfoBlock + 16	; DW - bytes per scan line
; Mandatory information for VBE 1.2 and above
VBEModeInfoBlock.XResolution		equ VBEModeInfoBlock + 18	; DW - horizontal resolution in pixels or characters
VBEModeInfoBlock.YResolution		equ VBEModeInfoBlock + 20	; DW - vertical resolution in pixels or characters
VBEModeInfoBlock.XCharSize		equ VBEModeInfoBlock + 22	; DB - character cell width in pixels
VBEModeInfoBlock.YCharSize		equ VBEModeInfoBlock + 23	; DB - character cell height in pixels
VBEModeInfoBlock.NumberOfPlanes		equ VBEModeInfoBlock + 24	; DB - number of memory planes
VBEModeInfoBlock.BitsPerPixel		equ VBEModeInfoBlock + 25	; DB - bits per pixel
VBEModeInfoBlock.NumberOfBanks		equ VBEModeInfoBlock + 26	; DB - number of banks
VBEModeInfoBlock.MemoryModel		equ VBEModeInfoBlock + 27	; DB - memory model type
VBEModeInfoBlock.BankSize		equ VBEModeInfoBlock + 28	; DB - bank size in KB
VBEModeInfoBlock.NumberOfImagePages	equ VBEModeInfoBlock + 29	; DB - number of image pages
VBEModeInfoBlock.Reserved		equ VBEModeInfoBlock + 30	; DB - reserved (0x00 for VBE 1.0-2.0, 0x01 for VBE 3.0)
; Direct Color fields (required for direct/6 and YUV/7 memory models)
VBEModeInfoBlock.RedMaskSize		equ VBEModeInfoBlock + 31	; DB - size of direct color red mask in bits
VBEModeInfoBlock.RedFieldPosition	equ VBEModeInfoBlock + 32	; DB - bit position of lsb of red mask
VBEModeInfoBlock.GreenMaskSize		equ VBEModeInfoBlock + 33	; DB - size of direct color green mask in bits
VBEModeInfoBlock.GreenFieldPosition	equ VBEModeInfoBlock + 34	; DB - bit position of lsb of green mask
VBEModeInfoBlock.BlueMaskSize		equ VBEModeInfoBlock + 35	; DB - size of direct color blue mask in bits
VBEModeInfoBlock.BlueFieldPosition	equ VBEModeInfoBlock + 36	; DB - bit position of lsb of blue mask
VBEModeInfoBlock.RsvdMaskSize		equ VBEModeInfoBlock + 37	; DB - size of direct color reserved mask in bits
VBEModeInfoBlock.RsvdFieldPosition	equ VBEModeInfoBlock + 38	; DB - bit position of lsb of reserved mask
VBEModeInfoBlock.DirectColorModeInfo	equ VBEModeInfoBlock + 39	; DB - direct color mode attributes
; Mandatory information for VBE 2.0 and above
VBEModeInfoBlock.PhysBasePtr		equ VBEModeInfoBlock + 40	; DD - physical address for flat memory frame buffer
VBEModeInfoBlock.Reserved1		equ VBEModeInfoBlock + 44	; DD - Reserved - always set to 0
VBEModeInfoBlock.Reserved2		equ VBEModeInfoBlock + 48	; DD - Reserved - always set to 0


; EOF