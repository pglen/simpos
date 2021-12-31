; =============================================================================
; Simpos -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2021-2022 Peter Glen
;
; Initialize Keyboard / Mouse
; =============================================================================

PS2_ENABLE_AUX_INPUT    equ 0xAE
PS2_ENABLE_AUX_INPUT2   equ 0xA8

;outportb(0x64, PS2_ENABLE_AUX_INPUT);


DELAY_ONE    equ  0x8ffffff

; -----------------------------------------------------------------------------
; Mostly for testing
;
; use:
    ;mov rax, 0x8ffffff     ; appx 1 sec
    ;call useless_delay

keyb_init    db     'keyb_init', 10, 0
keyb_done    db     'keyb_done', 10, 0

align 8

useless_delay:

  cnt_again:
    nop
    nop
    dec     rax
    jnz     cnt_again
    ret

wait_kb:
    in      al, 0x64
    test    al, 0x02
    jnz      wait_kb
    ret

; -----------------------------------------------------------------------------
init_kb:


    mov esi, keyb_init
    call serial_out

    ; Disable KB
    mov al, 0xad
    out 0x64, al
    call wait_kb

    mov al, 0xa7
    out 0x64, al
    call wait_kb

    in  al, 0x60

    ; Status
    mov al, 0x20
    out 0x64, al
    call wait_kb
    in  al, 0x60
    push    rax

    ; Enable KB
    mov al, PS2_ENABLE_AUX_INPUT
    out 0x64, al
    call wait_kb

    mov al, PS2_ENABLE_AUX_INPUT2
    out 0x64, al
    call wait_kb

    ; Enable interrupts and clocks
    mov al, 0x60
    out 0x64, al
    call wait_kb

    pop     rax

    ;xor al, al
    and al,  ~0x30
    or  al,   3
    out 0x60, al
    call wait_kb

    in  al, 0x60

    ;mov al, 0xF6
    ;out 0x64, al
    ;call wait_kb
    ;
    ;mov al, 0xF4
    ;out 0x64, al
    ;call wait_kb

    mov al, 0xFF
    out 0x64, al
    call wait_kb

    ;mov rax, 0x3 * DELAY_ONE
    ;call useless_delay

    ; Pulse output
    ;mov al, 0xf6
    ;out 0x64, al
    ;call wait_kb
    ;
    ;mov al, 0xf4
    ;out 0x64, al
    ;call wait_kb

    mov esi, keyb_done
    call serial_out

    ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
