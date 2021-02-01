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

mandelbrot:         call    initGraphics

                    push    rgbyPalette
                    call    setPalette

                    call    mouseStart
.loop:              call    drawMandelbrot
.waitClick:
.waitMouseDown:     hlt
                    mov     al, [byButtonStatus]
                    cmp     al, 0
                    jz      .waitMouseDown

.waitMouseUp:       hlt
                    mov     bl, [byButtonStatus]
                    cmp     bl, 0
                    jnz     .waitMouseUp

                    cmp     al, 1                   ; left click
                    jne    .l1

                    push    dword [qwZoom + 4]
                    push    dword [qwZoom]
                    push    word  [wMouseY]
                    push    word  [wMouseX]
                    call    handleZoom
                    jmp     .loop

.l1:                cmp     al, 2                   ; right click
                    jne    .waitClick

                    push    dword [qwUnzoom + 4]
                    push    dword [qwUnzoom]
                    push    word  [wMouseY]
                    push    word  [wMouseX]
                    call    handleZoom
                    jmp     .loop


;; Function: handleZoom
;;           change the world x, y, width and height values based on a mouse click at x,y and zoom factor
;; Inputs:
%define var_wX         bp + 4  
%define var_wY         bp + 6
%define var_qwZoom     bp + 8
;; Returns:  None
;; Locals:   None

handleZoom:         push    sp
                    mov     bp, sp

                    finit

                    ; worldX =  worldX +  (worldWidth * mouse_x / width) - (worldWidth / zoom / 2)
                    fld     qword [qwWorldX]
                    fld     qword [qwScreenWidth]
                    fild    word [var_wX]
                    fld     qword [qwWorldWidth]
                    fmul    st1
                    fdiv    st2
                    fadd    st3
                    fld     qword [var_qwZoom]
                    fld     qword [qwConst2]
                    fmulp   st1
                    fld     qword [qwWorldWidth]
                    fdiv    st1
                    fsubr   st2
                    fstp    qword [qwWorldX]
                    fstp    st0
                    fstp    st0
                    fstp    st0
                    fstp    st0
                    fstp    st0

                    ; ; ; worldWidth = worldWidth / zoom
                    fld     qword [var_qwZoom]
                    fld     qword [qwWorldWidth]
                    fdiv    st1
                    fstp    qword [qwWorldWidth]
                    fstp    st0

                    ; ; worldY =  worldY +  (worldHeight * mouse_y / height) - (worldHeight / zoom / 2)
                    fld     qword [qwWorldY]
                    fld     qword [qwScreenHeight]
                    fild    word [var_wY]
                    fld     qword [qwWorldHeight]
                    fmul    st1
                    fdiv    st2
                    fadd    st3
                    fld     qword [var_qwZoom]
                    fld     qword [qwConst2]
                    fmulp   st1
                    fld     qword [qwWorldHeight]
                    fdiv    st1
                    fsubr   st2
                    fstp    qword [qwWorldY]
                    fstp    st0
                    fstp    st0
                    fstp    st0
                    fstp    st0
                    fstp    st0

                    ; worldHeight = worldHeight / 10
                    fld     qword [var_qwZoom]
                    fld     qword [qwWorldHeight]
                    fdiv    st1
                    fstp    qword [qwWorldHeight]
                    fstp    st0

                    pop     sp
                    retn    8


;; Function: drawMandelbrot
;;
;; Inputs:   None
;; Returns:  None
;; Locals:
%define var_wX        bp - 2
%define var_wY        bp - 4
%define var_wI        bp - 6
%define var_qwC1      bp - 14
%define var_qwC2      bp - 22
%define var_qwZ1      bp - 30
%define var_qwZ2      bp - 38
%define var_qwTmp     bp - 46
%define var_qwTmp2    bp - 54

drawMandelbrot:     push    bp
                    mov     bp, sp
                    sub     sp, 54
                    finit

                    mov     [var_wX], word 0
                    mov     [var_wY], word 0
                    xor     ax, ax
                    mov     ds, ax

.forY:              ; x = 0
                    xor     ax, ax
                    mov     [var_wX], ax
                    ; c1 = 0
                    fldz
                    fstp    qword [var_qwC1]

