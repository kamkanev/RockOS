;==========================
;       LS COMMAND
;==========================

[bits 16]
[org 0x7c00]

%define SHELL_SEGMENT 0x800
%define DIR_TABLE_START_LBA 20
%define DIR_TABLE_SECTORS   10
%define CWD_ID              0x0500
%define DIR_BUFFER          0x2000

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp

    mov si, new_line
    call print_string

    mov byte [found_any], 0
    mov cx, 0

.read_next_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .done_scan

    push cx
    mov di, DIR_BUFFER
    mov cx, 256
    xor ax, ax
    rep stosw
    pop cx

    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    push cx
    call read_lba
    pop cx
    jc .disk_error

    mov si, DIR_BUFFER
    mov dx, 32

.check_entry:
    cmp byte [si + 11], 0
    je .next_entry

    mov ax, word [CWD_ID]
    cmp word [si + 12], ax
    jne .next_entry

    mov byte [found_any], 1

    push si
    push dx
    push cx

    mov cx, 11
    mov bx, si
.print_char:
    mov al, byte [bx]
    cmp al, 0
    je .done_print_name
    cmp al, ' '
    je .done_print_name
    mov ah, 0x0e
    int 0x10
    inc bx
    loop .print_char
.done_print_name:

    cmp byte [si + 11], 2
    jne .print_newline
    mov si, dir_suffix
    call print_string
    jmp .done_entry

.print_newline:
    mov si, new_line
    call print_string

.done_entry:
    pop cx
    pop dx
    pop si

.next_entry:
    add si, 16
    dec dx
    jnz .check_entry

    inc cx
    jmp .read_next_sector

.done_scan:
    cmp byte [found_any], 0
    jne .exit
    mov si, empty_msg
    call print_string
    jmp .exit

.disk_error:
    mov si, disk_error_msg
    call print_string

.exit:
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

read_lba:
    mov word [dap_lba], ax
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

dap:
    db 0x10
    db 0
    dw 1
    dw DIR_BUFFER
    dw 0

dap_lba:
    dq 0

found_any db 0
new_line db 10, 13, 0
empty_msg db '(empty)', 10, 13, 0
disk_error_msg db 'LS disk error', 10, 13, 0
dir_suffix db ' <DIR>', 10, 13, 0

times 512 - ($ - $$) db 0
