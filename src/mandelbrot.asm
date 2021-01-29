 mandelbrot_module:
    mov     ax, 13h                 ; Turn on graphics mode (320x200)
    int     10h

    call    init_palette
    call    mouse_start

.loop:
    call    draw_mandelbrot

.waitClick:
    hlt

    mov     al, [curStatus]
    cmp     al, 0x9
    jne    .l1
    push    dword [zoom + 4]        ; left click
    push    dword [zoom]
    push    word  [mouseY]
    push    word  [mouseX]
    call    handle_zoom
    jmp     .loop
.l1:
    cmp     al, 0xa
    jne    .waitClick               ; right click
    push    dword [unzoom + 4]
    push    dword [unzoom]
    push    word  [mouseY]
    push    word  [mouseX]
    call    handle_zoom
    jmp     .loop


; Function: handle_zoom
;           change the world x, y, width and height values based on a mouse click at x,y and zoom factor
; Inputs:   SP+4   = x
;           SP+6   = y
;           SP+8   = zoom
; Returns:  None
; Clobbers: None

handle_zoom:
    push    sp
    mov     bp, sp

    finit

    ; world_x =  world_x +  (world_width * mouse_x / width) - (world_width / zoom / 2)
    fld     qword [world_x]
    fld     qword [width]
    fild    word [bp + 4]
    fld     qword [world_width]
    fmul    st1
    fdiv    st2
    fadd    st3
    fld     qword [bp + 8]
    fld     qword [const2]
    fmulp   st1
    fld     qword [world_width]
    fdiv    st1
    fsubr   st2
    fstp    qword [world_x]
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0

    ; ; ; world_width = world_width / zoom
    fld     qword [bp + 8]
    fld     qword [world_width]
    fdiv    st1
    fstp    qword [world_width]
    fstp    st0

    ; ; world_y =  world_y +  (world_height * mouse_y / height) - (world_height / zoom / 2)
    fld     qword [world_y]
    fld     qword [height]
    fild    word [bp + 6]
    fld     qword [world_height]
    fmul    st1
    fdiv    st2
    fadd    st3
    fld     qword [bp + 8]
    fld     qword [const2]
    fmulp   st1
    fld     qword [world_height]
    fdiv    st1
    fsubr   st2
    fstp    qword [world_y]
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0

    ; world_height = world_height / 10
    fld     qword [bp + 8]
    fld     qword [world_height]
    fdiv    st1
    fstp    qword [world_height]
    fstp    st0

    pop     sp
    retn    8


; Function: draw_mandelbrot
;
; Inputs:   None
; Returns:  None
; Clobbers: None

draw_mandelbrot:

    push    sp
    mov     bp, sp

    finit

    mov     [screen_ptr], word 0
    mov     [x], word 0
    mov     [y], word 0
    xor     ax, ax
    mov     ds, ax

.yloop:
    mov     cx, [y]
    cmp     cx, 200
    je      .yloopend

    xor     ax, ax
    mov     [x], ax

    fldz
    fstp    qword [c1]

.xloop:
    mov     cx, [x]
    cmp     cx, 320
    je .xloopend

    fldz
    fst     qword [z1]
    fstp    qword [z2]

    ; $c1 = $world_x + world_width / width * x;
    fld     qword [world_x]
    fild    word [x]
    fld     qword [width]
    fld     qword [world_width]
    fdiv    st1
    fmul    st2
    fadd    st3
    fstp    qword [c1]
    fstp    st0
    fstp    st0
    fstp    st0

    ; $c2 = $min_y + ($max_y - $min_y) / $height * $y;
    fld     qword [world_y]
    fild    word [y]
    fld     qword [height]
    fld     qword [world_height]
    fdiv    st1
    fmul    st2
    fadd    st3
    fstp    qword [c2]
    fstp    st0
    fstp    st0
    fstp    st0

    xor     ax, ax
    mov     [i], ax

.iloop:
    mov     cx, [i]
    cmp     cx, MAX_ITER
    je      .iloopend

    ; tmp = z1 * z1 - z2 * z2 + c1
    fld     qword [c1]
    fld     qword [z2]
    fmul    st0
    fld     qword [z1]
    fmul    st0
    fsub    st1
    fadd    st2
    fstp    qword [tmp]
    fstp    st0
    fstp    st0

    ; z2 = 2 * z1 * z2 + c2
    fld     qword [c2]
    fld     qword [z2]
    fld     qword [z1]
    fld     qword [const2]
    fmul    st1
    fmul    st2
    fadd    st3
    fstp    qword [z2]
    fstp    st0
    fstp    st0
    fstp    st0

    fld     qword [tmp]
    fstp    qword [z1]

    ; if (z1 * z1 + z2 * z2 >= 4) break
    fld     qword [z2]
    fmul    st0
    fld     qword [z1]
    fmul    st0
    fadd
    fst     qword [tmp2]
    fld     qword [const4]
    fcomi   st1
    fstp    st0
    fstp    st0
    fstp    st0

    jbe     .iloopend

 .nexti:
    inc     cx
    mov     [i], cx
    jmp     .iloop

