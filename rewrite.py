ls_content = """\
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
    ; Initialize segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp
    mov si, new_line
    call print_string

    mov cx, 0  ; loop counter (0 to 9)
    
.read_next_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .exit
    
    ; Clear DIR_BUFFER so stale data isn't processed
    push cx
    mov di, DIR_BUFFER
    mov cx, 256
    mov ax, 0
    rep stosw
    pop cx

    ; Read sector
    mov ax, DIR_TABLE_START_LBA
    add ax, cx      ; AX = LBA to read
    
    push cx
    call read_lba
    pop cx

    mov si, DIR_BUFFER
    mov dx, 32       ; 32 entries per sector
.check_entry:
    cmp byte [si + 11], 0
    je .next_entry
    
    ; Check Parent ID
    mov ax, word [CWD_ID]
    cmp word [si + 12], ax
    jne .next_entry

    ; We found an entry for this dir!
    push si
    push dx
    push cx

    ; Print name (up to 11 chars, null or space terminated)
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

    ; Print dir indicator if it's a directory (Flags == 2)
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
    .return: ret

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

new_line db 10, 13, 0
dir_suffix db ' <DIR>', 10, 13, 0

times 512 - ($ - $$) db 0
"""

mkdir_content = """\
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
    ; Initialize segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp
    ; Find the argument by searching for space
    mov bx, USER_INPUT
.find_space:
    cmp byte [bx], ' '
    je .found_space
    cmp byte [bx], 0
    je .exit   ; no argument or space
    inc bx
    jmp .find_space
.found_space:
    inc bx     ; pass the space
    ; skip any extra spaces
.skip_spaces:
    cmp byte [bx], ' '
    jne .check_arg
    inc bx
    jmp .skip_spaces

.check_arg:
    cmp byte [bx], 0
    je .exit   ; no argument after spaces

    ; Now we have the directory name in bx.
    mov cx, 0                           ; cx = loop counter (0 to 9)
    
.read_next_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .exit
    
    ; Clear DIR_BUFFER
    push cx
    mov di, DIR_BUFFER
    mov cx, 256
    mov ax, 0
    rep stosw
    pop cx

    ; Read LBA
    mov ax, DIR_TABLE_START_LBA
    add ax, cx      ; AX = LBA to read
    push cx
    call read_lba
    pop cx

    ; Scan 32 entries (512 / 16)
    mov si, DIR_BUFFER
    mov dx, 32       ; counter
.check_entry:
    cmp byte [si + 11], 0  ; Flags is at offset 11
    je .found_empty
    add si, 16
    dec dx
    jnz .check_entry

    inc cx
    jmp .read_next_sector

.found_empty:
    ; Restore bx to point to argument
    mov bx, USER_INPUT
.find_space2:
    cmp byte [bx], ' '
    je .found_space2
    inc bx
    jmp .find_space2
.found_space2:
    inc bx
.skip_spaces2:
    cmp byte [bx], ' '
    jne .arg_ready
    inc bx
    jmp .skip_spaces2
.arg_ready:
    ; Copy name from BX to SI (max 11 chars)
    push cx             ; save cx (loop counter)
    mov di, si
    mov cx, 11          ; max 11 chars
.copy_char:
    mov al, byte [bx]
    cmp al, 0
    je .done_copy_early
    cmp al, ' '
    je .done_copy_early
    mov byte [di], al
    inc bx
    inc di
    loop .copy_char
    jmp .done_copy
.done_copy_early:
    mov byte [di], 0    ; ensure null terminated
.done_copy:
    pop cx

    ; Set Flags to 2 (Directory)
    mov byte [si + 11], 2
    
    ; Set Parent ID to CWD_ID
    mov ax, word [CWD_ID]
    mov word [si + 12], ax

    ; Set Data Sector (acts as unique ID for dir)
    mov ax, word [NEXT_SECTOR_PTR]
    mov word [si + 14], ax
    inc word [NEXT_SECTOR_PTR]

    ; Write sector back
    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    call write_lba

.exit:
    mov si, new_line
    call print_string
    jmp SHELL_SEGMENT:0x0000

; procedure to print a string
print_string:
    cld
    mov ah, 0x0e
    .next_char:
        lodsb
        cmp al, 0
        je .return
        int 0x10
        jmp .next_char
    .return: ret

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

new_line db 10, 13, 0

times 512 - ($ - $$) db 0
"""

