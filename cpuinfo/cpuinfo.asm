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

;mov si, new_line
;call print_string

;print flags
mov si, flags_str
call print_string
xor ax, ax
lahf
call print_decimal
mov si, new_line
call print_string

;print control registers
mov si, control_reg
call print_string
mov eax, cr0
call print_decimal
mov si, new_line
call print_string

;print stack segment
mov si, stack_segment
call print_string
;mov word[print_val], bp
mov ax, ss;[print]
call print_decimal
mov si, new_line
call print_string

;print data segment
mov si, data_segment
call print_string
;mov word[print_val], ds
mov ax, ds;[print_val]
call print_decimal
mov si, new_line
call print_string

;print code segment
mov si, code_segment
call print_string
mov ax, cs
call print_decimal
mov si, new_line
call print_string

;print extra segment
mov si, extra_segment
call print_string
mov ax, es
call print_decimal
mov si, new_line
call print_string

;mov si, new_line
;call print_string

;STACK
;print base pointer
mov si, base_pointer
call print_string
mov ax, bp
call print_decimal
mov si, new_line
call print_string
;print stack pointer
mov si, stack_pointer
call print_string
mov ax, sp
call print_decimal
mov si, new_line
call print_string

;mov si, new_line
;call print_string

;CPUID EAX=0h
mov si, new_line
call print_string
mov si, cpuid_maxval_str
call print_string

mov eax, 0x0
cpuid
push edx
push ecx
push ebx
call print_decimal

mov si, new_line
call print_string
mov si, max_cpuid_genu_str
call print_string
pop eax
call print_decimal

mov si, new_line
call print_string
mov si, max_cpuid_ntel_str
call print_string

pop eax
call print_decimal

mov si, new_line
call print_string
mov si, max_cpuid_itel_str
call print_string

pop eax
call print_decimal

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
;any_key db 'Press any key to return...', 0
;print_val dw 0
flags_str db 'FLAGS: ', 0
control_reg db 'Control Reg (CR0): ', 0
stack_segment db 'Stack Seg (SS): ', 0
code_segment db 'Code Seg (CS): ', 0
data_segment db 'Data Seg (DS): ', 0
extra_segment db 'Extra Seg (ES): ', 0
base_pointer db 'Base Pointer(BP): ', 0
stack_pointer db 'Stack Pointer(SP): ', 0

cpuid_maxval_str db 'Maximum Input Value for Basic CPUID Information : ', 0
max_cpuid_genu_str db 'Genu : ', 0
max_cpuid_ntel_str db 'ntel : ', 0
max_cpuid_itel_str db 'itel : ', 0

;note_str db 'All values are in decimal', 0
new_line db 10, 13

;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file