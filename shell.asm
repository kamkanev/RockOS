;=========================
;          SHELL
;=========================

[bits 16]
[org 0x8000]                    ;tell NASM the code is running shell at address 0x0000_8000

%define BOOTSECTOR_ADDRESS 0x7c0
%define FILES_ADDRESS 0x7E00
%define FILES_ADDR_OFFSET 8         

%define ENTER_KEY 0x1c
%define BACKSPACE_KEY 0x0e

;init segment register
mov ax, 0
mov ds, ax                          ;set data segment
mov es, ax                          ;set extra segment
mov ss, ax                          ;set stack segment

mov bp, 0x7c00                      ;set stack base pointer
mov sp, bp                          ;set stack pointer


mov ah, 0x00                        ;BIOS code to set video mode
mov al, 0x03                        ;80x25 text mode
int 0x10                            ;set video mode

;print into
mov si, intro
call print_string

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;main OS loop
shell_loop:

    ;print the user prompt
    mov si, user_prompt
    call print_string

    ;reset user input
    mov di, user_input              ;point DESTINATION INDEX register to user_iput variable adress
    mov al, 0                       ;al is used by stosb
    times 20 stosb                  ; store zeros at di and then inc di
    mov di, user_input

    .next_byte:
        mov ah, 0x00                ;BIOS code to read keyboard
        int 0x16                    ;read a single keystroke from the keyboard

        cmp ah, ENTER_KEY           ; is ENTER pressed
        ;je shell_loop
        je .search             ;search game by name

        cmp ah, BACKSPACE_KEY       ; is BACKSPACE pressed
        je .erase_char

        stosb                       ;store key that has been pressed into user_input
        mov ah, 0x0e                ;BIOS teletype code
        int 0x10                    ;echo typed character
        jmp .next_byte              ;read next key from user

    .erase_char:
        ;erasing in shell
        mov ah, 0x03                ;BIOS code for getting cursor position
        int 0x10                    ;get cursor position
        cmp dl, 3                   ;cursor column to far left
        je .next_byte               ;if so dont erase any more

        mov ah, 0x0e                ;teletype mode eanabled
        mov al, 8                   ; ASCII code for '\b'
        int 0x10                    ;move cursor 1 step back

        mov ah, 0x0e                ;teletype mode eanabled
        mov al, 0                   ; ASCII code for empty char
        int 0x10                    ;move cursor 1 step back

        mov ah, 0x0e                ;teletype mode eanabled
        mov al, 8                   ; ASCII code for '\b'
        int 0x10                    ;move cursor 1 step back

        ;erasing from user_input variable
        mov al, 0                   ;AL is used by stosb
        dec di                      ;go one position back
        stosb                       ;replace with al and inc di
        dec di                      ;do one position back (again)

        jmp .next_byte              ;process next byte

    .search:
        call search_file

    jmp shell_loop

;search file procedure
search_file:
    cmp byte [user_input], 0        ;check first byte user has entered
    je .return

    mov bx, 0                       ;file name index
    mov dl, 3                       ;sector of first executable on USB or flsh drive

    .next_game:
        mov ax, [file_list + bx]
        cmp ax, no_file
        je .no_file_found
        add bx, 2                   ;point bx to the next filename
        inc dl                      ;point to next sector associated to the file name
        call compare_strings        ;compare user_input with file name
        cmp cl, 1                   ;if user input matches file name execute the file
        je execute                  ;execute binary coresponding to the file name and sector (dl)

        jmp .next_game

    .no_file_found:
        mov si, new_line
        call print_string

        mov si, error_no_file
        call print_string
    
    .return: ret

;print all files avaiable on USB
;WOULD SEPARATE IN SEPARATE APP/FILE LATER ON
print_files:
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

;String comparison
;DI => scasb compares value stored in DI which is 's' with 's' stored in AX reg and then inc. DI if DF is 0
;           v
;addr. 1: s|n|a|o|0|        user input
;addr. 2: s|n|a|k|e|0|      file name
;           ^
;SI => lodsb loads value stored at SI to AX and then inc. SI if DF is 0
compare_strings:
    cld                             ;clear direction flag to use later
    mov di, user_input           ;point DI to target input
    mov si, ax                   ;point SI to source string

    .next_byte:
        lodsb                       ;init AX = to where SI points to
        scasb                       ;compare the value of whre DI is pointing at
        jne .return_false
        cmp al, 0                   ;if reach term 0 at the end
        je .return_true

        jmp .next_byte

    .return_true:
        mov cl, 1
        ret

    .return_false:
        mov cl, 0
        ret


;procedure execute boot sector game/file
execute:

    mov ax, BOOTSECTOR_ADDRESS                   ;init the segment
    mov es, ax                      ;init extra segment register
    mov bx, 0                       ;init local offset
    mov cl, dl                       ;select sector (4) from USB/HDD
    call read_sector                ;read sector
    jmp BOOTSECTOR_ADDRESS:0x0000                ;jump to the shell

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

;mesages
error_message db 'Failed to read sector from HDD/USB', 10, 13, 0
error_no_file db 'No file found!',0;, 10, 13, 0

;variables
intro db 'Welcome to RockOS! Type "list" to list the avaiable games ', 10, 13, 0
user_prompt db 10, 13, ' > ', 0
user_input times 20 db 0
new_line db 10, 13
no_file dw 0
file_list dw FILES_ADDRESS, FILES_ADDRESS + FILES_ADDR_OFFSET, FILES_ADDRESS + 2 * FILES_ADDR_OFFSET, no_file

;temp vars

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file