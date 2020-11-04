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