.iloopend:
    mov     cx, [x]
    mov     dx, [y]

    mov     di, [screen_ptr]
    mov     ax, [i]

    cmp     ax, MAX_ITER
    jl      .j1
    mov     ax, 253              ; the last 2 items of the palette are used by the mouse
    jmp     .j2
.j1:


    ; push    dx
    ; xor     dx, dx
    ; mov     bx, 252
    ; mul     bx
    ; mov     bx, MAX_ITER
    ; div     bx
    ; pop dx

    ; http://linas.org/art-gallery/escape/escape.html
    ; n + 1 - log(log2(abs(z)))
    ; fld     qword [log2_10_inv]
    ; fld1
    ; fld     qword [tmp2]   ; holds z^2
    ; fsqrt
    ; fyl2x
    ; fyl2x
    ; fchs
    ; fld1
    ; fadd    st1
    ; frndint
    ; fistp   word [tmp2]
    ; fstp    st0
    ; fstp    st0
    ; fstp    st0
    ; add     ax, [tmp2]


.j2:
    push    cx
    push    dx
    push    ax
    call    set_pixel
    inc     di
    mov     [screen_ptr], di

.nextx:
    inc     cx
    mov     [x], cx
    jmp     .xloop

.xloopend:
.nexty:
    mov     ax, [y]
    inc     ax
    mov     [y], ax

    jmp     .yloop

.yloopend:

    pop     sp
    ret


; Function: init_palette
;           change the world x, y, width and height values based on a mouse click at x,y and zoom factor
; Inputs:   None
; Returns:  None
; Clobbers: None
init_palette:
    pusha

    ;; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
    ;; INT 10H 1010H: Set One DAC Color Register
    ;; Expects: AX    1010H
    ;;          BX    color register to set (0-255)
    ;;          DH    red value   (00H-3fH)
    ;;          CH    green value (00H-3fH)
    ;;          CL    blue value  (00H-3fH)

    mov     di, palette
    mov     [tmp], byte 0
    xor     bx, bx
.loop:
    mov     dh,  [di]
    inc     di
    mov     ch,  [di]
    inc     di
    mov     cl,  [di]
    inc     di
    mov     ax, 1010h
    int     10h

    inc     bx
    cmp     bx, 256
    jl      .loop

    popa
    ret

;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;

x            dw 0
y            dw 0
i            dw 0

c1           dq 0.0
c2           dq 0.0
z1           dq 0.0
z2           dq 0.0
tmp          dq 0.0
tmp2         dq 0.0

const1       dq 1.0
const2       dq 2.0
const4       dq 4.0
log2_10_inv  dq 0.30102999566

width        dq 320.0
height       dq 200.0

world_x      dq -2.0
world_y      dq -1.0
world_width  dq 3.2
world_height dq 2.0

zoom         dq 2.0
unzoom       dq 0.5

screen_ptr   dw 0x0000

MAX_ITER     equ 253

