; Converts an 8-bit or 16-bit number to a base-10 string representation.
;
; INPUT: DI points to an output buffer.
;        AX contains the number to be converted.
; OUTPUT: Final string will be stored in the buffer pointed to by SI.
To_String_Dec:
    mov     bx, 10
    xor     cx, cx
    mov     si, To_String_Buff + 5

To_String_Dec_loop:
    xor     dx, dx
    sub     si, 1
    div     bx
    add     dx, '0'
    mov     byte[si], dl
    add     cx, 1
    test    ax, ax
    jnz     To_String_Dec_loop

    ; Move cx bytes from ds:si (temporary buffer) to es:di (output buffer)
    mov     dx, cx
    rep     movsb
    mov     byte[di], 0         ; Null terminator
    sub     di, dx

    ret

To_String_Buff:
    times   5 db 0              ; This is placed right after a ret and will never be hit
                                ; if the file is included correctly (which it absolutely should
                                ; be). The registers we are dealing with are 16-bit, so there are
                                ; no situations in which the output number could be larger than 5
                                ; digits, so no code can be overwritten.


; Converts a number to a 4-digit base-16 string representation and prints it.
;
; INPUT: BX contains the 16-bit input number to be converted.
Console_WriteHex:
    mov     cx, 4
    mov     ah, 0Eh

Console_WriteHex_Loop:
    mov     si, 0Fh
    rol     bx, 4
    and     si, bx
    mov     al, [HEX_ASCII + si]
    int     10h
    loop    Console_WriteHex_Loop

    ret


; Converts a number to a 4-digit base-16 string representation.
;
; INPUT: SI points to an allocated output buffer.
;        AX contains the 16-bit input number to be converted.
; OUTPUT: Final string will be stored in the buffer pointed to by SI.
To_String_Hex:
    add     si, 3

To_String_Hex_Next:
    mov     di, 0Fh
    and     di, ax
    mov     cl, [HEX_ASCII + di]
    mov     [si], cl
    sub     si, 1
    shr     ax, 4
    jnz     To_String_Hex_Next
    mov     byte[si + 4], 0

    ret


; Hex chars LUT
HEX_ASCII:      db "0123456789ABCDEF"