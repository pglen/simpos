; =============================================================================
; SimpOS -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2021 Peter Glen
; Written: Sun 31.Oct.2021

; History:
;           Fri 05.Nov.2021 - de tabify, add token scan, commets flush
;
; =============================================================================

; -----------------------------------------------------------------------------
; string_length -- Return length of a string
;
;  IN:    RSI = string location
; OUT:    RCX = length (not including the NULL terminator)
;    All other registers preserved

string_length:
    push rdi
    push rax

    xor ecx, ecx
    xor eax, eax
    mov rdi, rsi
    not rcx
    cld
    repne scasb                         ; compare byte at RDI to value in AL
    not rcx
    dec rcx

    pop rax
    pop rdi
    ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; string_scan -- Return position of char
;  IN:    RSI = string location
;         RCX = string lenght
;         AL  = char to search for
; OUT:    RCX = position of found character
;    All other registers preserved

string_scan:
    push rdi
    push rax

    mov rdi, rsi
    cld
    repne scasb                         ; compare byte at RDI to value in AL
    ;dec rcx

    pop rax
    pop rdi
    ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; string_compare -- See if two strings match
;  IN:    RSI = string one
;         RDI = string two
; OUT:    Carry flag set if same

string_compare:

    push rsi
    push rdi
    push rbx
    push rax

 string_compare_more:
    mov     al, [rsi]                   ; Store string contents
    mov     bl, [rdi]
    test    al, al                      ; End of first string?
    jz      string_compare_terminated
    cmp     al, bl
    jne     string_compare_not_same
    inc     rsi
    inc     rdi
    jmp     string_compare_more

 string_compare_terminated:
    test    bl, bl                      ; End of second string?
    jz      string_compare_same

  string_compare_not_same:
    clc
    jmp  string_compare_done

 string_compare_same:
    stc

 string_compare_done:
    pop     rax
    pop     rbx
    pop     rdi
    pop     rsi
    ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; string_token -- See if string one is a token of string two
;
;  IN:    RSI = string one token
;         RDI = string two payload
; OUT:    Carry flag set if same
;         RDI = string after token

string_token:
    push rsi
    push rbx
    push rax

 string_token_more:
    mov  al, [rsi]                      ; String contents
    mov  bl, [rdi]

    test al, al                         ; End of first string?
    jz  string_token_same

    cmp  al, bl
    jne  string_token_not_same

    test bl, bl                         ; End of second string?
    jz string_token_not_same

    inc  rsi
    inc  rdi
    jmp  string_token_more

 string_token_same:
    stc
    jmp string_token_done

 string_token_not_same:
    clc

 string_token_done:
    pop rax
    pop rbx
    pop rsi
    ret

; -----------------------------------------------------------------------------
; string_skip -- Walk until non char encountered, point to first non match
;
;
;  IN:      RSI = string
;           BL  = char to skip
; OUT:      Carry flag set if same


string_skip:

 string_skip_more:

    mov  al, [rsi]                      ; String contents

    test al, al                         ; End of first string?
    jz  string_skip_done

    cmp  al, bl
    jne  string_skip_done

    inc  rsi
    jmp  string_skip_more

 string_skip_done:

    ret

; -----------------------------------------------------------------------------
; string_from_int -- Convert a binary integer into an string
;  IN:    RAX = binary integer
;    RDI = location to store string
; OUT:    RDI = points to end of string
;    All other registers preserved
; Min return value is 0 and max return value is 18446744073709551615 so the
; string needs to be able to store at least 21 characters (20 for the digits
; and 1 for the string terminator).
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/rax2uint.s

string_from_int:
    push rdx
    push rcx
    push rbx
    push rax
    push rsi

    mov rbx, 10                         ; base of the decimal system
    xor ecx, ecx                        ; number of digits generated
 string_from_int_next_divide:
    xor edx, edx                        ; RAX extended to (RDX,RAX)
    div rbx                             ; divide by the number-base
    push rdx                            ; save remainder on the stack
    inc rcx                             ; and count this remainder
    test rax, rax                       ; was the quotient zero?
    jnz string_from_int_next_divide     ; no, do another division

 string_from_int_next_digit:
    pop rax                             ; else pop recent remainder
    add al, '0'                         ; and convert to a numeral
    stosb                               ; store to memory-buffer
    loop string_from_int_next_digit     ; again for other remainders
    xor al, al
    stosb                               ; Store the null terminator at ...
                                        ; the end of the string

    pop rsi
    pop rax
    pop rbx
    pop rcx
    pop rdx
    ret

; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; string_to_int -- Convert a string into a binary integer
;  IN:    RSI = location of string
; OUT:    RAX = integer value
;    All other registers preserved
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/uint2rax.s

string_to_int:
    push rsi
    push rdx
    push rcx
    push rbx

    xor eax, eax                        ; initialize accumulator
    mov rbx, 10                         ; decimal-system's radix
 string_to_int_next_digit:
    mov cl, [rsi]                       ; fetch next character
    cmp cl, '0'                         ; char precedes '0'?
    jb string_to_int_invalid            ; yes, not a numeral
    cmp cl, '9'                         ; char follows '9'?
    ja string_to_int_invalid            ; yes, not a numeral
    mul rbx                             ; ten times prior sum
    and rcx, 0x0F                       ; convert char to int
    add rax, rcx                        ; add to prior total
    inc rsi                             ; advance source index
    jmp string_to_int_next_digit        ; and check another char

 string_to_int_invalid:
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    ret

; -----------------------------------------------------------------------------
