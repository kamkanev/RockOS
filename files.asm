;=========================
;       BOOTLOADER
;=========================

[bits 16]                   ;tell NASM to wotk with 16bit code

db 'pong', 0, 0, 0, 0
db 'tetris', 0, 0
db 'space', 0, 0, 0

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file