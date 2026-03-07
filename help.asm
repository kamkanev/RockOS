;=========================
;          HELP
;=========================

[bits 16]
[org 0x7c00]

%define SHELL_SEGMENT 0x800

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp

    mov si, help_text
    call print_string

    jmp SHELL_SEGMENT:0x0000

print_string:
    cld
    mov ah, 0x0e
.next_char:
    lodsb
    cmp al, 0
    je .return
    int 0x10
    jmp .next_char
.return:
    ret

help_text db 10,13
          db 'Commands:',10,13
          db 'help  - show this page',10,13
          db 'info  - cpu info',10,13
          db 'clear - clear screen',10,13
          db 'theme - set colors',10,13
          db 'clock - show time',10,13
          db 'ls    - list entries',10,13
          db 'cd x  - change dir',10,13
          db 'mkdir x - new dir',10,13
          db 'touch x - new file',10,13
          db 'reboot - restart os',10,13,10,13
          db 'Games:',10,13
          db 'snake: WASD, Q exit, R restart',10,13
          db 'mines: arrows, Enter/Space, Q exit',10,13
          db 'pong: arrows, R exit',10,13
          db 'tetris: arrows, Q exit',10,13,0

times 512 - ($ - $$) db 0
