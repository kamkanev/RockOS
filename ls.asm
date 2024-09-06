;=========================
;          LIST
;=========================

[bits 16]
[org 0x7c00]                    ;tell NASM the code is running shell at address 0x0000_8000

%define BOOTSECTOR_ADDRESS 0x7c0
%define FILES_ADDRESS 0x7E00
%define FILES_ADDR_OFFSET 8  
%define SHELL_SEGMENT 0x800       

%define ENTER_KEY 0x1c
%define BACKSPACE_KEY 0x0e

;init segment register
mov ax, 0
mov ds, ax                          ;set data segment
mov es, ax                          ;set extra segment
mov ss, ax                          ;set stack segment

mov bp, 0x7c00                      ;set stack base pointer
mov sp, bp                          ;set stack pointer


;mov ah, 0x00                        ;BIOS code to set video mode
;mov al, 0x03                        ;80x25 text mode
;int 0x10                            ;set video mode

mov bx, FILES_ADDRESS               ;destination address in RAM where data from sector 2 is going to be loaded
mov cl, 2                           ;which sector (2) to read from HDD/USB
call read_sector                    ;read sector from USB

;mov si, new_line
;call print_string

call print_files

;mov si, new_line
;call print_string
;mov si, new_line
;call print_string
;mov si, any_key
;call print_string


;mov ah, 0x00                        ;BIOS code to read keyboard
;int 0x16                            ;read a single keystroke from the keyboard


jmp SHELL_SEGMENT:0x0000            ;go back to shell

;print all files avaiable on USB
;WOULD SEPARATE IN SEPARATE APP/FILE LATER ON
print_files:
    cld
    mov bx, 0                       ;reset file counter

    .next_file:
        mov ax, [file_list + bx]
        cmp ax, no_file
        je .return
        mov si, ax                  ;si 1st char of curr file name in file_list( files.asm)
        call print_string           ;print first file from files.asm
        mov si, new_line
        call print_string
        add bx, 2                   ;point bx to next file name
        jmp .next_file              ;process next file name

    .return: ret

;procedure to print a string
print_string:
    cld                             ;clear directional flag
    mov ah, 0x0e                    ;enable teletype output for int 0x10 BIOS call
    
    .next_char:
        lodsb                       ;read next byte from (e)si and the inc si
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

;variables
;any_key db 'Press any key to return...', 0
error_message db 'Failed to read sector from HDD/USB', 10, 13, 0
new_line db 10, 13
no_file dw 0
file_list dw FILES_ADDRESS                              ;list
          dw FILES_ADDRESS + FILES_ADDR_OFFSET          ;info
          dw FILES_ADDRESS + 2 * FILES_ADDR_OFFSET      ;clear
          dw FILES_ADDRESS + 3 * FILES_ADDR_OFFSET      ;theme
          dw FILES_ADDRESS + 4 * FILES_ADDR_OFFSET      ;clock
          dw FILES_ADDRESS + 5 * FILES_ADDR_OFFSET      ;snake
          dw FILES_ADDRESS + 6 * FILES_ADDR_OFFSET      ;tetros
          dw FILES_ADDRESS + 7 * FILES_ADDR_OFFSET      ;pong
          dw FILES_ADDRESS + 8 * FILES_ADDR_OFFSET      ;reboot
          dw no_file
;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file