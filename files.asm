;=========================
;       BOOTLOADER
;=========================

[bits 16]                   ;tell NASM to wotk with 16bit code

db 'Here are the available games', 0
db 'pong', 0
db 'tetris', 0
db 'space invaders', 0

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file