touch_content = """\
;==========================
;       TOUCH COMMAND
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
    ; Initialize segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp
    ; Find the argument by searching for space
    mov bx, USER_INPUT
.find_space:
    cmp byte [bx], ' '
    je .found_space
    cmp byte [bx], 0
    je .exit   ; no argument or space
    inc bx
    jmp .find_space
.found_space:
    inc bx     ; pass the space
    ; skip any extra spaces
.skip_spaces:
    cmp byte [bx], ' '
    jne .check_arg
    inc bx
    jmp .skip_spaces

.check_arg:
    cmp byte [bx], 0
    je .exit   ; no argument after spaces

    ; Now we have the file name in bx.
    mov cx, 0                           ; cx = loop counter (0 to 9)
    
.read_next_sector:
    cmp cx, DIR_TABLE_SECTORS
    je .exit
    
    ; Clear DIR_BUFFER
    push cx
    mov di, DIR_BUFFER
    mov cx, 256
    mov ax, 0
    rep stosw
    pop cx

    ; Read LBA
    mov ax, DIR_TABLE_START_LBA
    add ax, cx      ; AX = LBA to read
    push cx
    call read_lba
    pop cx

    ; Scan 32 entries (512 / 16)
    mov si, DIR_BUFFER
    mov dx, 32       ; counter
.check_entry:
    cmp byte [si + 11], 0  ; Flags is at offset 11
    je .found_empty
    add si, 16
    dec dx
    jnz .check_entry

    inc cx
    jmp .read_next_sector

.found_empty:
    ; Restore bx to point to argument
    mov bx, USER_INPUT
.find_space2:
    cmp byte [bx], ' '
    je .found_space2
    inc bx
    jmp .find_space2
.found_space2:
    inc bx
.skip_spaces2:
    cmp byte [bx], ' '
    jne .arg_ready
    inc bx
    jmp .skip_spaces2
.arg_ready:
    ; Copy name from BX to SI (max 11 chars)
    push cx             ; save cx (loop counter)
    mov di, si
    mov cx, 11          ; max 11 chars
.copy_char:
    mov al, byte [bx]
    cmp al, 0
    je .done_copy_early
    cmp al, ' '
    je .done_copy_early
    mov byte [di], al
    inc bx
    inc di
    loop .copy_char
    jmp .done_copy
.done_copy_early:
    mov byte [di], 0    ; ensure null terminated
.done_copy:
    pop cx

    ; Set Flags to 1 (File)
    mov byte [si + 11], 1
    
    ; Set Parent ID to CWD_ID
    mov ax, word [CWD_ID]
    mov word [si + 12], ax

    ; Set Data Sector
    mov ax, word [NEXT_SECTOR_PTR]
    mov word [si + 14], ax
    inc word [NEXT_SECTOR_PTR]

    ; Write sector back
    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    call write_lba

.exit:
    mov si, new_line
    call print_string
    jmp SHELL_SEGMENT:0x0000

; procedure to print a string
print_string:
    cld
    mov ah, 0x0e
    .next_char:
        lodsb
        cmp al, 0
        je .return
        int 0x10
        jmp .next_char
    .return: ret

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

new_line db 10, 13, 0

times 512 - ($ - $$) db 0
"""

