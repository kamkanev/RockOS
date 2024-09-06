;=========================
;       BOOTLOADER
;=========================

[bits 16]                   ;tell NASM to wotk with 16bit code

db 'list', 0, 0, 0, 0
db 'info', 0, 0, 0, 0
db 'clear', 0, 0, 0
db 'theme', 0, 0, 0
db 'clock', 0, 0, 0
db 'snake', 0, 0, 0
db 'tetros', 0, 0
db 'pong', 0, 0, 0, 0
db 'reboot', 0, 0

times 512 - ($ - $$) db 0       ;fill trailing zeros to get exacly 512 bytes long binary file