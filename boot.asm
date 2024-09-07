;=========================
;       BOOTLOADER
;=========================

[bits 16]                   ;tell NASM to wotk with 16bit code
[org 0x7c00]                ;tell NASM the code is running bootsector at address 0x0000_7c00

;shortcuts for addresses
%define BOOTSECTOR_ADDRESS 0x7c00
%define FILES_ADDRESS 0x0000_7E00
%define SHELL_ADDRESS 0x800
%define THEME_ADDR 0x0000_8200

;init segment register
mov ax, 0
mov ds, ax                          ;set data segment
mov es, ax                          ;set extra segment
mov ss, ax                          ;set stack segment

mov bp, BOOTSECTOR_ADDRESS          ;set stack base pointer
mov sp, bp                          ;set stack pointer

;mov si, success_message             ;point source index register to success_message string address
;call print_string
mov ah, 0x00                        ;BIOS code to set video mode
mov al, 0x03                        ;80x25 text mode
int 0x10                            ;set video mode

print into
mov si, intro
call print_string


mov bx, FILES_ADDRESS               ;destination address in RAM where data from sector 2 is going to be loaded
mov cl, 2                           ;which sector (2) to read from HDD/USB
call read_sector                    ;read sector from USB

;0x0000_8000 is where the shell is located
;Physical address = (A * 0x10) + B //real mode
;0x0000_8000 = (0x800 * 0x10) + 0

mov ax, SHELL_ADDRESS                       ;init the segment
mov es, ax                          ;init extra segment register
mov bx, 0                           ;init local offset within the segment
mov cl, 3                           ;sector 3 on USB contains the shell
call read_sector                    ;read sector from USB/HDD


mov ax, THEME_ADDR                  ; init the segment
mov es, ax                          ; init EXTRA SEGMENT register
mov bx, 0                           ; init local offset within the segment
mov cl, 7                           ; theme sector
mov al, 1                           ; how many sectors to read
call read_sector                    ; read sector from USB flash drive


mov word [0x6fe], 0x0500            ; init where assembler would input machine codes by default
jmp SHELL_ADDRESS:0x0000                    ;far jump to the shell

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

;message
intro db 'Type "help" to list the avaiable commands ', 10, 13, 0
;success_message db 'RockOS is loaded!', 10, 13, 0
error_message db 'Failed to read sector from HDD/USB', 10, 13, 0

times 510 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file
dw 0xaa55                       ;set boot signutare