palette:
    db	0xff, 0x00, 0x00,    0xff, 0x06, 0x00,    0xff, 0x0c, 0x00,    0xff, 0x12, 0x00
    db	0xff, 0x18, 0x00,    0xff, 0x1e, 0x00,    0xff, 0x24, 0x00,    0xff, 0x2a, 0x00
    db	0xff, 0x30, 0x00,    0xff, 0x36, 0x00,    0xff, 0x3c, 0x00,    0xff, 0x42, 0x00
    db	0xff, 0x48, 0x00,    0xff, 0x4e, 0x00,    0xff, 0x54, 0x00,    0xff, 0x5a, 0x00
    db	0xff, 0x60, 0x00,    0xff, 0x66, 0x00,    0xff, 0x6c, 0x00,    0xff, 0x72, 0x00
    db	0xff, 0x78, 0x00,    0xff, 0x7e, 0x00,    0xff, 0x83, 0x00,    0xff, 0x89, 0x00
    db	0xff, 0x8f, 0x00,    0xff, 0x95, 0x00,    0xff, 0x9b, 0x00,    0xff, 0xa1, 0x00
    db	0xff, 0xa7, 0x00,    0xff, 0xad, 0x00,    0xff, 0xb3, 0x00,    0xff, 0xb9, 0x00
    db	0xff, 0xbf, 0x00,    0xff, 0xc5, 0x00,    0xff, 0xcb, 0x00,    0xff, 0xd1, 0x00
    db	0xff, 0xd7, 0x00,    0xff, 0xdd, 0x00,    0xff, 0xe3, 0x00,    0xff, 0xe9, 0x00
    db	0xff, 0xef, 0x00,    0xff, 0xf5, 0x00,    0xff, 0xfb, 0x00,    0xfd, 0xff, 0x00
    db	0xf7, 0xff, 0x00,    0xf1, 0xff, 0x00,    0xeb, 0xff, 0x00,    0xe5, 0xff, 0x00
    db	0xdf, 0xff, 0x00,    0xd9, 0xff, 0x00,    0xd3, 0xff, 0x00,    0xcd, 0xff, 0x00
    db	0xc7, 0xff, 0x00,    0xc1, 0xff, 0x00,    0xbb, 0xff, 0x00,    0xb5, 0xff, 0x00
    db	0xaf, 0xff, 0x00,    0xa9, 0xff, 0x00,    0xa3, 0xff, 0x00,    0x9d, 0xff, 0x00
    db	0x97, 0xff, 0x00,    0x91, 0xff, 0x00,    0x8b, 0xff, 0x00,    0x85, 0xff, 0x00
    db	0x80, 0xff, 0x00,    0x7a, 0xff, 0x00,    0x74, 0xff, 0x00,    0x6e, 0xff, 0x00
    db	0x68, 0xff, 0x00,    0x62, 0xff, 0x00,    0x5c, 0xff, 0x00,    0x56, 0xff, 0x00
    db	0x50, 0xff, 0x00,    0x4a, 0xff, 0x00,    0x44, 0xff, 0x00,    0x3e, 0xff, 0x00
    db	0x38, 0xff, 0x00,    0x32, 0xff, 0x00,    0x2c, 0xff, 0x00,    0x26, 0xff, 0x00
    db	0x20, 0xff, 0x00,    0x1a, 0xff, 0x00,    0x14, 0xff, 0x00,    0x0e, 0xff, 0x00
    db	0x08, 0xff, 0x00,    0x02, 0xff, 0x00,    0x00, 0xff, 0x04,    0x00, 0xff, 0x0a
    db	0x00, 0xff, 0x10,    0x00, 0xff, 0x16,    0x00, 0xff, 0x1c,    0x00, 0xff, 0x22
    db	0x00, 0xff, 0x28,    0x00, 0xff, 0x2e,    0x00, 0xff, 0x34,    0x00, 0xff, 0x3a
    db	0x00, 0xff, 0x40,    0x00, 0xff, 0x46,    0x00, 0xff, 0x4c,    0x00, 0xff, 0x52
    db	0x00, 0xff, 0x58,    0x00, 0xff, 0x5e,    0x00, 0xff, 0x64,    0x00, 0xff, 0x6a
    db	0x00, 0xff, 0x70,    0x00, 0xff, 0x76,    0x00, 0xff, 0x7c,    0x00, 0xff, 0x81
    db	0x00, 0xff, 0x87,    0x00, 0xff, 0x8d,    0x00, 0xff, 0x93,    0x00, 0xff, 0x99
    db	0x00, 0xff, 0x9f,    0x00, 0xff, 0xa5,    0x00, 0xff, 0xab,    0x00, 0xff, 0xb1
    db	0x00, 0xff, 0xb7,    0x00, 0xff, 0xbd,    0x00, 0xff, 0xc3,    0x00, 0xff, 0xc9
    db	0x00, 0xff, 0xcf,    0x00, 0xff, 0xd5,    0x00, 0xff, 0xdb,    0x00, 0xff, 0xe1
    db	0x00, 0xff, 0xe7,    0x00, 0xff, 0xed,    0x00, 0xff, 0xf3,    0x00, 0xff, 0xf9
    db	0x00, 0xff, 0xff,    0x00, 0xf9, 0xff,    0x00, 0xf3, 0xff,    0x00, 0xed, 0xff
    db	0x00, 0xe7, 0xff,    0x00, 0xe1, 0xff,    0x00, 0xdb, 0xff,    0x00, 0xd5, 0xff
    db	0x00, 0xcf, 0xff,    0x00, 0xc9, 0xff,    0x00, 0xc3, 0xff,    0x00, 0xbd, 0xff
    db	0x00, 0xb7, 0xff,    0x00, 0xb1, 0xff,    0x00, 0xab, 0xff,    0x00, 0xa5, 0xff
    db	0x00, 0x9f, 0xff,    0x00, 0x99, 0xff,    0x00, 0x93, 0xff,    0x00, 0x8d, 0xff
    db	0x00, 0x87, 0xff,    0x00, 0x81, 0xff,    0x00, 0x7c, 0xff,    0x00, 0x76, 0xff
    db	0x00, 0x70, 0xff,    0x00, 0x6a, 0xff,    0x00, 0x64, 0xff,    0x00, 0x5e, 0xff
    db	0x00, 0x58, 0xff,    0x00, 0x52, 0xff,    0x00, 0x4c, 0xff,    0x00, 0x46, 0xff
    db	0x00, 0x40, 0xff,    0x00, 0x3a, 0xff,    0x00, 0x34, 0xff,    0x00, 0x2e, 0xff
    db	0x00, 0x28, 0xff,    0x00, 0x22, 0xff,    0x00, 0x1c, 0xff,    0x00, 0x16, 0xff
    db	0x00, 0x10, 0xff,    0x00, 0x0a, 0xff,    0x00, 0x04, 0xff,    0x02, 0x00, 0xff
    db	0x08, 0x00, 0xff,    0x0e, 0x00, 0xff,    0x14, 0x00, 0xff,    0x1a, 0x00, 0xff
    db	0x20, 0x00, 0xff,    0x26, 0x00, 0xff,    0x2c, 0x00, 0xff,    0x32, 0x00, 0xff
    db	0x38, 0x00, 0xff,    0x3e, 0x00, 0xff,    0x44, 0x00, 0xff,    0x4a, 0x00, 0xff
    db	0x50, 0x00, 0xff,    0x56, 0x00, 0xff,    0x5c, 0x00, 0xff,    0x62, 0x00, 0xff
    db	0x68, 0x00, 0xff,    0x6e, 0x00, 0xff,    0x74, 0x00, 0xff,    0x7a, 0x00, 0xff
    db	0x80, 0x00, 0xff,    0x85, 0x00, 0xff,    0x8b, 0x00, 0xff,    0x91, 0x00, 0xff
    db	0x97, 0x00, 0xff,    0x9d, 0x00, 0xff,    0xa3, 0x00, 0xff,    0xa9, 0x00, 0xff
    db	0xaf, 0x00, 0xff,    0xb5, 0x00, 0xff,    0xbb, 0x00, 0xff,    0xc1, 0x00, 0xff
    db	0xc7, 0x00, 0xff,    0xcd, 0x00, 0xff,    0xd3, 0x00, 0xff,    0xd9, 0x00, 0xff
    db	0xdf, 0x00, 0xff,    0xe5, 0x00, 0xff,    0xeb, 0x00, 0xff,    0xf1, 0x00, 0xff
    db	0xf7, 0x00, 0xff,    0xfd, 0x00, 0xff,    0xff, 0x00, 0xfb,    0xff, 0x00, 0xf5
    db	0xff, 0x00, 0xef,    0xff, 0x00, 0xe9,    0xff, 0x00, 0xe3,    0xff, 0x00, 0xdd
    db	0xff, 0x00, 0xd7,    0xff, 0x00, 0xd1,    0xff, 0x00, 0xcb,    0xff, 0x00, 0xc5
    db	0xff, 0x00, 0xbf,    0xff, 0x00, 0xb9,    0xff, 0x00, 0xb3,    0xff, 0x00, 0xad
    db	0xff, 0x00, 0xa7,    0xff, 0x00, 0xa1,    0xff, 0x00, 0x9b,    0xff, 0x00, 0x95
    db	0xff, 0x00, 0x8f,    0xff, 0x00, 0x89,    0xff, 0x00, 0x83,    0xff, 0x00, 0x7e
    db	0xff, 0x00, 0x78,    0xff, 0x00, 0x72,    0xff, 0x00, 0x6c,    0xff, 0x00, 0x66
    db	0xff, 0x00, 0x60,    0xff, 0x00, 0x5a,    0xff, 0x00, 0x54,    0xff, 0x00, 0x4e
    db	0xff, 0x00, 0x48,    0xff, 0x00, 0x42,    0xff, 0x00, 0x3c,    0xff, 0x00, 0x36
    db	0xff, 0x00, 0x30,    0xff, 0x00, 0x2a,    0xff, 0x00, 0x24,    0xff, 0x00, 0x1e
    db	0xff, 0x00, 0x18,    0x00, 0x00, 0x00,    0x00, 0x00, 0x00,    0x00, 0x00, 0x00