cd_content = """\
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
    ; Initialize segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7c00
    mov sp, bp
    ; Find the argument by searching for space
    mov bx, USER_INPUT
.find_space:
    cmp byte [bx], ' '
    je .found_space
    cmp byte [bx], 0
    je .exit   ; no argument or space
    inc bx
    jmp .find_space
.found_space:
    inc bx     ; pass the space
    ; skip any extra spaces
.skip_spaces:
    cmp byte [bx], ' '
    jne .check_arg
    inc bx
    jmp .skip_spaces

.check_arg:
    cmp byte [bx], 0
    je .exit   ; no argument after spaces

    ; Check if ".."
    cmp byte [bx], '.'
    jne .scan_for_dir
    cmp byte [bx+1], '.'
    jne .scan_for_dir
    cmp byte [bx+2], 0
    jne .scan_for_dir

    ; Handle "cd .."
    mov ax, word [CWD_ID]
    cmp ax, 0
    je .exit ; already at root

    ; Find parent ID of current ID
    mov cx, 0                           ; loop counter
.read_next_sector_parent:
    cmp cx, DIR_TABLE_SECTORS
    je .exit
    
    ; Read LBA
    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    push cx
    call read_lba
    pop cx

    mov si, DIR_BUFFER
    mov dx, 32
.check_entry_parent:
    cmp byte [si + 11], 2 ; must be dir
    jne .next_entry_parent
    
    mov ax, word [CWD_ID]
    cmp word [si + 14], ax ; Data Sector == CWD_ID?
    jne .next_entry_parent

    ; Found current dir! Its parent is the new CWD
    mov ax, word [si + 12]
    mov word [CWD_ID], ax
    jmp .exit

.next_entry_parent:
    add si, 16
    dec dx
    jnz .check_entry_parent
    inc cx
    jmp .read_next_sector_parent


.scan_for_dir:
    ; Scan for directory name matching argument and Parent == CWD_ID
    mov cx, 0                           ; loop counter
.read_next_sector_child:
    cmp cx, DIR_TABLE_SECTORS
    je .not_found
    
    ; Read LBA
    mov ax, DIR_TABLE_START_LBA
    add ax, cx
    push cx
    push bx
    call read_lba
    pop bx
    pop cx

    mov si, DIR_BUFFER
    mov dx, 32
.check_entry_child:
    cmp byte [si + 11], 2 ; must be dir
    jne .next_entry_child
    
    mov ax, word [CWD_ID]
    cmp word [si + 12], ax ; Parent == CWD_ID?
    jne .next_entry_child

    ; Compare string names
    push si
    push bx
    push cx
    mov cx, 11
.cmp_char:
    mov al, byte [bx]
    
    ; check string termination conditions for argument
    cmp al, 0
    je .check_term
    cmp al, ' '
    je .check_term

    ; normal character match
    cmp byte [si], al
    jne .cmp_fail
    inc bx
    inc si
    loop .cmp_char
    jmp .cmp_match

.check_term:
    ; argument ended. Does the directory name also end here?
    cmp byte [si], 0
    jne .cmp_fail
    cmp byte [si], ' '
    jne .cmp_fail
    ; if both terminated at the same point, it's a match!

.cmp_match:
    pop cx
    pop bx
    pop si
    ; Match! Set CWD_ID
    mov ax, word [si + 14]
    mov word [CWD_ID], ax
    jmp .exit
.cmp_fail:
    pop cx
    pop bx
    pop si

.next_entry_child:
    add si, 16
    dec dx
    jnz .check_entry_child
    inc cx
    jmp .read_next_sector_child

.not_found:
    mov si, new_line
    call print_string
    mov si, not_found_msg
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
    .return: ret

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

new_line db 10, 13, 0
not_found_msg db 'Directory not found.', 10, 13, 0

times 512 - ($ - $$) db 0
"""

with open('ls.asm', 'w') as f:
    f.write(ls_content)
with open('mkdir.asm', 'w') as f:
    f.write(mkdir_content)
with open('touch.asm', 'w') as f:
    f.write(touch_content)
with open('cd.asm', 'w') as f:
    f.write(cd_content)
