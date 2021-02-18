;;                                 ▄█▌
;;                                ╫████
;;                              ┌ ,███▌
;;                        ██▄▄█████████████▄▄ ▄▄
;;                       ┌▄████████████████████▀
;;                      ████████████████████████
;;                    ,██████████████████████████▀
;;         ██████▄▄   ███████████████████████████W
;;     . ███████████ ╫███████████████████████████¬
;;    ▄▄▄████████████╫█████████████████████████▀
;;    ▀▀▀███████████████████████████████████████
;;       ╠██████████ ╟███████████████████████████
;;         █▀████▀▀   ███████████████████████████M
;;                    `██████████████████████████▄
;;                      ████████████████████████
;;                       ╙▀████████████████████▄
;;                        ██▀▀█████████████▀▀ ▀▀
;;                              └ `███▌
;;                                ╫████
;;                                 ╙█▌

%assign Mandelbrot.maxIterations 254

Mandelbrot.start:
    call Graphics.init

    push Mandelbrot.rgbyPalette
    call Graphics.setPalette
    add sp, 2

    call Mouse.start

.mainLoop:
    call Mandelbrot.draw

.waitMouseDown:
    hlt
    mov al, [Mouse.byButtonStatus]
    test al, al
    je .waitMouseDown

.waitMouseUp:
    hlt
    mov bl, [Mouse.byButtonStatus]
    test bl, bl
    jne .waitMouseUp

    ; left click?
    cmp al, 1
    jne .l1

    push dword [Mandelbrot.qwZoom + 4]
    push dword [Mandelbrot.qwZoom]
    push word  [Mouse.wMouseY]
    push word  [Mouse.wMouseX]
    call Mandelbrot.handleZoom
    add sp, 12
    jmp .mainLoop

.l1:
    ; right click?
    cmp al, 2
    jne .waitMouseDown

    push dword [Mandelbrot.qwUnzoom + 4]
    push dword [Mandelbrot.qwUnzoom]
    push word [Mouse.wMouseY]
    push word [Mouse.wMouseX]
    call Mandelbrot.handleZoom
    add sp, 12
    jmp .mainLoop

;; Function:
;;      Change the world x, y, width and height values based on a
;;      mouse click at x, y and zoom factor
proc Mandelbrot.handleZoom
    %arg wX:word
    %arg wY:word
    %arg qwZoom:word
begin
    finit

    ; worldX =  worldX + (worldWidth * mouse_x / width) - (worldWidth / zoom / 2)
    fld qword [Mandelbrot.qwWorldX]
    fld qword [Mandelbrot.qwScreenWidth]
    fild word [wX]
    fld qword [Mandelbrot.qwWorldWidth]
    fmul st1
    fdiv st2
    fadd st3
    fld qword [qwZoom]
    fld qword [Mandelbrot.qwConst2]
    fmulp st1
    fld qword [Mandelbrot.qwWorldWidth]
    fdiv st1
    fsubr st2
    fstp qword [Mandelbrot.qwWorldX]
    fstp st0
    fstp st0
    fstp st0
    fstp st0
    fstp st0

    ; worldWidth = worldWidth / zoom
    fld qword [qwZoom]
    fld qword [Mandelbrot.qwWorldWidth]
    fdiv st1
    fstp qword [Mandelbrot.qwWorldWidth]
    fstp st0

    ; worldY =  worldY +  (worldHeight * mouse_y / height) - (worldHeight / zoom / 2)
    fld qword [Mandelbrot.qwWorldY]
    fld qword [Mandelbrot.qwScreenHeight]
    fild word [wY]
    fld qword [Mandelbrot.qwWorldHeight]
    fmul st1
    fdiv st2
    fadd st3
    fld qword [qwZoom]
    fld qword [Mandelbrot.qwConst2]
    fmulp st1
    fld qword [Mandelbrot.qwWorldHeight]
    fdiv st1
    fsubr st2
    fstp qword [Mandelbrot.qwWorldY]
    fstp st0
    fstp st0
    fstp st0
    fstp st0
    fstp st0

    ; worldHeight = worldHeight / zoom
    fld qword [qwZoom]
    fld qword [Mandelbrot.qwWorldHeight]
    fdiv st1
    fstp qword [Mandelbrot.qwWorldHeight]
    fstp st0

