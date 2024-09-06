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

int 0x19                 ; That's it! One call. Just make sure nothing has overwritten the
                         ; interrupt vector table, since this call does NOT restore them to the
                         ; default values of normal power-up. This means this call will not
                         ; work too well in an environment with an operating system loaded.

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file