.forX:              ; z1 = z2 = 0
                    fldz
                    fst     qword [var_qwZ1]
                    fstp    qword [var_qwZ2]

                    ; c1 = worldX + worldWidth / screenWidth * x
                    fld     qword [qwWorldX]
                    fild    word [var_wX]
                    fld     qword [qwScreenWidth]
                    fld     qword [qwWorldWidth]
                    fdiv    st1
                    fmul    st2
                    fadd    st3
                    fstp    qword [var_qwC1]
                    fstp    st0
                    fstp    st0
                    fstp    st0

                    ; c2 = worldY + worldHeight / screenHeight* y
                    fld     qword [qwWorldY]
                    fild    word [var_wY]
                    fld     qword [qwScreenHeight]
                    fld     qword [qwWorldHeight]
                    fdiv    st1
                    fmul    st2
                    fadd    st3
                    fstp    qword [var_qwC2]
                    fstp    st0
                    fstp    st0
                    fstp    st0

                    xor     ax, ax
                    mov     [var_wI], ax

.forI:              ; tmp = z1 * z1 - z2 * z2 + c1
                    fld     qword [var_qwC1]
                    fld     qword [var_qwZ2]
                    fmul    st0
                    fld     qword [var_qwZ1]
                    fmul    st0
                    fsub    st1
                    fadd    st2
                    fstp    qword [var_qwTmp]
                    fstp    st0
                    fstp    st0

                    ; z2 = 2 * z1 * z2 + c2
                    fld     qword [var_qwC2]
                    fld     qword [var_qwZ2]
                    fld     qword [var_qwZ1]
                    fld     qword [qwConst2]
                    fmul    st1
                    fmul    st2
                    fadd    st3
                    fstp    qword [var_qwZ2]
                    fstp    st0
                    fstp    st0
                    fstp    st0

                    ; z1 = tmp
                    fld     qword [var_qwTmp]
                    fstp    qword [var_qwZ1]

                    ; if (z1 * z1 + z2 * z2 >= 4) break .iloopend;
                    fld     qword [var_qwZ2]
                    fmul    st0
                    fld     qword [var_qwZ1]
                    fmul    st0
                    fadd
                    fst     qword [var_qwTmp2]
                    fld     qword [qwConst4]
                    fcomi   st1
                    fstp    st0
                    fstp    st0
                    fstp    st0
                    jbe     .endForI

 .nextI:            ; i++
                    mov     ax, word [var_wI]
                    inc     ax
                    mov     [var_wI], ax

                    ; while (i < MAX_ITER)
                    cmp     ax, MAX_ITER
                    jl      .forI

.endForI:           push    word [var_wX]          ; x
                    push    word [var_wY]          ; y
                    push    ax                     ; color
                    call    setPixel

.nextX:             ; x++
                    mov     ax, [var_wX]
                    inc     ax
                    mov     [var_wX], ax

                    ; while (x < 320)
                    cmp     ax, 320
                    jl      .forX

.endForX:
.nextY:             ; y++
                    mov     ax, [var_wY]
                    inc     ax
                    mov     [var_wY], ax

                    ; while (x < 200)
                    cmp     ax, 200
                    jl      .forY
.endForY:
                    mov     sp, bp
                    pop     bp
                    ret

;;
;; DATA
;; 
MAX_ITER:           equ     254
        
qwConst1:           dq      1.0
qwConst2:           dq      2.0
qwConst4:           dq      4.0
qwLog2_10_inv:      dq      0.30102999566
        
qwScreenWidth:      dq      320.0
qwScreenHeight:     dq      200.0

qwWorldX:           dq      -2.0
qwWorldY:           dq      -1.0
qwWorldWidth:       dq      3.2
qwWorldHeight:      dq      2.0

qwZoom:             dq      2.0
qwUnzoom:           dq      0.5

