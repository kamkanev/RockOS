;==========================
;       NANO COMMAND
;==========================

[bits 16]
[org 0x9000]

%define SHELL_SEGMENT       0x800
%define DIR_TABLE_START_LBA 20
%define DIR_TABLE_SECTORS   10
%define CWD_ID              0x0500
%define NEXT_SECTOR_PTR     0x0502
%define USER_INPUT          0x0510
%define DIR_BUFFER          0x2000
%define TEXT_BUFFER         0x3000

%define ENTER_KEY           0x1c
%define BACKSPACE_KEY       0x0e

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    cld

    mov ax, 0x0003
    int 0x10

    call get_arg_ptr
    cmp word [arg_ptr], 0
    je .usage

    call valid_name
    cmp al, 1
    jne .invalid

    call find_existing_file
    cmp al, 1
    je .have_file
    cmp al, 2
    je .directory

    call create_file
    cmp al, 1
    jne .no_space

.have_file:
    cmp byte [file_new], 1
    je .clear_buffer

    mov ax, word [file_lba]
    mov bx, TEXT_BUFFER
    call read_lba

    jmp .print_header
.clear_buffer:
    mov di, TEXT_BUFFER
    mov cx, 256
    xor ax, ax
    rep stosw
.print_header:
    call init_edit_ptr
    call draw_editor

.edit_loop:
    mov ah, 0x00
    int 0x16

    mov bl, al
    mov bh, ah

    cmp al, 0
    jne .check_ctrl
    cmp ah, 0x3c           ; F2
    je .save_continue
    cmp ah, 0x3d           ; F3
    je .save_exit
    cmp ah, 0x3e           ; F4
    je exit
    jmp .restore_key

.check_ctrl:

    cmp al, 0x11            ; Ctrl+Q (ASCII)
    je exit
    cmp al, 0x13            ; Ctrl+S (ASCII)
    je .save_continue
    cmp al, 0x18            ; Ctrl+X (ASCII)
    je .save_exit

    ; ctrl fallback via shift flags + scancode
    mov dl, bh
    mov ah, 0x02
    int 0x16
    test al, 0x04           ; Ctrl pressed?
    jz .no_ctrl_fallback
    cmp dl, 0x10            ; Q scancode
    je exit
    cmp dl, 0x1f            ; S scancode
    je .save_continue
    cmp dl, 0x2d            ; X scancode
    je .save_exit
.no_ctrl_fallback:

.restore_key:
    mov al, bl
    mov ah, bh

    cmp ah, BACKSPACE_KEY
    je .backspace
    cmp ah, ENTER_KEY
    je .enter

    cmp al, 0x20
    jb .edit_loop

    call append_char
    jmp .edit_loop

.enter:
    call append_newline
    jmp .edit_loop

.backspace:
    call delete_char
    jmp .edit_loop

.save_continue:
    call save_file
    call draw_editor
    mov ah, 0x03
    xor bx, bx
    int 0x10
    push dx
    mov dx, 0x0020
    mov ah, 0x02
    int 0x10
    mov si, saved_msg
    call print_string
    pop dx
    mov ah, 0x02
    int 0x10
    jmp .edit_loop

.save_exit:
    call save_file
    jmp exit

 .directory:
    mov si, directory_msg
    jmp .error
.invalid:
    mov si, invalid_msg
.error:
    call print_string
    call wait_key
    jmp exit

.usage:
    mov si, usage_msg
    call print_string
    call wait_key
    jmp exit

.no_space:
    mov si, no_space_msg
    call print_string
    call wait_key
    jmp exit

exit:
    mov ax, 0x0003
    int 0x10
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
.skip_spaces:
    cmp byte [bx], ' '
    jne .check_arg
    inc bx
    jmp .skip_spaces
.check_arg:
    cmp byte [bx], 0
    je .no_arg
    mov word [arg_ptr], bx
    ret
.no_arg:
    mov word [arg_ptr], 0
    ret

find_existing_file:
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
    cmp byte [si + 11], 0
    je .next_entry

    mov ax, word [CWD_ID]
    cmp word [si + 12], ax
    jne .next_entry

    push si
    push cx
    mov bx, word [arg_ptr]
    mov di, si
    call names_equal
    cmp al, 1
    pop cx
    pop si
    jne .next_entry

    cmp byte [si+11], 2
    jne .file
    mov al, 2
    ret
.file:
    mov ax, word [si + 14]
    mov word [file_lba], ax
    mov byte [file_new], 0
    mov al, 1
    ret

.next_entry:
    add si, 16
    dec dx
    jnz .scan_entry
    inc cx
    jmp .scan_sector

.not_found:
    mov al, 0
    ret

create_file:
    mov cx, 0
.scan_sector2:
    cmp cx, DIR_TABLE_SECTORS
    je .no_space

    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    mov bx, DIR_BUFFER
    push cx
    call read_lba
    pop cx

    mov si, DIR_BUFFER
    mov dx, 32
