; =============================================================================
; SimpOS -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2021 Peter Glen
; Written: Sun 24.Oct.2021
; =============================================================================

; Strings

align 8

prompt:             db '> ', 0
message_reboot:     db 'Rebooting ...', 10, 0
message_ver:        db 'SimpOS 64 bit Version 1.0', 13, 0
message_run:        db 'Running: ', 0
message_load:       db 'Enter file number: ', 0
message_loaded:     db 'Loaded. ', 13, 0
message_unknown:    db 'Unknown command', 13, 0

; (you will be prompted for the program number)

message_help:       db 'Available commands:', 13
                    db ' dir  - Show programs currently on disk', 13
                    db ' run - Load and execute program', 13
                    db ' load - Load a program to memory', 13
                    db ' exec - Run the program currently in memory', 13
                    db ' reboot - Reboot system', 13
                    db ' ver  - Show the system version', 13, 0

message_diskread    db  'Error on disk read', 13, 0


command_clear:      db 'clear', 0
command_reboot:     db 'reboot', 0
command_run:        db 'run', 0
command_exec:       db 'exec', 0
command_ls:         db 'ls', 0
command_dir:        db 'dir', 0
command_ver:        db 'ver', 0
command_load:       db 'load', 0
command_help:       db 'help', 0

monstart            db 'Monitor ', 0
mondone             db 'OK', 10, 0

banner:
                    db ' ---------------------------------------------------------', 13
                    db '   SimpOS Operating System Written by Peter Glen, 2020 ',    13
                    db ' ---------------------------------------------------------', 13, 13, 13, 0

memapmsg:           db 'Memory Map: ', 13,
                    db '    Start            Length        Flag     ACPI        Filler   ', 13, 0

cpumsg:             db '  cpu: ', 0
memmsg:             db '  mem: ', 0
networkmsg:         db '  net: ', 0
diskmsg:            db '  hdd: ', 0
mibmsg:             db ' MiB', 0
mhzmsg:             db ' MHz', 0
coresmsg:           db ' x ', 0
namsg:              db 'N/A', 0
closebracketmsg:    db ' ', 0
dirmsg:             db '#       Name            Size', 13, '-----------------------------', 13, 0
dirdump:            db "dump dir", 0
space:              db ' ', 0
retx:               db 10, 0
newline:            db 13, 0
tab:                db 9, 0
hprefix:            db '0x ', 0
xaddr:              db 'Addr: ' , 0

inmsg:              db ' Input: ', 0

; Variables

VideoBase:           dq 0
Screen_Pixels:       dd 0
Screen_Bytes:        dd 0
Screen_Row_2:        dd 0
FG_Color:            dd 0
BG_Color:            dd 0
VideoX:              dw 0
VideoY:              dw 0
Screen_Rows:         dw 0
Screen_Cols:         dw 0
Screen_Cursor_Row:   dw 0
Screen_Cursor_Col:   dw 0
VideoDepth:          db 0

%include 'font.inc'

; -----------------------------------------------------------------------------
; Constants

tchar:              db  0, 0, 0, 0, 0
hextable:           db '0123456789ABCDEF', 0
colon:              db ':', 0
os_debug_dump_mem_chars: db '0x: ', 0

temp_string1: times 50 db 0
temp_string2: times 50 db 0

; Reading here will extend beyond mem
temp_string:        db 0

; EOF