endproc

;; Function: drawMandelbrot
proc Mandelbrot.draw
    %local wX:word
    %local wY:word
    %local wI:word
    %local qwC1:qword           ; re(c)
    %local qwC2:qword           ; im(c)
    %local qwZ1:qword           ; re(z)
    %local qwZ2:qword           ; im(z)
    %local qwZ1Sq:qword         ; re(z) ^ 2 these are maintained to spare some multiplications
    %local qwZ2Sq:qword         ; im(z) ^ 2
    %local qwTmp:qword
begin
    finit

    mov [wX], word 0
    mov [wY], word 0
    xor ax, ax
    mov ds, ax

.forY:
    ; x = 0
    xor ax, ax
    mov [wX], ax
    ; c1 = 0
    fldz
    fstp qword [qwC1]

.forX:
    ; z1 = z2 = z1^2 = z2^2 = 0
    fldz
    fst qword [qwZ1]
    fst qword [qwZ1Sq]
    fst qword [qwZ2]
    fstp qword [qwZ2Sq]

    ; c1 = worldX + worldWidth / screenWidth * x
    fld qword [Mandelbrot.qwWorldX]
    fild word [wX]
    fld qword [Mandelbrot.qwScreenWidth]
    fld qword [Mandelbrot.qwWorldWidth]
    fdiv st1
    fmul st2
    fadd st3
    fstp qword [qwC1]
    fstp st0
    fstp st0
    fstp st0

    ; c2 = worldY + worldHeight / screenHeight* y
    fld qword [Mandelbrot.qwWorldY]
    fild word [wY]
    fld qword [Mandelbrot.qwScreenHeight]
    fld qword [Mandelbrot.qwWorldHeight]
    fdiv st1
    fmul st2
    fadd st3
    fstp qword [qwC2]
    fstp st0
    fstp st0
    fstp st0

    xor ax, ax
    mov [wI], ax

.forI:
    ; tmp = z1^2 - z2^2 + c1 
    fld qword [qwZ2Sq]
    fld qword [qwZ1Sq]
    fsub st1
    fld qword [qwC1]
    fadd st1
    fstp qword [qwTmp]
    fstp st0
    fstp st0

    ; z2 = 2 * z1 * z2 + c2
    fld qword [qwC2]
    fld qword [qwZ2]
    fld qword [qwZ1]
    fld qword [Mandelbrot.qwConst2]
    fmul st1
    fmul st2
    fadd st3
    fst qword [qwZ2]
    fmul st0
    ; don't forget to update z2^2
    fstp qword [qwZ2Sq]
    fstp st0
    fstp st0
    fstp st0

    ; z1 = tmp & update z1^2
    fld qword [qwTmp]
    fst qword [qwZ1]
    fmul st0
    fstp qword [qwZ1Sq]

    ; if (z1 ^ 2 + z2 ^ 2 >= 4) 
    ;   break
    fld qword [qwZ2Sq]
    fld qword [qwZ1Sq]
    fadd
    fld qword [Mandelbrot.qwConst4]
    fcomi st1
    fstp st0
    fstp st0
    fstp st0
    jbe .endForI

.nextI:
    ; i++
    mov ax, word [wI]
    inc ax
    mov [wI], ax

    ; while (i < maxIterations)
    cmp ax, Mandelbrot.maxIterations
    jl .forI

.endForI:
    push ax ; color
    push word [wY]
    push word [wX]
    call Graphics.setPixel
    add sp, 6

.nextX:
    ; x++
    mov ax, [wX]
    inc ax
    mov [wX], ax

    ; while (x < 320)
    cmp ax, 320
    jl .forX
