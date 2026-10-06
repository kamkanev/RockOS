; DS=ES=0. arg_ptr names a single component, at most 11 bytes.
; Preserve directory scan registers; AL=1 when the entry matches.
names_equal:
    push bx
    push cx
    push di
    mov bx, [arg_ptr]
    mov di, si
    mov cx, 11
.compare:
    mov al, [bx]
    cmp al, 0
    je .end
    cmp al, ' '
    je .end
    cmp al, [di]
    jne .no
    inc bx
    inc di
    loop .compare
    mov al, [bx]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
    jmp .no
.end:
    cmp byte [di], 0
    jne .no
.yes:
    mov al, 1
    jmp .done
.no:
    xor al, al
.done:
    pop di
    pop cx
    pop bx
    ret

; Reject names which would otherwise be silently truncated or act as paths.
valid_name:
    mov bx, [arg_ptr]
    xor cx, cx
.next:
    mov al, [bx]
    test al, al
    jz .end
    cmp al, ' '
    je .end
    cmp al, '/'
    je .no
    cmp al, 0x5c
    je .no
    inc cx
    cmp cx, 11
    ja .no
    inc bx
    jmp .next
.end:
    jcxz .no
    mov bx, [arg_ptr]
    cmp byte [bx], '.'
    jne .yes
    cmp cx, 1
    je .no
    cmp cx, 2
    jne .yes
    cmp byte [bx+1], '.'
    je .no
.yes:
    mov al, 1
    ret
.no:
    xor al, al
    ret