rgbyPalette:        db      0xff, 0x00, 0x00,    0xff, 0x06, 0x00,    0xff, 0x0c, 0x00,    0xff, 0x12, 0x00
                    db      0xff, 0x18, 0x00,    0xff, 0x1e, 0x00,    0xff, 0x24, 0x00,    0xff, 0x2a, 0x00
                    db      0xff, 0x30, 0x00,    0xff, 0x36, 0x00,    0xff, 0x3c, 0x00,    0xff, 0x42, 0x00
                    db      0xff, 0x48, 0x00,    0xff, 0x4e, 0x00,    0xff, 0x54, 0x00,    0xff, 0x5a, 0x00
                    db      0xff, 0x60, 0x00,    0xff, 0x66, 0x00,    0xff, 0x6c, 0x00,    0xff, 0x72, 0x00
                    db      0xff, 0x78, 0x00,    0xff, 0x7e, 0x00,    0xff, 0x83, 0x00,    0xff, 0x89, 0x00
                    db      0xff, 0x8f, 0x00,    0xff, 0x95, 0x00,    0xff, 0x9b, 0x00,    0xff, 0xa1, 0x00
                    db      0xff, 0xa7, 0x00,    0xff, 0xad, 0x00,    0xff, 0xb3, 0x00,    0xff, 0xb9, 0x00
                    db      0xff, 0xbf, 0x00,    0xff, 0xc5, 0x00,    0xff, 0xcb, 0x00,    0xff, 0xd1, 0x00
                    db      0xff, 0xd7, 0x00,    0xff, 0xdd, 0x00,    0xff, 0xe3, 0x00,    0xff, 0xe9, 0x00
                    db      0xff, 0xef, 0x00,    0xff, 0xf5, 0x00,    0xff, 0xfb, 0x00,    0xfd, 0xff, 0x00
                    db      0xf7, 0xff, 0x00,    0xf1, 0xff, 0x00,    0xeb, 0xff, 0x00,    0xe5, 0xff, 0x00
                    db      0xdf, 0xff, 0x00,    0xd9, 0xff, 0x00,    0xd3, 0xff, 0x00,    0xcd, 0xff, 0x00
                    db      0xc7, 0xff, 0x00,    0xc1, 0xff, 0x00,    0xbb, 0xff, 0x00,    0xb5, 0xff, 0x00
                    db      0xaf, 0xff, 0x00,    0xa9, 0xff, 0x00,    0xa3, 0xff, 0x00,    0x9d, 0xff, 0x00
                    db      0x97, 0xff, 0x00,    0x91, 0xff, 0x00,    0x8b, 0xff, 0x00,    0x85, 0xff, 0x00
                    db      0x80, 0xff, 0x00,    0x7a, 0xff, 0x00,    0x74, 0xff, 0x00,    0x6e, 0xff, 0x00
                    db      0x68, 0xff, 0x00,    0x62, 0xff, 0x00,    0x5c, 0xff, 0x00,    0x56, 0xff, 0x00
                    db      0x50, 0xff, 0x00,    0x4a, 0xff, 0x00,    0x44, 0xff, 0x00,    0x3e, 0xff, 0x00
                    db      0x38, 0xff, 0x00,    0x32, 0xff, 0x00,    0x2c, 0xff, 0x00,    0x26, 0xff, 0x00
                    db      0x20, 0xff, 0x00,    0x1a, 0xff, 0x00,    0x14, 0xff, 0x00,    0x0e, 0xff, 0x00
                    db      0x08, 0xff, 0x00,    0x02, 0xff, 0x00,    0x00, 0xff, 0x04,    0x00, 0xff, 0x0a
                    db      0x00, 0xff, 0x10,    0x00, 0xff, 0x16,    0x00, 0xff, 0x1c,    0x00, 0xff, 0x22
                    db      0x00, 0xff, 0x28,    0x00, 0xff, 0x2e,    0x00, 0xff, 0x34,    0x00, 0xff, 0x3a
                    db      0x00, 0xff, 0x40,    0x00, 0xff, 0x46,    0x00, 0xff, 0x4c,    0x00, 0xff, 0x52
                    db      0x00, 0xff, 0x58,    0x00, 0xff, 0x5e,    0x00, 0xff, 0x64,    0x00, 0xff, 0x6a
                    db      0x00, 0xff, 0x70,    0x00, 0xff, 0x76,    0x00, 0xff, 0x7c,    0x00, 0xff, 0x81
                    db      0x00, 0xff, 0x87,    0x00, 0xff, 0x8d,    0x00, 0xff, 0x93,    0x00, 0xff, 0x99
                    db      0x00, 0xff, 0x9f,    0x00, 0xff, 0xa5,    0x00, 0xff, 0xab,    0x00, 0xff, 0xb1
                    db      0x00, 0xff, 0xb7,    0x00, 0xff, 0xbd,    0x00, 0xff, 0xc3,    0x00, 0xff, 0xc9
                    db      0x00, 0xff, 0xcf,    0x00, 0xff, 0xd5,    0x00, 0xff, 0xdb,    0x00, 0xff, 0xe1
                    db      0x00, 0xff, 0xe7,    0x00, 0xff, 0xed,    0x00, 0xff, 0xf3,    0x00, 0xff, 0xf9
                    db      0x00, 0xff, 0xff,    0x00, 0xf9, 0xff,    0x00, 0xf3, 0xff,    0x00, 0xed, 0xff
                    db      0x00, 0xe7, 0xff,    0x00, 0xe1, 0xff,    0x00, 0xdb, 0xff,    0x00, 0xd5, 0xff
                    db      0x00, 0xcf, 0xff,    0x00, 0xc9, 0xff,    0x00, 0xc3, 0xff,    0x00, 0xbd, 0xff
                    db      0x00, 0xb7, 0xff,    0x00, 0xb1, 0xff,    0x00, 0xab, 0xff,    0x00, 0xa5, 0xff
                    db      0x00, 0x9f, 0xff,    0x00, 0x99, 0xff,    0x00, 0x93, 0xff,    0x00, 0x8d, 0xff
                    db      0x00, 0x87, 0xff,    0x00, 0x81, 0xff,    0x00, 0x7c, 0xff,    0x00, 0x76, 0xff
                    db      0x00, 0x70, 0xff,    0x00, 0x6a, 0xff,    0x00, 0x64, 0xff,    0x00, 0x5e, 0xff
                    db      0x00, 0x58, 0xff,    0x00, 0x52, 0xff,    0x00, 0x4c, 0xff,    0x00, 0x46, 0xff
                    db      0x00, 0x40, 0xff,    0x00, 0x3a, 0xff,    0x00, 0x34, 0xff,    0x00, 0x2e, 0xff
                    db      0x00, 0x28, 0xff,    0x00, 0x22, 0xff,    0x00, 0x1c, 0xff,    0x00, 0x16, 0xff
                    db      0x00, 0x10, 0xff,    0x00, 0x0a, 0xff,    0x00, 0x04, 0xff,    0x02, 0x00, 0xff
                    db      0x08, 0x00, 0xff,    0x0e, 0x00, 0xff,    0x14, 0x00, 0xff,    0x1a, 0x00, 0xff
                    db      0x20, 0x00, 0xff,    0x26, 0x00, 0xff,    0x2c, 0x00, 0xff,    0x32, 0x00, 0xff
                    db      0x38, 0x00, 0xff,    0x3e, 0x00, 0xff,    0x44, 0x00, 0xff,    0x4a, 0x00, 0xff
                    db      0x50, 0x00, 0xff,    0x56, 0x00, 0xff,    0x5c, 0x00, 0xff,    0x62, 0x00, 0xff
                    db      0x68, 0x00, 0xff,    0x6e, 0x00, 0xff,    0x74, 0x00, 0xff,    0x7a, 0x00, 0xff
                    db      0x80, 0x00, 0xff,    0x85, 0x00, 0xff,    0x8b, 0x00, 0xff,    0x91, 0x00, 0xff
                    db      0x97, 0x00, 0xff,    0x9d, 0x00, 0xff,    0xa3, 0x00, 0xff,    0xa9, 0x00, 0xff
                    db      0xaf, 0x00, 0xff,    0xb5, 0x00, 0xff,    0xbb, 0x00, 0xff,    0xc1, 0x00, 0xff
                    db      0xc7, 0x00, 0xff,    0xcd, 0x00, 0xff,    0xd3, 0x00, 0xff,    0xd9, 0x00, 0xff
                    db      0xdf, 0x00, 0xff,    0xe5, 0x00, 0xff,    0xeb, 0x00, 0xff,    0xf1, 0x00, 0xff
                    db      0xf7, 0x00, 0xff,    0xfd, 0x00, 0xff,    0xff, 0x00, 0xfb,    0xff, 0x00, 0xf5
                    db      0xff, 0x00, 0xef,    0xff, 0x00, 0xe9,    0xff, 0x00, 0xe3,    0xff, 0x00, 0xdd
                    db      0xff, 0x00, 0xd7,    0xff, 0x00, 0xd1,    0xff, 0x00, 0xcb,    0xff, 0x00, 0xc5
                    db      0xff, 0x00, 0xbf,    0xff, 0x00, 0xb9,    0xff, 0x00, 0xb3,    0xff, 0x00, 0xad
                    db      0xff, 0x00, 0xa7,    0xff, 0x00, 0xa1,    0xff, 0x00, 0x9b,    0xff, 0x00, 0x95
                    db      0xff, 0x00, 0x8f,    0xff, 0x00, 0x89,    0xff, 0x00, 0x83,    0xff, 0x00, 0x7e
                    db      0xff, 0x00, 0x78,    0xff, 0x00, 0x72,    0xff, 0x00, 0x6c,    0xff, 0x00, 0x66
                    db      0xff, 0x00, 0x60,    0xff, 0x00, 0x5a,    0xff, 0x00, 0x54,    0xff, 0x00, 0x4e
                    db      0xff, 0x00, 0x48,    0xff, 0x00, 0x42,    0xff, 0x00, 0x3c,    0xff, 0x00, 0x36
                    db      0xff, 0x00, 0x30,    0xff, 0x00, 0x2a,    0xff, 0x00, 0x24,    0xff, 0x00, 0x1e
                    db      0xff, 0x00, 0x18,    0xff, 0x00, 0x12,    0x00, 0x00, 0x00,    0xff, 0xff, 0xff
