; http://www.6502.org/tutorials/6502opcodes.html
; https://sites.google.com/site/6502asembly/6502-instruction-set
    !src <6502/std.a>
    
    !to "y.prg",cbm
    *= $1000
    !byte float(3.14)
    !byte $80
main:
    jsr initGraphics
; draw something
    ldx #0
    lda #112
.loop:
    sta $2800, X
    inx
    bne .loop

    rts 



initGraphics:
    ; Toggle standard Bitmap Mode 
    lda $d018 ; 53272
    ora #8
    sta $d018

    lda $d011 ; 53265
    ora #32
    sta $d011

    ; Set colors
    ldx #0
    lda #14
 setColor:
    ; $0400-$07ff screen ram
    sta $400, X
    sta $500, X
    sta $600, X
    sta $700, X  
    inx
    bne setColor

    ; Clear screen
    ldx #0
    lda #0 
clearScreen:
    ;$2000 - $3fff: Bitmap RAM
    sta $2000, X
    sta $2100, X
    sta $2200, X
    sta $2300, X
    sta $2400, X
    sta $2500, X
    sta $2600, X
    sta $2700, X
    sta $2800, X
    sta $2900, X
    sta $2a00, X
    sta $2b00, X
    sta $2c00, X
    sta $2d00, X
    sta $2e00, X
    sta $2f00, X
    sta $3000, X
    sta $3100, X
    sta $3200, X
    sta $3300, X
    sta $3400, X
    sta $3500, X
    sta $3600, X
    sta $3700, X
    sta $3800, X
    sta $3900, X
    sta $3a00, X
    sta $3b00, X
    sta $3c00, X
    sta $3d00, X
    sta $3e00, X
    sta $3f00, X
    inx
    bne clearScreen
    
    rts

