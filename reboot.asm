;=========================
;         REBOOT
;=========================

[bits 16]
[org 0x7c00]

start:
    cli

    ; BIOS warm-boot flag at BDA:0x72 (physical 0x0472)
    ; 0x1234 asks BIOS to do warm reboot path.
    xor ax, ax
    mov ds, ax
    mov word [0x0472], 0x1234

    ; Jump to BIOS reset vector.
    jmp 0xFFFF:0x0000

    ; Fallbacks if BIOS returns unexpectedly.
    int 0x19
.hang:
    hlt
    jmp .hang

times 512 - ($ - $$) db 0
