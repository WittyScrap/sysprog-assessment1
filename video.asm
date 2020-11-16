%include "macros.asm"

; Plots a single pixel of a specified color.
;
; Input: 
;       AL <- The color of the pixel.
;       CX <- The pixel's X coordinate.
;       DX <- The pixel's Y coordinate.
Plot_Point:
    push    ds
    push    si

    mov     bx, Back_Buff_Segment              ; Set segment to video memory address (0000A000 * 16 = 000A0000)
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

    mov     bx, Back_Buff_Segment              ; Set segment to video memory address (0000A000 * 16 = 000A0000)
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
    push    ax
    cmp     cx, [bp + 10]           ; Compare X0 with X1
    lahf
    mov     al, ah                  ; Store flags result in al
    cmp     dx, [bp + 12]           ; Compare Y0 with Y1
    lahf                            ; Store flags result in ah
    and     ah, al                  ; AND ah and al (if ZF was 0 in either it will now be 0)
    and     ah, 64 ; Where ZF is    ; AND ah with 01000000 (where ZF is stored)
    sahf                            ; Store flags back
    pop     ax
    jnz     Plot_Line_cont          ; If the ZF not set it means we can continue
    
    add     sp, 6                   ; Clear local variables

    pop     si
    pop     ds
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    pop     bp

    ret     10

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


; Plots a polygon composed of multiple lines.
;
; Polygon layout (16-bit per component):
;               X0, Y0,
;               X1, Y1,
;               X2, Y2,
;               ...
;               XN, YN
;
; Input size: 16
; Input:
;       DS <- Set to the segment in which the layout buffer is located
;       SI <- Pointer to polygon layout buffer
;       AX <- Number of points
;       DX <- Color
Plot_Poly:
    push    ax
    push    bx
    push    cx
    push    es
    push    ds

    push    bp
    mov     bp, sp

    sub     ax, 1               ; Discards first point
    
    mov     bx, ss
    mov     es, bx              ; Set destination segment to the stack segment

    sub     sp, 10              ; Reserve space for input stack frame
    mov     [bp - 10], dx       ; Store color

Plot_Poly_loop:
    mov     cx, 4               ; 4 words to be moved (Y1, X1, Y0, X0)
    lea     di, [bp - 8]        ; Set destination index to stack pointer, minus a word to not overwrite color

    rep     movsw               ; Move cx (4) words from ds:si (xx:ptr to data) to es:di (ss:bp), incrementing both in the process.
    call    Plot_Line           ; Plot the line

    sub     si, 4               ; Get back the previous two points to carry on
    sub     sp, 10              ; Get stack pointer back where it was (reserving 5 input vars)

    sub     ax, 1 
    test    ax, ax
    jnz     Plot_Poly_loop

    mov     sp, bp
    pop     bp

    pop     ds
    pop     es
    pop     cx
    pop     bx
    pop     ax

    ret


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
    ; BP - 10  <- DS backup
    ; BP - 12  <- ES backup
    ; BP - 16  <- DI backup
    
    push    bp
    mov     bp, sp

    push    ax 
    push    bx 
    push    cx
    push    dx
    push    es
    push    di

    mov     dx, 320 * 200

    mov     ax, Back_Buff_Segment
    mov     es, ax
    mov     bx, [bp + 8]        ; Pos Y
    add     [bp + 12], bx       ; Set end Y instead of size Y

    mov     ax, [bp + 4]        ; Color

Plot_Rect_loop:
    mov     cx, [bp + 10]       ; Size X
    cmp     cx, dx
    cmova   cx, dx              ; Clamping cx using "above" so that values < 0 are clamped to 320 * 200
    imul    di, bx, 320         ; Y offset = Y * 320
    add     di, [bp + 6]        ; Add X pos to compute final addr

    rep     stosb               ; Move cx (size x) bytes from al (color) to es:di (A000:y * 320 + x)

    add     bx, 1
    cmp     bx, [bp + 12]       ; Check against end Y
    jl      Plot_Rect_loop

    pop     di
    pop     es
    pop     dx
    pop     cx
    pop     bx 
    pop     ax

    pop     bp

    ret     10


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

    mov     bx, Back_Buff_Segment
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

    sub     cx, [bp + 8]            ; Subtract radius to obtain X
    sub     dx, [bp + 8]            ; Subtract radius to obtain Y

    mov     si, cx                  ; Backup X into SI
    mov     di, dx                  ; Backup Y into DI

    imul    cx, cx                  ; We are going to be comparing the result of 
    imul    dx, dx                  ; x*x + y*y to r*r to test whether a specific
                                    ; pixel at a given x, y location is inside the
    add     cx, dx                  ; circle we're trying to draw.

    mov     dx, [bp + 8]
    imul    dx, dx                  ; Radius squared
    add     dx, 1                   ; Add 1 to include points on the edge of the circle
    
    add     si, [bp + 6]
    add     di, [bp + 4]

    imul    di, di, 320
    add     di, si                  ; Compute final video offset addr (original x, y are used here)

    mov     ax, 320 * 200
    cmp     di, ax
    cmova   di, ax                  ; Clamp values so that we can't write past the end of the video memory
                                    ; boundaries.
    mov     ax, [ds:di]             ; Now we poll the original value of the current pixel from memory
    cmp     cx, dx
    cmovle  ax, [bp + 10]           ; If the point is inside the circle, override that with the circle's color

    mov     [ds:di], ax             ; Now set the pixel again, if we're outside the circle nothing will change.

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

    mov     sp, bp
    pop     bp

    ret     8


