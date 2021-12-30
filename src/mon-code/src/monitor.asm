BITS 64
ORG 0x001E0000

%include 'libsimpos.inc'

start:

    mov     rsi, monstart
    call    string_length
    call    [sys_serial]

    ; Grab video values from Pure64
    mov rsi, 0x5080
    xor eax, eax
    lodsd                   ; VIDEO_BASE
    mov [VideoBase], rax
    xor eax, eax
    xor ecx, ecx
    lodsw                   ; VIDEO_X
    mov [VideoX], ax        ; ex: 1024
    xor edx, edx
    mov cl, [font_width]
    div cx
    mov [Screen_Cols], ax
    lodsw                   ; VIDEO_Y
    mov [VideoY], ax        ; ex: 768
    xor edx, edx
    mov cl, [font_height]
    div cx
    mov [Screen_Rows], ax
    lodsb                   ; VIDEO_DEPTH
    mov [VideoDepth], al

    ; Calculate screen parameters
    xor eax, eax
    xor ecx, ecx
    mov ax, [VideoX]
    mov cx, [VideoY]
    mul ecx
    mov [Screen_Pixels], eax
    xor ecx, ecx
    mov cl, [VideoDepth]
    shr cl, 3
    mul ecx
    mov [Screen_Bytes], eax
    xor eax, eax
    xor ecx, ecx
    mov ax, [VideoX]
    mov cl, [font_height]
    mul cx
    mov cl, [VideoDepth]
    shr cl, 3
    mul ecx
    mov dword [Screen_Row_2], eax

    ; Emit start message
    ;mov     rsi, monstart
    ;call    string_length
    ;call    [sys_serial]

    ; Set foreground/background color
    ;mov eax, 0x00FFFFFF
    mov eax, 0x00FFFFFF
    mov [FG_Color], eax
    mov eax, 0x00002040
    mov [BG_Color], eax

    call screen_clear

    ; Overwrite the kernel output function so output goes to the screen instead of the serial port
    mov rax, output_chars
    mov rdi, 0x100018
    stosq

    ; Move cursor to bottom of screen
    ;mov ax, [Screen_Rows]
    ;dec ax
    ;; Just some lines down
    mov word [Screen_Cursor_Row], 1
    mov word [Screen_Cursor_Col], 0

    mov rsi, banner
    mov rdx, 1
    call output_mon

    ; Dump memory map
    ;mov rsi, 0x1e0000
    ;mov rsi, 0x12345678aaaabbbb
    ;mov rcx,128
    ;call mon_debug_dump_mem

    call show_memap

    ; Output system details
    mov rsi, cpumsg
    mov rdx, 1
    call output_mon

    xor eax, eax
    mov rsi, 0x5012
    lodsw
    mov rdi, temp_string
    mov rsi, rdi
    call string_from_int
    mov rdx, 1
    call output_mon

    mov rsi, coresmsg
    mov rdx, 1
    call output_mon
    mov rsi, 0x5010
    lodsw
    mov rdi, temp_string
    mov rsi, rdi
    call string_from_int
    mov rdx, 1
    call output_mon

    mov rsi, mhzmsg
    call output_mon
    mov rsi, memmsg
    call output_mon
    mov rsi, 0x5020
    lodsd
    mov rdi, temp_string
    mov rsi, rdi
    call string_from_int
    call output_mon
    mov rsi, mibmsg
    call output_mon
    mov rsi, closebracketmsg
    call output_mon
    mov rsi, newline
    mov  edx, 1
    call output_mon
    call output_mon

    mov     rsi, mondone
    call    string_length
    call    [sys_serial]

poll:
    mov rsi, prompt
    call output_mon
    mov rdi, temp_string
    mov byte [rdi], 0
    mov rcx, 100
    call input
    ; TODO clear leading/trailing spaces to sanitize input

    ;mov rsi, temp_string                ; show command on serial
    ;call string_length
    ;call  [sys_serial]
    ;mov rsi, retx
    ;mov rcx, 3
    ;call  [sys_serial]

    mov rsi, command_reboot
    call string_compare
    jc reboot_cmd

    mov rsi, command_exec
    call string_compare
    jc exec

    mov rsi, command_dir
    call string_compare
    jc dir

    mov rsi, command_clear
    call string_compare
    jc clear_scr

    mov rsi, command_ls
    call string_compare
    jc dir

    mov rsi, command_ver
    call string_compare
    jc print_ver

    mov rsi, command_load
    call string_compare
    jc load

    mov rsi, command_help
    call string_compare
    jc help

    mov rsi, command_run
    mov rdi, temp_string
    call string_token
    jc  run

    cmp rcx, 0            ; If no characters were entered show prompt again
    je poll
    mov rsi, message_unknown
    call output_mon
    jmp poll

