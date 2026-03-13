;=========================
;       BOOTLOADER
;=========================

[bits 16]                   ;tell NASM to wotk with 16bit code

db 'help', 0, 0, 0, 0
db 'info', 0, 0, 0, 0
db 'clear', 0, 0, 0
db 'theme', 0, 0, 0
db 'clock', 0, 0, 0
db 'snake', 0, 0, 0
db 'mines', 0, 0, 0
db 'pong', 0, 0, 0, 0
db 'tetris', 0, 0
db 'reboot', 0, 0
db 'ls', 0, 0, 0, 0, 0, 0
db 'cd', 0, 0, 0, 0, 0, 0
db 'mkdir', 0, 0, 0
db 'touch', 0, 0, 0
db 'nano', 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file
