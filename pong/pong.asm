;=====================
;       PONG
;=====================

[bits 16]                   ;tell NASM to wotk with 16bit code
[org 0x7c00]                ;tell NASM the code is running bootsector at address 0x0000_7c00

jmp setup_game              ;jump over the vars segment
; ======== CONSTANTS =========
VIDMEM equ 0B800h
ROWLEN equ 160                  ;80 char * 2 bytes
PLAYERX equ 4                   ;Player X offset  to row 1 start screen
AIX     equ 154                 ;cpu X offset from end screen by 1 row
KEY_UP  equ 048h
KEY_DW  equ 050h
KEY_C   equ 2Eh
KEY_R   equ 13h
SCREENW equ 80
SCREENH equ 24
SIZE_P  equ 5

; ======== VARS =========
drawColor:  db 0F0h
playerY:    dw 10                      ;start player at y postion 10 rows down
aiY:        dw 10                      ;start cpu at y postion 10 rows down

ballX:      dw 66                       ;starting ball X position
ballY:      dw 8                        ;y starting position for the ball
ballVX:     db -1
ballVY:     db 1

playerSCORE db 0
aiSCORE     db 0

; ======== LOGIC =========
setup_game:
;set to video mode
mov ax, 0x03            ;set video mode text mode to 80x25 chars, 16 colors
int 0x10

;set up video memory
mov ax, VIDMEM
mov es, ax              ;es:di <- B800:0000

;game loop
game_loop:
    ;clear screen every loop cycle
    ;black background
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

;drawing on screen

    ;drawing middle deviding line
    mov ah, [drawColor]         ;white bg, black fg
    mov di, 78           ;start at middle of 80 char row
    mov cx, 13           ;dashed line - is drawn every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN-2             ;only draw every other row (80 chars * 2 bytes * 2 rows)
        loop .draw_middle_loop

    ;draw player and ai paddle
    imul di, [playerY], ROWLEN          ;Y position is Y # of rows * len of row
    imul bx, [aiY], ROWLEN
    mov cl, SIZE_P
    .draw_player_loop:
        mov [es:di+PLAYERX], ax
        mov [es:bx+AIX], ax
        add di, ROWLEN
        add bx, ROWLEN
        loop .draw_player_loop

    ;draw ball
    imul di, [ballY], ROWLEN
    add di, [ballX]
    mov word [es:di], 2020h

;player input
    mov ah, 1                           ;BIOS get keyboard status with int 0x16 ah 1
    int 0x16
    jz move_ai                          ;no keys pressed dont interupt and continue

    cbw                                 ;zero out ah in 1 byte
    int 0x16                            ;BIOS read key pressed, scancode in AH, char in AL

    cmp ah, KEY_UP
    je up_pressed
    cmp ah, KEY_DW
    je down_pressed
    cmp ah, KEY_C
    je c_pressed
    cmp ah, KEY_R
    je r_pressed

    jmp move_ai                         ;other key is pressed

    ;move paddle up
    up_pressed:
        dec word[playerY]               ;move up 1 row
        jge move_ai
        inc word[playerY]

        jmp move_ai

    ;move down the player
    down_pressed:
        cmp word [playerY], SCREENH - SIZE_P ;player at bottom screen
        jg move_ai
        inc word[playerY]               ;move 1 row down
        jmp move_ai

    ;change color
    c_pressed:
        add byte[drawColor], 10h
        jmp move_ai

    ;reset game
    r_pressed:
        int 19h                         ;reset vecotor to reload bootlsector

;move ai
    move_ai:
        mov bx, [aiY]
        cmp bx, word [ballY]
        jle move_ai_down
        dec word[aiY]
        jnz move_ball
        inc word[aiY]

    move_ai_down:
        add bx, SIZE_P
        cmp bx, word[ballY]
        jge move_ball
        inc word[aiY]

        cmp word[aiY], SCREENH
        jl move_ball
        dec word[aiY]

;move ball
    move_ball:

        mov bl, [ballVX]                ;move ball by x
        add [ballX], bl

        mov bl, [ballVY]                ;move ball by y
        add [ballY], bl

;collisions
    check_hit_top:
        cmp word [ballY], 0
        jg check_hit_bot
        neg byte[ballVY]
        jmp end_collisions_check

    check_hit_bot:
        cmp word [ballY], 24
        jl check_hit_player
        neg byte[ballVY]
        jmp end_collisions_check

    check_hit_player:
        cmp word [ballX], PLAYERX
        jne check_hit_ai
        mov bx, [playerY]
        cmp bx, [ballY]
        jg check_hit_ai
        add bx, SIZE_P
        cmp bx, [ballY]
        jl check_hit_ai
        neg byte[ballVX]

        jmp end_collisions_check

    check_hit_ai:
        cmp word[ballX], AIX
        jne end_collisions_check
        mov bx, [aiY]
        cmp bx, word[ballY]
        jg end_collisions_check
        add bx, SIZE_P
        cmp bx, word[ballY]
        jl end_collisions_check
        neg byte[ballVX]


    end_collisions_check:
    ;delay loop
    mov bx, [0x46C]
    inc bx
    inc bx
    .delay:

        cmp [0x46C], bx
        jl .delay

jmp game_loop

;win/lose conditions

times 510 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file
dw 0xaa55                       ;set boot signutare