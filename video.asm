%include "macros.asm"

; Plots a single pixel of a specified color.
;
; Input: AL contains the color of the pixel.
;        CX contains the pixel's X coordinate.
;        DX contains the pixel's Y coordinate.
Plot_Point:
    push    ds
    push    si

    mov     bx, 0xA000              ; Video memory start addr
    mov     ds, bx

    imul    bx, dx, 320
    add     bx, cx
    
    mov     si, 320 * 200           ; 64,000
    cmp     bx, si
    cmova   bx, si
    
    mov     byte[ds:bx], al

    pop     si
    pop     ds

    ret


; Plots a line with a specified color between
; two points.
;
; Input size: 16
; Input: 
;       y1
;       x1
;       y0
;       x0
;       Color
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
    ; BP - 2   <- AX backup
    ; BP - 4   <- BX backup
    ; BP - 6   <- CX backup
    ; BP - 8   <- DX backup
    ; BP - 10  <- DS backup
    ; BP - 12  <- SI backup
    ; BP - 14  <- SX
    ; BP - 16  <- SY
    ; BP - 18  <- ERR

    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    cx
    push    dx
    push    ds
    push    si

    sub     sp, 6

    mov     bx, 0xA000              ; Set segment to video memory address (0000A000 * 16 = 000A0000)
    mov     ds, bx

    ; dx := abs(x1 - x0)
    mov     si, [bp + 10]
    sub     si, [bp + 6]
    abs     si, ax                  ; DX

    ; dy := abs(y1 - y0)
    mov     di, [bp + 12]
    sub     di, [bp + 8]
    abs     di, ax                  ; DY

    ; if x0 < x1 then sx := 1 else sx := -1
    mov     ax, [bp + 10]           ; x1
    sub     ax, [bp + 6]            ; x0
    sign    ax, 16
    mov     [bp - 14], ax           ; SX

    ; if y0 < y1 then sy := 1 else sy := -1
    mov     ax, [bp + 12]           ; y1
    sub     ax, [bp + 8]            ; y0
    sign    ax, 16
    mov     [bp - 16], ax           ; SY

    ; err := dx - dy
    mov     [bp - 18], si
    sub     [bp - 18], di

    mov     cx, [bp + 6]            ; Startup at x0
    mov     dx, [bp + 8]            ; Startup at y0

Plot_Line_loop:
    ; Retrieve offset from X and Y (Y * 320) + X
    imul    bx, dx, 320
    add     bx, cx
    
    ; Clamp values between 0 and video block size
    mov     ax, 320 * 200
    cmp     bx, ax
    cmova   bx, ax                  ; "above" is an unsigned condition, -1 compared to 64000
    mov     ax, [bp + 4]            ; still results "above" since -1 is really FFFF.
    
    mov     byte[ds:bx], al         ; Plot point

    ; if x0 = x1 and y0 = y1 break
    cmp     cx, [bp + 10]
    jne     Plot_Line_cont
    cmp     dx, [bp + 12]
    jne     Plot_Line_cont
    
    add     sp, 6                   ; Clear local variables

    pop     si
    pop     ds
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    mov     sp, bp
    pop     bp

    ret

Plot_Line_cont:
    xor     ax, ax

    ; e2 := 2 * err
    mov     bx, [bp - 18]
    shl     bx, 1                   ; Here we multiply err by 2

    ; if e2 > -dy then
    ;   err := err - dy
    ;   x0 := x0 + sx
    ; end
    neg     di
    cmp     bx, di
    cmovg   ax, di
    add     [bp - 18], ax
    mov     ax, 0
    cmp     bx, di
    cmovg   ax, [bp - 14]
    neg     di
    add     cx, ax

    ; if e2 < dx then
    ;   err := err + dx
    ;   y0 := y0 + sy
    ; end
    cmp     bx, si
    mov     ax, 0
    cmovl   ax, si
    add     [bp - 18], ax
    mov     ax, 0
    cmp     bx, si
    cmovl   ax, [bp - 16]
    add     dx, ax

    jmp     Plot_Line_loop


; Draws a crosshair that splits the screen
; into 4 quadrants.
;
; Input: AX contains the color of the crosshair.
Plot_Crosshair:
    push    199
    push    319
    push    0
    push    0
    push    ax

    call    Plot_Line

    clear   5, 16

    push    0
    push    319
    push    199
    push    0
    push    ax

    call    Plot_Line

    ret