.scan_entry2:
    cmp byte [si + 11], 0
    jne .next_entry2

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
    mov byte [si + 11], 1
    mov ax, word [CWD_ID]
    mov word [si + 12], ax
    mov ax, word [NEXT_SECTOR_PTR]
    mov word [si + 14], ax
    mov word [file_lba], ax
    inc word [NEXT_SECTOR_PTR]

    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    mov bx, DIR_BUFFER
    call write_lba

    mov byte [file_new], 1
    mov al, 1
    ret

.next_entry2:
    add si, 16
    dec dx
    jnz .scan_entry2
    inc cx
    jmp .scan_sector2

.no_space:
    mov al, 0
    ret

%include "fs_names.inc"

;==========================
; Editor helpers
;==========================

; Row 0 is the title, rows 1-22 are text, rows 23-24 are shortcuts.
; Redraw from the buffer so wrapping, scrolling and deletion agree.
draw_editor:
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184f
    int 0x10
    xor bx, bx
    xor dx, dx
    mov ah, 0x02
    int 0x10
    mov si, title_msg
    call print_string
    call print_arg
    xor bx, bx
    mov dx, 0x1700
    mov ah, 0x02
    int 0x10
    mov si, help_msg
    call print_string
    mov dx, 0x1800
    mov ah, 0x02
    int 0x10
    mov si, help_keys
    call print_string
    mov dx, 0x0100
    mov ah, 0x02
    int 0x10
    call print_buffer
    ret

; Write without BIOS teletype scrolling the full screen. Only the text
; rectangle scrolls, so the cursor and file contents never enter the footer.
editor_putc:
    pusha
    mov bl, al
    mov ah, 0x03
    xor bh, bh
    int 0x10
    cmp bl, 13
    je .carriage
    cmp bl, 10
    je .newline
    mov al, bl
    mov bl, 0x07
    mov cx, 1
    mov ah, 0x09
    int 0x10
    inc dl
    cmp dl, 80
    jb .position
    xor dl, dl
.newline:
    inc dh
    cmp dh, 23
    jb .position
    mov ax, 0x0601
    mov bh, 0x07
    mov cx, 0x0100
    mov dx, 0x164f
    int 0x10
    mov dx, 0x1600
    jmp .position
.carriage:
    xor dl, dl
.position:
    xor bx, bx
    mov ah, 0x02
    int 0x10
    popa
    ret

print_buffer:
    mov si, TEXT_BUFFER
    mov cx, 512
.next_byte:
    mov al, byte [si]
    cmp al, 0
    je .done
    call editor_putc
    inc si
    loop .next_byte
.done:
    ret

init_edit_ptr:
    mov si, TEXT_BUFFER
    mov cx, 512
    xor bx, bx
.scan_end:
    mov al, byte [si]
    cmp al, 0
    je .found_end
    inc si
    inc bx
    loop .scan_end
.found_end:
    mov word [edit_ptr], bx
    ret

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
    call draw_editor
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
    call draw_editor
.ret:
    ret

delete_char:
    mov bx, word [edit_ptr]
    cmp bx, 0
    je .ret
    dec bx
    mov di, TEXT_BUFFER
    add di, bx
    mov al, byte [di]
    cmp al, 0x0d
    je .ret
    cmp al, 0x0a
    je .ret
    mov word [edit_ptr], bx
    mov byte [di], 0
    call draw_editor
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
    mov word [dap + 4], bx
    mov word [dap_lba], ax
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

write_lba:
    mov word [dap + 4], bx
    mov word [dap_lba], ax
    mov ax, 0x4300
    mov dl, 0x80
    mov si, dap
    int 0x13
    ret

;==========================
; Printing helpers
;==========================

print_string:
    cld
    xor bx, bx
    mov ah, 0x0e
.next_char:
    lodsb
    cmp al, 0
    je .return
    int 0x10
    jmp .next_char
.return:
    ret

print_arg:
    mov bx, word [arg_ptr]
.next_char:
    mov al, byte [bx]
    cmp al, 0
    je .done
    cmp al, ' '
    je .done
    push bx
    xor bx, bx
    mov ah, 0x0e
    int 0x10
    pop bx
    inc bx
    jmp .next_char
.done:
    ret

wait_key:
    mov ah, 0x00
    int 0x16
    ret

;==========================
; Data
;==========================

arg_ptr dw 0
file_lba dw 0
edit_ptr dw 0
file_new db 0

directory_msg db "Cannot edit a directory.",13,10,0
invalid_msg db "Invalid name (1-11 bytes).",13,10,0
title_msg db 'nano ',0
usage_msg db 'Usage: nano <file>',10,13,0
no_space_msg db 'No space in directory table',10,13,0
saved_msg db '[Saved]',0
new_line db 10,13,0

help_msg db 'Ctrl+S Save    Ctrl+X Save & Exit    Ctrl+Q Quit',0
help_keys db 'F2 Save        F3 Save & Exit        F4 Quit    Backspace: erase within line',0

; DAP for LBA disk I/O

dap:
    db 0x10
    db 0
    dw 1
    dw 0
    dw 0

dap_lba:
    dq 0

; Loaded above the resident shell; occupies LBAs 17-19.

times 1536 - ($ - $$) db 0
