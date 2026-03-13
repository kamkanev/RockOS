;==========================
;       NANO COMMAND
;==========================

[bits 16]
[org 0x7c00]

%define SHELL_SEGMENT       0x800
%define DIR_TABLE_START_LBA 20
%define DIR_TABLE_SECTORS   10
%define CWD_ID              0x0500
%define NEXT_SECTOR_PTR     0x0502
%define USER_INPUT          0x0510
%define DIR_BUFFER          0x2000
%define TEXT_BUFFER         0x3000
%define FOUND_EMPTY         0x0520
%define EMPTY_SECTOR        0x0522
%define EMPTY_OFF           0x0524

%define ENTER_KEY           0x1c

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov ax, 0x0003
    int 0x10

    call get_arg_ptr
    cmp word [arg_ptr], 0
    je exit

    call find_or_create
    cmp al, 1
    jne exit

    mov ax, word [file_lba]
    mov bx, TEXT_BUFFER
    call read_lba

    ; print buffer and set edit_ptr
    mov si, TEXT_BUFFER
    xor bx, bx
    mov cx, 512
.print_loop:
    mov al, byte [si]
    cmp al, 0
    je .print_done
    mov ah, 0x0e
    int 0x10
    inc si
    inc bx
    loop .print_loop
.print_done:
    mov word [edit_ptr], bx

.edit_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x11            ; Ctrl+Q
    je exit
    cmp al, 0x13            ; Ctrl+S
    je .save_continue
    cmp al, 0x18            ; Ctrl+X
    je .save_exit

    cmp ah, ENTER_KEY
    je .enter

    cmp al, 0x20
    jb .edit_loop

    call append_char
    jmp .edit_loop

.enter:
    call append_newline
    jmp .edit_loop

.save_continue:
    call save_file
    jmp .edit_loop

.save_exit:
    call save_file
    jmp exit

exit:
    jmp SHELL_SEGMENT:0x0000

;==========================
; Arg + directory
;==========================

get_arg_ptr:
    mov bx, USER_INPUT
.find_space:
    cmp byte [bx], ' '
    je .found_space
    cmp byte [bx], 0
    je .no_arg
    inc bx
    jmp .find_space
.found_space:
    inc bx
    mov word [arg_ptr], bx
    ret
.no_arg:
    mov word [arg_ptr], 0
    ret

find_or_create:
    mov byte [FOUND_EMPTY], 0
    mov cx, 0
.scan_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .not_found

    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    mov bx, DIR_BUFFER
    push cx
    call read_lba
    pop cx

    mov si, DIR_BUFFER
    mov dx, 32
.scan_entry:
    mov al, byte [si + 11]
    cmp al, 1
    je .check_match
    cmp al, 0
    jne .next_entry

    cmp byte [FOUND_EMPTY], 0
    jne .next_entry
    mov word [EMPTY_OFF], si
    mov word [EMPTY_SECTOR], cx
    mov byte [FOUND_EMPTY], 1
    jmp .next_entry

.check_match:
    mov ax, word [CWD_ID]
    cmp word [si + 12], ax
    jne .next_entry

    push si
    push cx
    mov di, si
    mov si, word [arg_ptr]
    call names_equal
    cmp al, 1
    pop cx
    pop si
    jne .next_entry

    mov ax, word [si + 14]
    mov word [file_lba], ax
    mov al, 1
    ret

.next_entry:
    add si, 16
    dec dx
    jnz .scan_entry
    inc cx
    jmp .scan_sector

.not_found:
    cmp byte [FOUND_EMPTY], 1
    jne .fail

    mov cx, word [EMPTY_SECTOR]
    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    mov bx, DIR_BUFFER
    call read_lba

    mov si, word [EMPTY_OFF]
    mov bx, word [arg_ptr]
    mov di, si
    mov dx, 11
.copy_char:
    mov al, byte [bx]
    cmp al, 0
    je .done_copy
    mov byte [di], al
    inc bx
    inc di
    dec dx
    jnz .copy_char
.done_copy:
    mov byte [si + 11], 1
    mov ax, word [CWD_ID]
    mov word [si + 12], ax
    mov ax, word [NEXT_SECTOR_PTR]
    mov word [si + 14], ax
    mov word [file_lba], ax
    inc word [NEXT_SECTOR_PTR]

    mov ax, DIR_TABLE_START_LBA
    add ax, word [EMPTY_SECTOR]
    mov bx, DIR_BUFFER
    call write_lba

    mov al, 1
    ret

.fail:
    mov al, 0
    ret

names_equal:
    mov cx, 11
    repe cmpsb
    jne .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

;==========================
; Editor helpers
;==========================

append_char:
    mov bx, word [edit_ptr]
    cmp bx, 511
    jae .ret
    mov di, TEXT_BUFFER
    add di, bx
    mov byte [di], al
    inc bx
    mov byte [di + 1], 0
    mov word [edit_ptr], bx
    mov ah, 0x0e
    int 0x10
.ret:
    ret

append_newline:
    mov bx, word [edit_ptr]
    cmp bx, 509
    jae .ret
    mov di, TEXT_BUFFER
    add di, bx
    mov byte [di], 0x0d
    mov byte [di + 1], 0x0a
    mov byte [di + 2], 0
    add bx, 2
    mov word [edit_ptr], bx
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
.ret:
    ret

save_file:
    mov ax, word [file_lba]
    mov bx, TEXT_BUFFER
    call write_lba
    ret

;==========================
; Disk helpers
;==========================

read_lba:
    mov word [dap_buf], bx
    mov word [dap_seg], 0
    mov word [dap_lba], ax
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

write_lba:
    mov word [dap_buf], bx
    mov word [dap_seg], 0
    mov word [dap_lba], ax
    mov ah, 0x43
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

;==========================
; Data
;==========================

arg_ptr dw 0
file_lba dw 0
edit_ptr dw 0

dap:
    db 0x10
    db 0
    dw 1
    dw 0
    dw 0
    dq 0

dap_buf equ dap + 4

dap_seg equ dap + 6

dap_lba equ dap + 8

times 512 - ($ - $$) db 0
