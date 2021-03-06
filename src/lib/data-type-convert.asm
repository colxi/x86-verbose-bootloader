;----------------------------------------------------------------------------
;
;  Name           : data-type-convert.asm
;
;  Description    : 16BIT FASM assembly minimal library focused into provide
;                   the essential resources, to convert byte values, to diferent
;                   and equivalent ASCII representations, and viceversa.
;
;                   Contents:
;                   itoa | uitoa | hextoa | bintoa || atoi
;
;  Version        : 1.1
;  Created        : 24/03/2017
;  Author         : colxi
;
;---------------------------------------------------------------------------


use16


;;**************************************************
 ;
 ;   itoa()  -  Returns the ASCII Decimal representation of
 ;              SIGNED values stored in AX (16 bits).
 ;              Note: Will perform a call to uitoa
 ;   + input :
 ;       AX = Signed Integer to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;   + Destroys :
 ;       (none)
 ;
 ;**************************************************
itoa:
    push    si

    test    ax,     ax              ; check if is negative
    js      .negative
        call    uitoa               ; not negative! call uitoa
        RET
    .negative:
        neg     ax                  ; convert to positive
        call    uitoa               ; call uitoa to ASCII conversion
        dec     si                  ; decrement si pointer by 1
                                    ; -SI was set in the previous uitoa() call-
        mov     [si],   byte "-"    ; insert negative symbol before number
        mov     ax,     si          ; update updated SI value into AX

        pop     si
        RET



;;**************************************************
 ;
 ;   uitoa()  - Returns the ASCII Decimal representation of
 ;              UNSIGNED values stored in AX (16 bits).
 ;              Note: Algorithm moves in decending order,
 ;              from las digit, to first digit.
 ;   + input :
 ;       AX = Unsigned integer to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;   + Destroys :
 ;       (none)
 ;
 ;**************************************************
uitoa:
    push    bx
    push    dx
    push    si

    lea     si,     [.buffer+6]     ; set pointer to last byte in buffer
    mov     bx,     10              ; set divider
    .nextDigit:
        xor     dx,     dx          ; clear dx before dividing dx:ax by bx
        div     bx                  ; divide ax/10
        add     dx,     48          ; add 48 to remainder to get ASCII tabl char
        dec     si                  ; move buffr pointer backwadrs
        mov     [si],   dl          ; set char in buffer
        cmp     ax,     0
        jz      .done               ; end when ax reach 0
        jmp     .nextDigit          ; else... get next digit
    .done:
        mov     ax,     si          ; store buffer pointer in ax

        pop     si
        pop     dx
        pop     bx
        RET
    .buffer: times 6 db 0,0         ; 16bit integer max length=5 + null
                                    ; extra byte is added to fit thr negative
                                    ; symbol (-) when processing calls from
                                    ; ITOA proc and handñing negative numbers


;;**************************************************
 ;
 ;   hextoa() - Returns the ASCII Hexadecimal representation
 ;              of the byte stored in AL.
 ;   + input :
 ;       AL = Byte to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;   + Destroys :
 ;      (none)
 ;
;**************************************************
hextoa:
    push    bx
    push    cx
    push    dx
    push    si

    mov     si,     .hexMap         ; Pointer to hex-character table
    xor     bh,     bh              ; clear BH register

    mov     bl,     al              ; copy input value
    shr     bl,     4               ; shiftR to get high nibble (first 4 bits)
    mov     ch,     [si+bx]         ; Read hex-character from the table

    mov     bl,     al              ; copy input value
    and     bl,     00001111b       ; Mask byte to get low nibble (last 4 bits)
    mov     cl,     [si+bx]         ; Read hex-character from the table

    mov     [.buffer],   cx         ; save result to char buffer
    mov     ax,     .buffer         ; store in AX address to buffer

    pop     si
    pop     dx
    pop     cx
    pop     bx
    RET
    .buffer:    db      0x00, 0x00,  0x00       ; one for each character + null
    .hexMap:    db      '0123456789ABCDEF'      ; ASCII mapping



;;**************************************************
 ;
 ;   hextoa() - Returns the ASCII Binary representation
 ;              of the byte stored in AL.
 ;   + input :
 ;       AL = Byte to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;   + Destroys :
 ;       (none)
 ;
;**************************************************
bintoa:
    push    bx
    push    cx
    push    si

    mov     cl,     7               ; initialize counter
    lea     si,     [.buffer]       ; set pointer to buffer
    .nextBit:
        mov     bl,     al          ; clone BYTE value to operate on it
        mov     bh,     00000001b   ; init mask
        shl     bh,     cl          ; shifL MASK c times to match current bit
        and     bl,     bh          ; aply MASK on BYTE to reset unwanted bits
        shr     bl,     cl          ; shiftR BYTE c times to get absolute 0 or 1
        or      bl,     00110000b   ; Point the rsulting char in Ascii table
        mov     [si],   bl          ; set char in buffer
        inc     si                  ; increment buffer pointer position
        sub     cl,     1           ; decrease bit current counter by 1
        cmp     cl,     0           ; Compare Counter with 0
        jge     .nextBit            ; If counter >= 0, jump to nextBit

    mov     ax,     .buffer         ; store buffer pointer in ax

    pop     si
    pop     cx
    pop     bx
    RET
    .buffer:    times   8 db 0,0    ; 8 bytes, one for each bit  + null



;;**************************************************
 ;
 ;   atoi() - Returns the DECIMAL representation
 ;            of the UNSIGNED numeric ASCII string.
 ;   + input :
 ;       AX = Pointer to UNSIGNED numeric string
 ;   + output :
 ;       AX = Decimal value
 ;   + Destroys :
 ;      (none)
 ;
;**************************************************
atoi:
    pushf
    push    si
    push    bx
    push    cx

    mov     si,     ax          ; set string pointer in SI
    xor     bx,     bx          ; clear BX
    cld                         ; CLear Direction flag. Direction:ASC

    .nextDigit:
        lodsb                   ; Load into AL the SI byte
                                ; ...and increment SI
        cmp     al,     0x00    ; check if its string end (null char)
        je      .done           ; it is! done!

        cmp     al,     '0'     ; if char is lower than "0" is not numerical...
        jb      .err_noascii    ; handle error
        cmp     al,     '9'     ; if char is higher than "9" is not numerical...
        ja      .err_noascii    ; handle error

        sub     al,     30h     ; ascii '0'=30h, ascii '1'=31h...etc.
        mov     ah,     0x00    ; clear the AH register
        push    ax
        mov     ax,     bx      ; BX will have final value
        mov     cx,     10      ; prepare multiplication
        mul     cx              ; AX=AX*10
        mov     bx,     ax
        pop     ax
        add     bx,     ax      ; BX = BX + AX
        jmp     .nextDigit
    .err_noascii:
        mov     bx,     0x0000  ; NULL the result value
    .done:
        mov     ax,     bx      ; put final result in AX

        pop     cx
        pop     bx
        pop     si
        popf
        RET