; Draws a 4bpp bitmap located at a custom address of
; any given size that is divisible by 4. The bitmap must
; be indexed and the palette must match the standard VGA
; palette.
;
; Keep in mind the size/location are still limited by other
; factors, such as the size of the screen and the size of the
; bootloader.
;
; Input:
;       DS <- Set to the segment in which the image resides
;       SI <- Set to the address in which the image resides
;       AX <- Set to the X location of the image
;       BX <- Set to the Y location of the image
;
; Remarks:
;       Use the default image.bmp provided for a special
;       surprise!
Draw_Image:
    push    es
    push    cx
    push    dx
    push    bp                      ; We're gonna borrow you as a general purpose register

    mov     bp, si

    mov     cx, Back_Buff_Segment
    mov     es, cx

    mov     dx, bx                  ; This will be our height target
    add     bx, word[bp + 16h]      ; Vertical height of the bitmap since the last row is the first because bitmap is weird
    add     si, word[bp + 0Ah]      ; Add PixelDataOffset to SI to get picture start addr    

Draw_Image_loop:
    mov     cx, word[bp + 12h]      ; Set to the Horizontal width of the bitmap

    imul    di, bx, 320
    add     di, ax

    rep     movsb                   ; memcpy this row...

    sub     bx, 1
    cmp     bx, dx
    jg      Draw_Image_loop

    pop     bp
    pop     dx
    pop     cx
    pop     es

    ret


; Clears the screen using a given color.
;
; Input:
;       AX <- The color to screen the screen with.
Clear_Color:
    push    es
    push    cx
    push    di

    push    ax

    mov     ax, Back_Buff_Segment
    mov     es, ax
    
    pop     ax

    xor     di, di
    mov     cx, 320 * 200 / 2   ; Whole screen
    rep     stosw               ; memset the whole screen with AX (color)

    pop     di
    pop     cx
    pop     es

    ret


; Copies the back buffer into the front buffer.
;
; Input: None
Present:
    push    ds
    push    es
    push    si
    push    di
    push    cx

    mov     cx, 0xA000
    mov     es, cx

    mov     cx, Back_Buff_Segment
    mov     ds, cx

    mov     cx, 320 * 200 / 2

    xor     si, si
    xor     di, di

    rep     movsw

    pop     cx
    pop     di
    pop     si
    pop     es
    pop     ds

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
    line    0, 0, 159, 99, 1001b
    line    159, 0, 0, 99, 1010b
    line    79, 0, 79, 99, 1011b
    line    0, 49, 159, 49, 1100b
    line    39, 0, 119, 99, 1101b
    line    119, 0, 39, 99, 1110b
    line    0, 24, 159, 74, 1111b
    line    0, 74, 159, 24, 0100b

    ret


; Demonstrates usage of the circle drawing function.
; 3 circles of varying sizes and colours will be drawn
; on the bottom-left quadrant.
;
; Input: None
Demo_Circles:
    circle  15, 120, 10, 1010b
    circle  40, 180, 5, 1100b
    circle  90, 150, 35, 1110b

    ret


; Demonstrates usage of the rectangle drawing function.
; 3 rectangles of varying shapes, sizes, and colours will
; be drawn on the top-right quadrant.
;
; Input: None
Demo_Rects:
    rect    170, 10, 100, 50, 0101b
    rect    180, 40, 80, 50, 1011b
    rect    275, 30, 33, 60, 1111b

    ret


; Demonstrates usage of the polygon drawing function.
; 3 Polygons of different shapes, sizes, and colours will
; be drawn on the bottom-right quadrant.
;
; Input: None
Demo_Polys:
    poly    0, poly_rect, 5, 1101b
    poly    0, poly_star, 11, 1110b
    poly    0, poly_bubble, 12, 1011b
    poly    0, poly_mark, 2, 1011b
    point   220, 178, 1011b


    ret


; Polygon data
poly_rect:      dw 170, 110
                dw 200, 110
                dw 200, 130
                dw 170, 130
                dw 170, 110

poly_star:      dw 274, 114
                dw 283, 141
                dw 310, 142
                dw 288, 159
                dw 296, 186
                dw 274, 170
                dw 252, 186
                dw 260, 159
                dw 238, 142
                dw 265, 141
                dw 274, 114

poly_bubble:    dw 205, 152
                dw 237, 152
                dw 241, 156
                dw 241, 180
                dw 238, 183
                dw 216, 183
                dw 213, 188
                dw 208, 183
                dw 205, 183
                dw 201, 180
                dw 201, 156
                dw 205, 152

poly_mark:      dw 220, 155
                dw 220, 172