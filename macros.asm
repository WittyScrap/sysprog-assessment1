%macro abs 2
    mov     %2, %1
    neg     %1
    cmovl   %1, %2
%endmacro

%macro sign 2
    sar     %1, %2 - 1
    or      %1, 1
%endmacro

%macro clear 2
    add     sp, %1 * (%2 / 8)
%endmacro

%macro line 5
    push    %4
    push    %3
    push    %2
    push    %1
    push    %5
    call    Plot_Line
    clear   5, 16
%endmacro

%macro circle 4
    push    %4
    push    %3
    push    %1
    push    %2
    call    Plot_Circle
    clear   4, 16
%endmacro

%macro rect 5
    push    %4
    push    %3
    push    %2
    push    %1
    push    %5
    call    Plot_Rect
    clear   5, 16
%endmacro