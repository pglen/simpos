; -----------------------------------------------------------------------------
; debug_dump_(rax|eax|ax|al) -- Dump content of RAX, EAX, AX, or AL
;  IN:	RAX = content to dump
; OUT:	Nothing, all registers preserved

align 8

debug_dump_rax:

	rol rax, 8
	call debug_dump_al
	rol rax, 8
	call debug_dump_al
	rol rax, 8
	call debug_dump_al
	rol rax, 8
	call debug_dump_al
	rol rax, 32
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
	call serial_out
	pop rcx
	pop rsi
	pop rax
	pop rbx
	ret

; -----------------------------------------------------------------------------
; debug_dump_mem -- Dump content of memory in hex format
;  IN:	RSI = starting address of memory to dump
;	RCX = number of bytes
; OUT:	Nothing, all registers preserved
debug_dump_mem:

	push rsi
	push rcx			; Counter
	push rdx			; Total number of bytes to display
	push rax

	test rcx, rcx			; Bail out if no bytes were requested
	jz debug_dump_mem_done

	push rcx
	push rsi

	mov rsi, debug_dump_mem_chars
	call serial_out

    pop rsi
	mov rax, rsi			; Output the memory address
	push rsi
    call debug_dump_eax

	mov rsi, debspace
	call serial_out

	mov rsi, debug_dump_mem_len
	call serial_out

    mov rax, rcx			; Output the memory len
	call debug_dump_ax

	pop rsi
    pop rcx

	call debug_dump_mem_newline

 nextline:
	mov dx, 0
 nextchar:
	cmp rcx, 0
	je debug_dump_mem_done_newline
	push rsi			; Output ' '
	push rcx
	mov rsi, debspace
	call serial_out
	pop rcx
	pop rsi
	lodsb
	call debug_dump_al

    cmp     dx, 8
    jne     nospace

    push rsi			; Output ' '
	mov     rsi, debspace
    call    serial_out
	pop rsi

  nospace:

	dec rcx
	inc rdx
	cmp dx, 16			; End of line yet?
	jne nextchar
	call debug_dump_mem_newline
	cmp rcx, 0
	je debug_dump_mem_done
	jmp nextline

 debug_dump_mem_done_newline:
	call debug_dump_mem_newline

 debug_dump_mem_done:
	pop rax
	pop rcx
	pop rdx
	pop rsi
	ret

 debug_dump_mem_newline:
	push rsi			; Output newline
	mov rsi, newline
	call serial_out
	pop rsi
	ret

; -----------------------------------------------------------------------------
; serial_out  -- Content description
; Output message via serial port
;
;  IN:  RSI = starting address of string
;
; OUT:    Nothing
;
; Date/Time: Fri 29.Oct.2021 12:01:44
; -----------------------------------------------------------------------------
; Use:
;       mov rsi, message    	; Location of message
;       mov cx, 11

serial_out:

    cld    			      ; Clear the direction flag.. we want to increment through the string

    push    rdx
    push    rax

    mov     dx, 0x03F8    	 ; Address of first serial port

 serial_nextchar:
    add dx, 5    		; Offset to Line Status Register
    in al, dx
    sub dx, 5    		; Back to to base
    lodsb    			; Get char from string and store in AL
    cmp al, 0
    je  serial_done
    out dx, al    		; Send the char to the serial port
    jmp serial_nextchar

 serial_done:
    pop     rax
    pop     rdx
    ret

; ------------------------------------------------------
console_out:

    mov eax, [VBEModeInfoBlock.PhysBasePtr]    	; Base address of video memory (if graphics mode is set)
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
hextable  		        db '0123456789ABCDEF'
tchar                   db          0, 0, 0
newline                 db  10, 0

