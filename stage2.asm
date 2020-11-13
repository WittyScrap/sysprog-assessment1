; Real-Mode Part of the Boot Loader
;
; When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
; a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
; eventually switch the processor into 32-bit mode.

; ctyme.com/intr/int.htm

BITS 16

; Tell the assembler that we will be loaded at 9000h (That's where stage 1 jumps to to begin stage 2).
ORG 9000h

start:
    jmp     Stage2                      ; Startup

%include "a20.asm"
%include "io.asm"
%include "string.asm"
%include "video.asm"

Stage2:
    ; Load the next 5 sectors into memory
    mov		ah, 2						; BIOS read sector function
	mov		al, 5						; Read 5 sectors (enough to fit a ~2kb picture)
	mov		bx, Image					; Load into address ES:BX (0000:Image)
	mov		ch, 0						; Use cylinder 0
	mov		dh, 0						; Use head 0			
	mov		cl, 9						; Start reading at sector 9 (one after the 7 loaded sectors, where the image resides. We are currently in sector 2)
	int		13h
	cmp		al, 5						; int 13h (ah:2) returns the number of sectors read in al. If this is not 5, fail.
	jne		End_Loop

    mov     si, msg_stage2              ; Print stage 2 message
    call    Console_WriteLine

    call    Enable_A20                  ; Try enabling A20 line, result will be in range 0 (fail) to 4 (1-4 are success values),
    mov     si, dx                      ; we will need to multiply return value by 2 to get an address offset
    shl     si, 1                       
    mov     si, [msg_list + si]
    
    call    Console_WriteLine           ; Print relevant success/fail message

    test    dx, dx                      ; Check for successful activation
    jz      A20_Fail                    ; Halt if failed

    call    Console_Write_CRLF

    ; Switch video mode to VGA
    xor     ah, ah
    mov     al, 13h
    int     10h

    mov     ax, 15

    call    Demo_Crosshair
    call    Demo_Lines
    call    Demo_Circles
    call    Demo_Rects
    call    Demo_Polys

    ; Now draw the loaded image
    image   Image, 144, 84

End_Loop:
    jmp     End_Loop
 
A20_Fail:
    hlt                                 ; Could not enable A20 line, halt here

%include "a20msg.asm"

; Pad out the boot loader stage 2 so that it will be exactly 7 sectors
            times 512 * 7 - ($ - $$) db 0

; Image is stored at the end of the 7 sectors, in an additional 4 sectors.
; These are loaded in memory during stage 2.
Image: ; Now the image will be loaded here by dd