clear_scr:
    call screen_clear
    mov word [Screen_Cursor_Row], 0
    mov word [Screen_Cursor_Col], 0
    jmp poll

reboot_cmd:
    mov rsi, message_reboot
    call output_mon
    mov     eax, reset
    call    sys_system
    jmp poll

exec:
    call 0x200000
    jmp poll

dir:
    mov rsi, dirmsg
    mov rdx, 1
    call output_mon
    mov rdi, temp_string
    mov rsi, rdi
    mov rax, 1
    mov rcx, 1
    mov rdx, 0
    call [sys_disk_read]        ; Load the 4K BMFS file table

    ;push    rsi
    ;push    rcx
    ;mov rsi, dirdump
    ;call output_mon
    ;mov     rsi, temp_string
    ;mov     rcx, 1280
    ;call    mon_debug_dump_mem
    ;pop     rcx
    ;pop     rsi

    mov rax, 1
 dir_next:
    cmp byte [rsi], 0        ; 0 means we're at the end of the list
    je dir_end

    push rsi
    mov rdi, temp_string1
    mov rsi, rdi
    call string_from_int
    mov rdx, 1
    call output_mon
    mov rsi, tab
    call output_mon
    add al, 1
    pop rsi

    call output_mon            ; Output_mon file name
    add rsi, 48
    push rax
    mov rax, [rsi]
    push rsi
    mov rsi, tab
    call output_mon
    mov rdi, temp_string1
    mov rsi, rdi
    call string_from_int
    call output_mon
    mov rsi, newline
    call output_mon
    pop rsi
    pop rax
    add rsi, 16            ; Next entry
    jmp dir_next
 dir_end:
    jmp poll

print_ver:
    mov rsi, message_ver
    call output_mon
    jmp poll

; -----------------------------------------------------------------------------
run:

    push rdi
    mov     rsi, rdi
    mov     bl, ' '
    call    string_skip
    pop rdi

    mov rsi, message_run
    mov edx, 1
    call output_mon

    mov     rsi, rdi
    call    string_length
    mov edx, 1
    call output_mon

    mov rsi, retx
    mov edx, 1
    call output_mon


    ;call    string_scan
    ;mov     rax, rcx
    ;call    mon_debug_dump_rax

    jmp poll

load:
    mov rsi, message_load
    mov edx, 1
    call output_mon
    mov rdi, temp_string
    mov rsi, rdi
    mov rcx, 2
    call input
    call string_to_int
    sub rax, 1            ; Files are indexed from 0
    push rax            ; Save the file #
    ; check value
    ; load file table
    mov rdi, temp_string
    mov rax, 1
    mov rcx, 1
    mov rdx, 0
    call [sys_disk_read]

    ; offset to file number and starting sector
    pop rcx                ; Restore the file #
    shl rcx, 6
    add rcx, 32            ; Offset to starting block # in BMFS file record
    add rdi, rcx
    mov rax, [rdi]
    shl rax, 9            ; Shift left by 9 to convert 2M block to 4K sector
    ; size
    ; TODO
    ; load to memory, use RAX for starting sector
    mov rdi, 0x200000
    mov rcx, 1            ; Loading 4K for now
    mov rdx, 0
    call [sys_disk_read]

    mov rsi, message_loaded
    mov edx, 1
    call output_mon

    jmp poll

help:
    mov rsi, message_help
    call output_mon
    jmp poll

%include 'monstr.asm'
%include 'monio.asm'
%include 'mondebug.asm'
%include 'mondata.asm'

endd:

;%assign num endd-start
;%warning "Code size" num org

; =============================================================================
; EOF

