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

mov ax, [print_val]
call print_decimal

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

;procedure to print a decimal value from AX
print_decimal:
    ;cld
    ;initialize count
    mov cx,0
    mov dx,0

    .setup:
        cmp ax, 0                   ;if ax is zero go to printing
        je .print_number

        mov bx, 10                  ;init bx to 10

        div bx                      ;divide ax to bx => DX = AX / BX

        push dx                     ;push result in stack

        inc cx                      ;increase counter
        xor dx, dx                  ;set dx to 0
        jmp .setup
    
    .print_number:
        mov ah, 0x0e                    ;enable teletype output for int 0x10 BIOS call

        .print_char:
            cmp cx, 0                   ;if cx, 0 exit if not continue to print
            je .return

            pop dx                      ;get last value in stack
            add dx, 48                  ;add 48 ASCII for '0'

            mov al, dl
            ;cmp al, 0                   ;match the '/000' termnating char of a string
            ;je .return
            int 0x10                    ;assuming ah = 0x0e int 0x10 will print a single char

            dec cx
            jmp .print_char
    
    .return: ret

;variables
;any_key db 'Press any key to return...', 0
print_val dw 652
new_line db 10, 13
no_file dw 0

;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file