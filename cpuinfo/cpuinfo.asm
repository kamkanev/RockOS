;=========================
;        CPU INFO
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

mov si, new_line
call print_string

mov si, test_word
mov cl, 4
call print_word
mov si, new_line
call print_string
;mov si, any_key
;call print_string

;mov ah, 0x00                        ;BIOS code to read keyboard
;int 0x16                            ;read a single keystroke from the keyboard


jmp SHELL_SEGMENT:0x0000            ;go back to shell

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

print_word:

    cmp cl, 0
    je .return
    cld
    mov ah, 0x0e

    .next_word:
        lodsb
        dec cl
        cmp al, 0
        je .zero_word
        ;add something more for hex print
        int 0x10

        cmp cl, 0
        je .return
        jmp .next_word

    .zero_word:
        mov al, '0'
        int 0x10
        cmp cl, 0
        je .return
        jmp .next_word
    
    .return: ret

;variables
;any_key db 'Press any key to return...', 0
test_word db 0x55, 0xaa, 0x00, 0xbb
new_line db 10, 13
no_file dw 0

;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file