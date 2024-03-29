; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2020 Return Infinity -- see LICENSE.TXT
;
; Debug Functions
; =============================================================================

    ; test register dump
    ;mov rax, 0x4444444444444444
    ;call os_debug_dump_ax
    ;mov rsi, newline
    ;call output
    ;
    ;mov rax, 0x4444444444444444
    ;call os_debug_dump_eax
    ;mov rsi, newline
    ;call output
    ;
    ;mov rax, 0x4444444444444444
    ;call os_debug_dump_rax
    ;mov rsi, newline
    ;call output
    ;
    ;mov rsi, newline
    ;call output

; -----------------------------------------------------------------------------
; os_debug_dump_(rax|eax|ax|al) -- Dump content of RAX, EAX, AX, or AL
;  IN:	RAX = content to dump
; OUT:	Nothing, all registers preserved

os_debug_dump_rax:

	rol rax, 8
	call os_debug_dump_al
	rol rax, 8
	call os_debug_dump_al
	rol rax, 8
	call os_debug_dump_al
	rol rax, 8
	call os_debug_dump_al
	rol rax, 32
os_debug_dump_eax:
	rol eax, 8
	call os_debug_dump_al
	rol eax, 8
	call os_debug_dump_al
	rol eax, 16
os_debug_dump_ax:
	rol ax, 8
	call os_debug_dump_al
	rol ax, 8
os_debug_dump_al:
	push rbx
	push rax
	mov rbx, hextable
	push rax			; Save RAX since we work in 2 parts
	shr al, 4			; Shift high 4 bits into low 4 bits
	xlatb
	mov [tchar+0], al
	pop rax
	and al, 0x0f			; Clear the high 4 bits
	xlatb
	mov [tchar+1], al
	push rsi
	push rcx
	mov rsi, tchar
	mov rcx, 2
	call b_output
	pop rcx
	pop rsi
	pop rax
	pop rbx
	ret
; -----------------------------------------------------------------------------
; char in al

out_char:

    push    rsi
    push    rcx

    mov rsi, tchar
    mov [rsi], al
    mov byte [rsi + 1], 0
	mov rcx, 2

	call b_output

    pop     rcx
    pop     rsi

    ret

; -----------------------------------------------------------------------------
; os_debug_dump_mem -- Dump content of memory in hex format
;  IN:	RSI = starting address of memory to dump
;	RCX = number of bytes
; OUT:	Nothing, all registers preserved
os_debug_dump_mem:
	push rsi
	push rcx			; Counter
	push rdx			; Total number of bytes to display
	push rax

	test rcx, rcx			; Bail out if no bytes were requested
	jz os_debug_dump_mem_done

	push rsi			; Output '0x'
	push rcx
	mov rsi, os_debug_dump_mem_chars
	mov rcx, 2
	call b_output
	pop rcx
	pop rsi

	mov rax, rsi			; Output the memory address
	call os_debug_dump_rax
	call os_debug_dump_mem_newline

nextline:
	mov dx, 0
nextchar:
	cmp rcx, 0
	je os_debug_dump_mem_done_newline
	push rsi			; Output ' '
	push rcx
	mov rsi, os_debug_dump_mem_chars+4
	mov rcx, 1
	call b_output
	pop rcx
	pop rsi
	lodsb
	call    os_debug_dump_al

    cmp     dx, 8
    jne     nospace

    push rsi			; Output ' '
	push rcx
	mov     rsi, debspace
	mov     rcx, 1
    call    b_output
	pop rcx
	pop rsi

  nospace:

	dec rcx
	inc rdx
	cmp dx, 16			; End of line yet?
	jne nextchar

    ; print ascii after
    push    rcx
    push    rsi

    mov     esi, debspace
    call    b_output

    pop     rsi                 ; Refresh esi
    push    rsi

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
    call    out_char
    dec     ecx
    cmp     ecx, 0
    jg      more_16              ; If 16 chars end of string

    pop     rsi
    pop     rcx


	call os_debug_dump_mem_newline
	cmp rcx, 0
	je os_debug_dump_mem_done
	jmp nextline

 os_debug_dump_mem_done_newline:
	call os_debug_dump_mem_newline

 os_debug_dump_mem_done:
	pop rax
	pop rcx
	pop rdx
	pop rsi
	ret

 os_debug_dump_mem_newline:
	push rsi			; Output newline
	push rcx
	mov rsi, newline
	mov rcx, 1
	call b_output
	pop rcx
	pop rsi
	ret

os_debug_dump_mem_chars: db '0x: '
debspace    db " ", 0

; =============================================================================
; EOF
