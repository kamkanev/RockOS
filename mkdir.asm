;==========================
;       MKDIR COMMAND
;==========================

[bits 16]
[org 0x7c00]

%define SHELL_SEGMENT 0x800
%define DIR_TABLE_START_LBA 20
%define DIR_TABLE_SECTORS   10
%define CWD_ID              0x0500
%define NEXT_SECTOR_PTR     0x0502
%define USER_INPUT          0x0510
%define DIR_BUFFER          0x2000

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp

    mov bx, USER_INPUT
.find_space:
    cmp byte [bx], ' '
    je .found_space
    cmp byte [bx], 0
    je .exit
    inc bx
    jmp .find_space

.found_space:
    inc bx
.skip_spaces:
    cmp byte [bx], ' '
    jne .check_arg
    inc bx
    jmp .skip_spaces

.check_arg:
    cmp byte [bx], 0
    je .exit
    mov word [arg_ptr], bx

    mov cx, 0
.read_next_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .exit

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
    jc .exit

    mov si, DIR_BUFFER
    mov dx, 32
.check_entry:
    cmp byte [si + 11], 0
    je .found_empty
    add si, 16
    dec dx
    jnz .check_entry

    inc cx
    jmp .read_next_sector

.found_empty:
    mov bx, word [arg_ptr]
    mov di, si
    mov dx, 11
.copy_char:
    mov al, byte [bx]
    cmp al, 0
    je .done_copy
    cmp al, ' '
    je .done_copy
    mov byte [di], al
    inc bx
    inc di
    dec dx
    jnz .copy_char

.done_copy:
    mov byte [si + 11], 2
    mov ax, word [CWD_ID]
    mov word [si + 12], ax
    mov ax, word [NEXT_SECTOR_PTR]
    mov word [si + 14], ax
    inc word [NEXT_SECTOR_PTR]

    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    call write_lba

.exit:
    mov si, new_line
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

read_lba:
    mov word [dap_lba], ax
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

write_lba:
    mov word [dap_lba], ax
    mov ah, 0x43
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

arg_ptr dw 0
new_line db 10, 13, 0

times 512 - ($ - $$) db 0
