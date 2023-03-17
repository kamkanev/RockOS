;=========================
;          SHELL
;=========================

[bits 16]
[org 0x8000]                    ;tell NASM the code is running shell at address 0x0000_8000

;init segment register
mov ax, 0
mov ds, ax
mov es, ax

mov si, 0x7E00
call print_string

;main OS loop
;shell_loop:

;    jmp shell_loop

execute:

    mov ax, 0x7c0                   ;init the segment
    mov es, ax                      ;init extra segment register
    mov bx, 0                       ;init local offset
    mov cl, 4                       ;select sector (4) from USB/HDD
    call read_sector                ;read sector
    jmp 0x7c0:0x0000                ;jump to the shell

;procedure to print a string
print_string:
    cld                             ;clear directional flag
    mov ah, 0x0e                    ;enable teletype output for int 0x10 BIOS call
    
    .next_char:
        lodsb                       ;read next byte from (e)si
        cmp al, 0                   ;match the '/000' termnating char of a string
        je .return
        int 0x10                    ;assuming ah = 0x0e int 0x10 will print a single char
        jmp .next_char
        
    .return: ret

;procedure to read a single sector from USB/HDD
read_sector:
    mov ah, 0x02                    ;BIOS code for read from storage device
    mov al, 1                       ;how many sectors to read
    mov ch, 0                       ;specify celinder
    mov dh, 0                       ;specify head
    mov dl, 0x80                    ;specify HDD code
    int 0x13                        ;read the sector from USB/HDD
    jc .error
    ret
    
    .error:
        mov si, error_message
        call print_string           ;print error_message
        jmp $                       ;stuck here forever (infinite loop)

error_message db 'Failed to read sector from HDD/USB', 10, 13, 0

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file