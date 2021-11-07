; =============================================================================
; SimpOS -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2021 Peter Glen
; Written: Sun 24.Oct.2021
; =============================================================================

%macro TAB 0
    push rsi
    mov rsi, tab
    call output_mon
    pop rsi
%endmacro

%macro SPACE 0
    push rsi
    push rdx

    mov rdx, 1
    mov rsi, space
    call output_mon

    pop rdx
    pop rsi

%endmacro

%macro  DOSTR 0
    mov rdi, temp_string
    mov rsi, rdi
    call string_from_int
    mov rdx, 1
    call output_mon
%endmacro

; -----------------------------------------------------------------------------
; mon_debug_dump_(rax|eax|ax|al) -- Dump content of RAX, EAX, AX, or AL
;  IN:    RAX = content to dump
; OUT:    Nothing, all registers preserved

align 16

mon_debug_dump_rax:

    rol rax, 8
    call mon_debug_dump_al
    rol rax, 8
    call mon_debug_dump_al
    rol rax, 8
    call mon_debug_dump_al
    rol rax, 8
    call mon_debug_dump_al
    rol rax, 32

mon_debug_dump_eax:
    rol eax, 8
    call mon_debug_dump_al
    rol eax, 8
    call mon_debug_dump_al
    rol eax, 16
mon_debug_dump_ax:
    rol ax, 8
    call mon_debug_dump_al
    rol ax, 8

mon_debug_dump_al:
    push rbx
    push rax
    push rdx

    mov rdx, 0

    cld
    mov rbx, hextable
    push rax            ; Save RAX since we work in 2 parts
    shr al, 4            ; Shift high 4 bits into low 4 bits
    xlatb
    mov [tchar+0], al
    pop rax
    and al, 0x0f            ; Clear the high 4 bits
    xlatb
    mov [tchar+1], al
    push rsi
    push rcx
    mov rsi, tchar
    mov rcx, 2

    mov rdx, 0
    call output_mon

    mov rsi, space
    mov rcx, 1
    mov rdx, 0
    call output_mon

    pop rcx
    pop rsi
    pop rdx
    pop rax
    pop rbx
    ret
; -----------------------------------------------------------------------------

%macro  OUTS 1

    push    rsi
    mov     rsi, %1
    push    rdx
    mov    rdx, 0
    call   output_mon
    pop     rdx
    pop     rsi

%endmacro

; -----------------------------------------------------------------------------
; mon_debug_dump_mem -- Dump content of memory in hex format
;  IN:    RSI = starting address of memory to dump
;    RCX = number of bytes
; OUT:    Nothing, all registers preserved

mon_debug_dump_mem:
    push rsi
    push rcx            ; Counter
    push rdx            ; Total number of bytes to display
    push rax

    test rcx, rcx            ; Bail out if no bytes were requested
    jz mon_debug_dump_mem_done

    push rsi            ; Output '0x'
    push rcx
    mov rsi, xaddr
    mov rcx, 4
    mov rdx, 0
    call output_mon
    pop rcx
    pop rsi

    push rax
    mov rax, rsi            ; Output the memory address
    push rsi
    call mon_debug_dump_rax
    call mon_debug_dump_mem_colon
    call mon_debug_dump_mem_newline
    pop rsi
    pop rax

 nextline:
    push rsi
    mov rsi, space
    mov rdx, 0
    call output_mon
    pop rsi
    mov dx, 0

 nextchar:
    cmp rcx, 0
    je mon_debug_dump_mem_done_newline

    lodsb
    call mon_debug_dump_al
    dec rcx
    inc rdx

    cmp dx, 8            ; Middle of line yet?
    jne nospace16
    OUTS space
    OUTS space

  nospace16:
    cmp dx, 16            ; Middle of line yet?
    jne nextchar
    call mon_debug_dump_mem_newline
    jmp nextline

    cmp rcx, 0
    je mon_debug_dump_mem_done
    jmp nextline

 mon_debug_dump_mem_done_newline:
    call mon_debug_dump_mem_newline

 mon_debug_dump_mem_done:
    pop rax
    pop rcx
    pop rdx
    pop rsi
    ret

 mon_debug_dump_mem_newline:
    push rsi            ; Output newline
    push rcx
    push rdx
    mov rsi, retx
    mov rcx, 1
    mov rdx, 0
    call output_mon
    pop rdx
    pop rcx
    pop rsi
    ret

 mon_debug_dump_mem_colon:
    push rsi            ; Output colon
    push rcx
    mov rsi, colon
    mov rcx, 1
    call output_mon
    pop rcx
    pop rsi
    ret

; -----------------------------------------------------------------------------
; Funcname  -- Content description
;
;  IN:  RSI = starting address of memory to dump
;       RCX = number of bytes
;
; OUT:    Nothing
;
;       All registers preserved
;
; Date/Time: Sun 24.Oct.2021 16:58:43
; -----------------------------------------------------------------------------

show_memap:

    ; Output memory map
    mov rdx, 1

    mov rsi, memapmsg
    call output_mon

    xor rax, rax
    mov rsi, 0x6000
    mov rcx, 25
    cld

 again_mm:

    push rcx

    ; begin mem ptr
    lodsq
    call str_from_hex
    SPACE

    ; mem size
    lodsq
    cmp rax, 0
    je  done_mem
    call str_from_hex
    SPACE

    ; type
    lodsd
    cmp ax, 1
    jne nogood

    ;push rsi
    ;mov rsi, colon
    ;call output
    ;pop rsi

 nogood:

    call str_from_hex32
    SPACE

    ; attributes
    lodsd
    push rsi
    call str_from_hex32
    SPACE
    pop rsi

    ; padding
    ;xor rax, rax
    lodsq
    push rsi
    call str_from_hex
    SPACE
    pop rsi

    push rsi
    mov rsi, newline
       mov rdx, 1
    call output_mon
    pop rsi

    pop  rcx
    dec  rcx
    cmp  rcx, 0
    jne  again_mm
    ret

 done_mem:

    push rsi
    mov rsi, newline
      mov rdx, 1

    call output_mon
    call output_mon
    pop rsi


    pop rcx
    ret

; -----------------------------------------------------------------------------
; str_from_hex  -- Content description
;
;  IN:  RAX = number to put yo screen
;
; OUT:    Nothing
;
;       All registers preserved
;
; Date/Time: Sun 24.Oct.2021 17:35:17
; -----------------------------------------------------------------------------

str_from_hex:

    push rax
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    rol rax, 8
    call disp_hex
    pop rax
    ret

str_from_hex32:

    push rax
    rol eax, 8
    call disp_hex
    rol eax, 8
    call disp_hex
    rol eax, 8
    call disp_hex
    rol eax, 8
    call disp_hex
    pop rax
    ret

str_from_hex16:

    push rax
    rol ax, 8
    call disp_hex
    rol ax, 8
    call disp_hex
    pop rax
    ret

disp_hex:               ; Hex in AL

    push rbx
    push rdx
    push rax
    cld

    mov rbx, hextable
    push rax            ; Save RAX since we work in 2 parts
    shr al, 4            ; Shift high 4 bits into low 4 bits
    xlatb
    mov [tchar+0], al
    pop rax
    and al, 0x0f            ; Clear the high 4 bits
    xlatb
    mov [tchar+1], al
    push rsi
    push rcx
    mov rsi, tchar
    mov rcx, 2
    mov rdx, 1

    call output_mon

    pop rcx
    pop rsi
    pop rax
    pop rdx
    pop rbx
    ret

; EOF
