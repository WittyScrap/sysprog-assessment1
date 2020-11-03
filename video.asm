%macro abs 2
    mov     %2, %1
    neg     %1
    cmovl   %1, %2
%endmacro

; Plots a single pixel of a specified color.
;
; Input: AL contains the color of the pixel.
;        CX contains the pixel's X coordinate.
;        DX contains the pixel's Y coordinate.
Plot_Point:
    mov     ah, 0Ch
    mov     bh, 0
    int     10h

    ret


; Plots a line with a specified color between
; two points.
;
; Input size: 16
; Input: 
;       Color code
;       x0
;       y0
;       x1
;       y1
Plot_Line:
    ; Stack Frame Layout:
    ; 
    ; BP + 12  <- y1
    ; BP + 10  <- x1
    ; BP + 8   <- y0
    ; BP + 6   <- x0
    ; BP + 4   <- Color
    ; BP + 2   <- Ret Addr
    ; BP       <- BP
    ; BP - 2   <- SX
    ; BP - 4   <- SY
    ; BP - 6   <- ERR

    push    bp
    mov     bp, sp

    add     sp, 6

    ; dx := abs(x1 - x0)
    mov     si, [bp + 10]
    sub     si, [bp + 6]
    abs     si, ax                  ; DX

    ; dy := abs(y1 - y0)
    mov     di, [bp + 12]
    sub     di, [bp + 8]
    abs     di, ax                  ; DY

    ; if x0 < x1 then sx := 1 else sx := -1
    mov     ax, [bp + 6]            ; x0
    cmp     [bp + 10], ax           ; x1
    lahf
    and     ax, 8000h               ; 8000h = 1 << 15
    shr     ax, 15
    sub     ax, 1
    mov     [bp - 2], ax            ; [bp - 2] = SX

    ; if y0 < y1 then sy := 1 else sy := -1
    mov     ax, [bp + 8]            ; y0
    cmp     [bp + 12], ax           ; y1
    lahf
    and     ax, 8000h               ; 8000h = 1 << 15
    shr     ax, 15
    sub     ax, 1
    mov     [bp - 4], ax            ; [bp - 4] = SY

    ; err := dx - dy
    mov     [bp - 6], si
    sub     [bp - 6], di

    mov     cx, [bp + 6]            ; Startup at x0
    mov     dx, [bp + 8]            ; Startup at y0
    mov     al, [bp + 4]            ; Line color
    mov     ah, 0Ch

Plot_Line_loop:
    mov     bh, 0
    pop     ax
    int     10h                     ; Plot point

    push    ax
    xor     ax, ax

    ; if x0 = x1 and y0 = y1 break
    cmp     cx, [bp + 10]
    jne     Plot_Line_cont
    cmp     dx, [bp + 12]
    jne     Plot_Line_cont
    jmp     Plot_Line_endloop

Plot_Line_cont:
    shl     word[bp - 6], 1         ; Here we multiply err by 2
    push    di
    neg     di
    cmp     [bp - 6], di
    shr     word[bp - 6], 1
    pop     di
    cmovg   ax, di
    sub     [bp - 6], ax
    mov     ax, 0
    cmovg   ax, [bp - 2]
    add     cx, ax

    shl     word[bp - 6], 1         ; Here we multiply err by 2
    cmp     [bp - 6], si 
    shr     word[bp - 6], 1
    mov     ax, 0
    cmovl   ax, si
    add     [bp - 6], ax
    mov     ax, 0
    cmovl   ax, [bp - 4]
    add     dx, ax

Plot_Line_endloop:
    mov     sp, bp
    pop     bp

    ret