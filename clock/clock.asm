;=========================
;        CLOCK
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

;main here
;From get real clock time https://riptutorial.com/x86/example/23463/bios-calls

mov ah, 0x02             ; Select 'Read system time' function
int 0x1A                 ; RTC services interrupt
                         ; Now CH contains hour, CL minutes, DH seconds, and DL the DST flag,
                         ; all encoded in BCD (DL is zero if in standard time)
                         ; Now we can decode them into a string (we'll ignore DST for now)

mov al, ch               ; Get hour
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [CLOCK_STRING+0], al ; Set ten's place of hour
mov al, ch               ; Get hour again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [CLOCK_STRING+1], al ; Set one's place of hour

mov al, cl               ; Get minute
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [CLOCK_STRING+3], al ; Set ten's place of minute
mov al, cl               ; Get minute again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [CLOCK_STRING+4], al ; Set one's place of minute

mov al, dh               ; Get second
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [CLOCK_STRING+6], al ; Set ten's place of second
mov al, dh               ; Get second again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [CLOCK_STRING+7], al ; Set one's place of second

; output date
mov ah, 0x04
int 0x1a	; get date: ch - century, cl - year, dh - month, dl -day

mov al, dl               ; Get day
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [DATE_STRING+0], al ; Set ten's place of day
mov al, dl               ; Get day again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [DATE_STRING+1], al ; Set one's place of day

mov al, dh               ; Get month
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [DATE_STRING+3], al ; Set ten's place of month
mov al, dh               ; Get month again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [DATE_STRING+4], al ; Set one's place of month

mov al, ch               ; Get hour
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [DATE_STRING+6], al ; Set ten's place of hour
mov al, ch               ; Get hour again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [DATE_STRING+7], al ; Set one's place of hour

mov al, cl               ; Get minute
shr al, 4                ; Discard one's place for now
add al, 48               ; Add ASCII code of digit 0
mov [DATE_STRING+8], al ; Set ten's place of minute
mov al, cl               ; Get minute again
and al, 0x0F             ; Discard ten's place this time
add al, 48               ; Add ASCII code of digit 0 again
mov [DATE_STRING+9], al ; Set one's place of minute


mov si, DATE_STRING
call print_string

mov si, big_space
call print_string

mov si, CLOCK_STRING
call print_string

mov si, new_line
call print_string

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
        ;je .print_number
        je .check_0

        mov bx, 10                  ;init bx to 10

        div bx                      ;divide ax to bx => DX = AX / BX

        push dx                     ;push result in stack

        inc cx                      ;increase counter
        xor dx, dx                  ;set dx to 0
        jmp .setup
    
    .check_0:
        cmp cx, 0
        jne .print_number

        ;mov dx, 0
        push dx
        inc cx

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
CLOCK_STRING db '00:00:00', 0   ; Place in some separate (non-code) area
big_space db '            ', 0
DATE_STRING db '00.00.0000', 0
new_line db 10, 13

;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file