.endForX:

.nextY:
    ; y++
    mov ax, [wY]
    inc ax
    mov [wY], ax

    ; while (y < 200)
    cmp ax, 200
    jl .forY
.endForY:
endproc

Mandelbrot.qwConst1: dq 1.0
Mandelbrot.qwConst2: dq 2.0
Mandelbrot.qwConst4: dq 4.0
Mandelbrot.qwLog2_10_inv: dq 0.30102999566

Mandelbrot.qwScreenWidth: dq 320.0
Mandelbrot.qwScreenHeight: dq 200.0

Mandelbrot.qwWorldX: dq -2.0
Mandelbrot.qwWorldY: dq -1.0
Mandelbrot.qwWorldWidth: dq 3.2
Mandelbrot.qwWorldHeight: dq 2.0

Mandelbrot.qwZoom: dq 2.0
Mandelbrot.qwUnzoom: dq 0.5

Mandelbrot.rgbyPalette:
    db	0x3f, 0x00, 0x00,    0x3f, 0x01, 0x00,    0x3f, 0x03, 0x00,    0x3f, 0x04, 0x00
    db	0x3f, 0x06, 0x00,    0x3f, 0x07, 0x00,    0x3f, 0x09, 0x00,    0x3f, 0x0a, 0x00
    db	0x3f, 0x0c, 0x00,    0x3f, 0x0d, 0x00,    0x3f, 0x0f, 0x00,    0x3f, 0x10, 0x00
    db	0x3f, 0x12, 0x00,    0x3f, 0x13, 0x00,    0x3f, 0x15, 0x00,    0x3f, 0x16, 0x00
    db	0x3f, 0x18, 0x00,    0x3f, 0x19, 0x00,    0x3f, 0x1b, 0x00,    0x3f, 0x1c, 0x00
    db	0x3f, 0x1e, 0x00,    0x3f, 0x1f, 0x00,    0x3f, 0x20, 0x00,    0x3f, 0x22, 0x00
    db	0x3f, 0x23, 0x00,    0x3f, 0x25, 0x00,    0x3f, 0x26, 0x00,    0x3f, 0x28, 0x00
    db	0x3f, 0x29, 0x00,    0x3f, 0x2b, 0x00,    0x3f, 0x2c, 0x00,    0x3f, 0x2e, 0x00
    db	0x3f, 0x2f, 0x00,    0x3f, 0x31, 0x00,    0x3f, 0x32, 0x00,    0x3f, 0x34, 0x00
    db	0x3f, 0x35, 0x00,    0x3f, 0x37, 0x00,    0x3f, 0x38, 0x00,    0x3f, 0x3a, 0x00
    db	0x3f, 0x3b, 0x00,    0x3f, 0x3d, 0x00,    0x3f, 0x3e, 0x00,    0x3f, 0x3f, 0x00
    db	0x3d, 0x3f, 0x00,    0x3c, 0x3f, 0x00,    0x3a, 0x3f, 0x00,    0x39, 0x3f, 0x00
    db	0x37, 0x3f, 0x00,    0x36, 0x3f, 0x00,    0x34, 0x3f, 0x00,    0x33, 0x3f, 0x00
    db	0x31, 0x3f, 0x00,    0x30, 0x3f, 0x00,    0x2e, 0x3f, 0x00,    0x2d, 0x3f, 0x00
    db	0x2b, 0x3f, 0x00,    0x2a, 0x3f, 0x00,    0x28, 0x3f, 0x00,    0x27, 0x3f, 0x00
    db	0x25, 0x3f, 0x00,    0x24, 0x3f, 0x00,    0x22, 0x3f, 0x00,    0x21, 0x3f, 0x00
    db	0x20, 0x3f, 0x00,    0x1e, 0x3f, 0x00,    0x1d, 0x3f, 0x00,    0x1b, 0x3f, 0x00
    db	0x1a, 0x3f, 0x00,    0x18, 0x3f, 0x00,    0x17, 0x3f, 0x00,    0x15, 0x3f, 0x00
    db	0x14, 0x3f, 0x00,    0x12, 0x3f, 0x00,    0x11, 0x3f, 0x00,    0x0f, 0x3f, 0x00
    db	0x0e, 0x3f, 0x00,    0x0c, 0x3f, 0x00,    0x0b, 0x3f, 0x00,    0x09, 0x3f, 0x00
    db	0x08, 0x3f, 0x00,    0x06, 0x3f, 0x00,    0x05, 0x3f, 0x00,    0x03, 0x3f, 0x00
    db	0x02, 0x3f, 0x00,    0x00, 0x3f, 0x00,    0x00, 0x3f, 0x01,    0x00, 0x3f, 0x02
    db	0x00, 0x3f, 0x04,    0x00, 0x3f, 0x05,    0x00, 0x3f, 0x07,    0x00, 0x3f, 0x08
    db	0x00, 0x3f, 0x0a,    0x00, 0x3f, 0x0b,    0x00, 0x3f, 0x0d,    0x00, 0x3f, 0x0e
    db	0x00, 0x3f, 0x10,    0x00, 0x3f, 0x11,    0x00, 0x3f, 0x13,    0x00, 0x3f, 0x14
    db	0x00, 0x3f, 0x16,    0x00, 0x3f, 0x17,    0x00, 0x3f, 0x19,    0x00, 0x3f, 0x1a
    db	0x00, 0x3f, 0x1c,    0x00, 0x3f, 0x1d,    0x00, 0x3f, 0x1f,    0x00, 0x3f, 0x20
    db	0x00, 0x3f, 0x21,    0x00, 0x3f, 0x23,    0x00, 0x3f, 0x24,    0x00, 0x3f, 0x26
    db	0x00, 0x3f, 0x27,    0x00, 0x3f, 0x29,    0x00, 0x3f, 0x2a,    0x00, 0x3f, 0x2c
    db	0x00, 0x3f, 0x2d,    0x00, 0x3f, 0x2f,    0x00, 0x3f, 0x30,    0x00, 0x3f, 0x32
    db	0x00, 0x3f, 0x33,    0x00, 0x3f, 0x35,    0x00, 0x3f, 0x36,    0x00, 0x3f, 0x38
    db	0x00, 0x3f, 0x39,    0x00, 0x3f, 0x3b,    0x00, 0x3f, 0x3c,    0x00, 0x3f, 0x3e
    db	0x00, 0x3f, 0x3f,    0x00, 0x3e, 0x3f,    0x00, 0x3c, 0x3f,    0x00, 0x3b, 0x3f
    db	0x00, 0x39, 0x3f,    0x00, 0x38, 0x3f,    0x00, 0x36, 0x3f,    0x00, 0x35, 0x3f
    db	0x00, 0x33, 0x3f,    0x00, 0x32, 0x3f,    0x00, 0x30, 0x3f,    0x00, 0x2f, 0x3f
    db	0x00, 0x2d, 0x3f,    0x00, 0x2c, 0x3f,    0x00, 0x2a, 0x3f,    0x00, 0x29, 0x3f
    db	0x00, 0x27, 0x3f,    0x00, 0x26, 0x3f,    0x00, 0x24, 0x3f,    0x00, 0x23, 0x3f
    db	0x00, 0x21, 0x3f,    0x00, 0x20, 0x3f,    0x00, 0x1f, 0x3f,    0x00, 0x1d, 0x3f
    db	0x00, 0x1c, 0x3f,    0x00, 0x1a, 0x3f,    0x00, 0x19, 0x3f,    0x00, 0x17, 0x3f
    db	0x00, 0x16, 0x3f,    0x00, 0x14, 0x3f,    0x00, 0x13, 0x3f,    0x00, 0x11, 0x3f
    db	0x00, 0x10, 0x3f,    0x00, 0x0e, 0x3f,    0x00, 0x0d, 0x3f,    0x00, 0x0b, 0x3f
    db	0x00, 0x0a, 0x3f,    0x00, 0x08, 0x3f,    0x00, 0x07, 0x3f,    0x00, 0x05, 0x3f
    db	0x00, 0x04, 0x3f,    0x00, 0x02, 0x3f,    0x00, 0x01, 0x3f,    0x00, 0x00, 0x3f
    db	0x02, 0x00, 0x3f,    0x03, 0x00, 0x3f,    0x05, 0x00, 0x3f,    0x06, 0x00, 0x3f
    db	0x08, 0x00, 0x3f,    0x09, 0x00, 0x3f,    0x0b, 0x00, 0x3f,    0x0c, 0x00, 0x3f
    db	0x0e, 0x00, 0x3f,    0x0f, 0x00, 0x3f,    0x11, 0x00, 0x3f,    0x12, 0x00, 0x3f
    db	0x14, 0x00, 0x3f,    0x15, 0x00, 0x3f,    0x17, 0x00, 0x3f,    0x18, 0x00, 0x3f
    db	0x1a, 0x00, 0x3f,    0x1b, 0x00, 0x3f,    0x1d, 0x00, 0x3f,    0x1e, 0x00, 0x3f
    db	0x20, 0x00, 0x3f,    0x21, 0x00, 0x3f,    0x22, 0x00, 0x3f,    0x24, 0x00, 0x3f
    db	0x25, 0x00, 0x3f,    0x27, 0x00, 0x3f,    0x28, 0x00, 0x3f,    0x2a, 0x00, 0x3f
    db	0x2b, 0x00, 0x3f,    0x2d, 0x00, 0x3f,    0x2e, 0x00, 0x3f,    0x30, 0x00, 0x3f
    db	0x31, 0x00, 0x3f,    0x33, 0x00, 0x3f,    0x34, 0x00, 0x3f,    0x36, 0x00, 0x3f
    db	0x37, 0x00, 0x3f,    0x39, 0x00, 0x3f,    0x3a, 0x00, 0x3f,    0x3c, 0x00, 0x3f
    db	0x3d, 0x00, 0x3f,    0x3f, 0x00, 0x3f,    0x3f, 0x00, 0x3e,    0x3f, 0x00, 0x3d
    db	0x3f, 0x00, 0x3b,    0x3f, 0x00, 0x3a,    0x3f, 0x00, 0x38,    0x3f, 0x00, 0x37
    db	0x3f, 0x00, 0x35,    0x3f, 0x00, 0x34,    0x3f, 0x00, 0x32,    0x3f, 0x00, 0x31
    db	0x3f, 0x00, 0x2f,    0x3f, 0x00, 0x2e,    0x3f, 0x00, 0x2c,    0x3f, 0x00, 0x2b
    db	0x3f, 0x00, 0x29,    0x3f, 0x00, 0x28,    0x3f, 0x00, 0x26,    0x3f, 0x00, 0x25
    db	0x3f, 0x00, 0x23,    0x3f, 0x00, 0x22,    0x3f, 0x00, 0x20,    0x3f, 0x00, 0x1f
    db	0x3f, 0x00, 0x1e,    0x3f, 0x00, 0x1c,    0x3f, 0x00, 0x1b,    0x3f, 0x00, 0x19
    db	0x3f, 0x00, 0x18,    0x3f, 0x00, 0x16,    0x3f, 0x00, 0x15,    0x3f, 0x00, 0x13
    db	0x3f, 0x00, 0x12,    0x3f, 0x00, 0x10,    0x3f, 0x00, 0x0f,    0x3f, 0x00, 0x0d
    db	0x3f, 0x00, 0x0c,    0x3f, 0x00, 0x0a,    0x3f, 0x00, 0x09,    0x3f, 0x00, 0x07
    db	0x3f, 0x00, 0x06,    0x3f, 0x00, 0x04,    0x00, 0x00, 0x00,    0xff, 0xff, 0xff