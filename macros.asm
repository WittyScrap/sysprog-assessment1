; Calculates the absolute value of a number.
; Input:
;       r/m8 - r/m32:   Value to get an absolute value for
;       r8 - r32:       Backup value, original value will be stored here
%macro abs 2
    mov     %2, %1          ; Save value
    neg     %1              ; Negate it
    cmovl   %1, %2          ; If SF is now set, it means the original value was positive; move it back.
%endmacro


; Calculates the sign of a number.
; Input:
;       r/m8 - r/m32:   Value to retrieve the sign for
;       imm8 - imm32:   Size of the operation
%macro sign 2
    sar     %1, %2 - 1
    or      %1, 1
%endmacro


; Draws a single point
; Input:
;       r/m/imm16:       X
;       r/m/imm16:       Y
;       r/m/imm8:        Color
%macro point 3
    mov     cx, %1
    mov     dx, %2
    mov     al, %3
    call    Plot_Point
%endmacro


; Draws a line from two points
; Input:
;       r/imm16:        X0
;       r/imm16:        Y0
;       r/imm16:        X1
;       r/imm16:        Y1
;       r/m16:          Color
%macro line 5
    push    %4
    push    %3
    push    %2
    push    %1
    push    %5
    call    Plot_Line
%endmacro


; Draws a filled circle on a point with a given
; radius.
; Input:
;       r/imm16:        X
;       r/imm16:        Y
;       r/imm16:        Radius
;       r/imm16:        Color
%macro circle 4
    push    %4
    push    %3
    push    %1
    push    %2
    call    Plot_Circle
%endmacro


; Draws a filled rectangle with a position and size
; Input:
;       r/imm16:        X
;       r/imm16:        Y
;       r/imm16:        SX
;       r/imm16:        SY
;       r/imm16:        Color
%macro rect 5
    push    %4
    push    %3
    push    %2
    push    %1
    push    %5
    call    Plot_Rect
%endmacro


; Draws a polygon consisting of a series of interconnected
; lines.
; Input:
;       r/m/imm16:      Segment in which the polygon data is stored
;       r/m/imm16:      Pointer to polygon data
;       r/m/imm16:      Number of vertices in polygon
;       r/m/imm16:      Color          
%macro poly 4
    mov     bx, %1
    mov     ds, bx
    mov     si, %2
    mov     ax, %3
    mov     dx, %4
    call    Plot_Poly
%endmacro


; Draws a picture at a given location. DS must be set to the
; sector in which the image is stored.
;
; Input:
;       r/m16:          Pointer to where the picture is stored
;       r/imm16:        X location of where to draw the picture
;       r/imm16:        Y location of where to draw the picture
%macro image 3
    mov     si, %1
    mov     ax, %2
    mov     bx, %3
    call    Draw_Image 
%endmacro