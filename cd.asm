;==========================
;       CD COMMAND
;==========================

[bits 16]
[org 0x7c00]

%define SHELL_SEGMENT 0x800
%define DIR_TABLE_START_LBA 20
%define DIR_TABLE_SECTORS   10
%define CWD_ID              0x0500
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

    cmp byte [bx], '.'
    jne .scan_child
    cmp byte [bx + 1], '.'
    jne .scan_child
    cmp byte [bx + 2], 0
    jne .scan_child

    mov ax, word [CWD_ID]
    cmp ax, 0
    je .exit

    mov cx, 0
.scan_parent_sector:
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
.scan_parent_entry:
    cmp byte [si + 11], 2
    jne .next_parent_entry
    mov ax, word [CWD_ID]
    cmp word [si + 14], ax
    jne .next_parent_entry
    mov ax, word [si + 12]
    mov word [CWD_ID], ax
    jmp .exit

.next_parent_entry:
    add si, 16
    dec dx
    jnz .scan_parent_entry
    inc cx
    jmp .scan_parent_sector

.scan_child:
    mov cx, 0
.scan_child_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .not_found

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
.scan_child_entry:
    cmp byte [si + 11], 2
    jne .next_child_entry

    mov ax, word [CWD_ID]
    cmp word [si + 12], ax
    jne .next_child_entry

    push si
    push cx
    mov bx, word [arg_ptr]
    mov di, si
    call names_equal
    cmp al, 1
    pop cx
    pop si
    jne .next_child_entry

    mov ax, word [si + 14]
    mov word [CWD_ID], ax
    jmp .exit

.next_child_entry:
    add si, 16
    dec dx
    jnz .scan_child_entry
    inc cx
    jmp .scan_child_sector

.not_found:
    mov si, not_found_msg
    call print_string

.exit:
    jmp SHELL_SEGMENT:0x0000

names_equal:
    mov cx, 11
.cmp_loop:
    mov al, byte [bx]
    cmp al, 0
    je .arg_end
    cmp al, ' '
    je .arg_end
    cmp byte [di], al
    jne .no
    inc bx
    inc di
    loop .cmp_loop
    mov al, 1
    ret
.arg_end:
    mov al, byte [di]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
.no:
    mov al, 0
    ret
.yes:
    mov al, 1
    ret

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

arg_ptr dw 0
not_found_msg db 'Directory not found.', 10, 13, 0

times 512 - ($ - $$) db 0
