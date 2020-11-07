%include "macros.asm"

; Plots a single pixel of a specified color.
;
; Input: AL contains the color of the pixel.
;        CX contains the pixel's X coordinate.
;        DX contains the pixel's Y coordinate.
Plot_Point:
    push    ds
    push    si

    mov     bx, 0xA000              ; Set segment to video memory address (0000A000 * 16 = 000A0000)
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
    
    ; Clamp values between 0 and video block size.
    ; This will allow X values greater than the
    ; screen width to appear to overflow back to
    ; the other side of the screen, since video
    ; memory is a contiguous block.
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


; Draws a rectangle on the screen at the given
; location and with the given scale and color.
;
; Input size: 16
; Input:
;       sy
;       sx
;       py
;       px
;       Color
Plot_Rect:
    ; Stack Frame Layout:
    ; 
    ; BP + 12  <- sy
    ; BP + 10  <- sx
    ; BP + 8   <- py
    ; BP + 6   <- px
    ; BP + 4   <- Color
    ; BP + 2   <- Ret Addr
    ; BP       <- BP
    ; BP - 2   <- AX backup
    ; BP - 4   <- BX backup
    ; BP - 6   <- CX backup
    ; BP - 8   <- DX backup
    ; BP - 10  <- DS backup
    ; BP - 12  <- SI backup
    ret

; Draws a circle at a specified location and with
; a specified radius and color.
;
; Input size: 16
; Input:
;       Color
;       Radius
;       x
;       y
Plot_Circle:
    ; Stack Frame Layout:
    ; 
    ; BP + 10  <- Color
    ; BP + 8   <- Radius
    ; BP + 6   <- x
    ; BP + 4   <- y
    ; BP + 2   <- Ret Addr
    ; BP       <- BP
    ; BP - 2   <- AX backup
    ; BP - 4   <- BX backup
    ; BP - 6   <- CX backup
    ; BP - 8   <- DX backup
    ; BP - 10  <- DS backup
    ; BP - 12  <- SI backup
    ; BP - 14  <- DI backup
    ; BP - 16  <- N
    ; BP - 18  <- N*N

    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    cx
    push    dx
    push    ds
    push    si
    push    di

    sub     sp, 4

    mov     bx, 0xA000              ; Set segment to video memory address (0000A000 * 16 = 000A0000)
    mov     ds, bx

    imul    bx, [bp + 8], 2
    add     bx, 1
    mov     [bp - 16], bx           ; N

    imul    bx, bx
    mov     [bp - 18], bx           ; N * N

    xor     bx, bx

Plot_Circle_loop:
    xor     dx, dx
    mov     ax, bx

    div     word[bp - 16]
    mov     cx, ax                  ; Now CX contains i and DX contains j

    sub     cx, [bp + 8]
    sub     dx, [bp + 8]

    mov     si, cx
    mov     di, dx

    imul    cx, cx
    imul    dx, dx

    add     cx, dx

    mov     dx, [bp + 8]
    imul    dx, dx
    add     dx, 1
    
    add     si, [bp + 6]
    add     di, [bp + 4]

    imul    di, di, 320
    add     di, si

    mov     ax, 320 * 200
    cmp     di, ax
    cmova   di, ax

    mov     ax, [ds:di]
    cmp     cx, dx
    cmovle  ax, [bp + 10]

    mov     [ds:di], ax

    add     bx, 1
    cmp     bx, [bp - 18]

    jl      Plot_Circle_loop

    add     sp, 4

    pop     di
    pop     si
    pop     ds
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    pop     bp

    ret


; Draws a crosshair that splits the screen
; into 4 quadrants.
;
; Input: AX contains the color of the crosshair.
Demo_Crosshair:
    line    0, 100, 319, 100, ax
    line    160, 0, 160, 199, ax

    ret


; Demonstrates usage of the line drawing function.
; 8 lines will be drawn on the top-left quadrant.
;
; Input: None
Demo_Lines:
    line    0, 0, 159, 99, 1
    line    159, 0, 0, 99, 2
    line    79, 0, 79, 99, 3
    line    0, 49, 159, 49, 4
    line    39, 0, 119, 99, 5
    line    119, 0, 39, 99, 6
    line    0, 24, 159, 74, 7
    line    0, 74, 159, 24, 8

    ret


; Demonstrates usage of the circle drawing function.
; 3 circles of varying sizes and colours will be drawn
; on the bottom-left quadrant.
;
; Input: None
Demo_Circles:
    circle  15, 120, 10, 10
    circle  40, 180, 5, 12
    circle  90, 150, 35, 14

    ret