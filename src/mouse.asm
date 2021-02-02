;; https://stackoverflow.com/questions/54280828/making-a-mouse-handler-in-x86-assembly

;; PS/2 mouse installed?
%assign Mouse.hwEquipPs2  4

;; Number of bytes in mouse packet
%assign Mouse.packetBytes 3

;; Mouse resolution 8 counts/mm
%assign Mouse.resolution  2

;; Function: 
;;      Initialize and enable mouse
proc Mouse.start
begin
    call    Mouse.initialize
    jc  .ret
    call    Mouse.enable
.ret:
endproc

;; Function:
;;      Initialize the mouse if present
;; Returns: cf = 1 if error, cf = 0 success
;; Clobbers: ax
proc Mouse.initialize
begin
    push es
    push bx

    ; Get equipment list
    int 0x11
    ; Is a PS/2 mouse installed?
    test ax, Mouse.hwEquipPs2
    jz .no_mouse

    ; Initialize mouse
    mov ax, 0xC205
    mov bh, Mouse.packetBytes
    int 0x15
    jc .no_mouse

    ; Set resolution
    mov ax, 0xC203
    mov bh, Mouse.resolution
    int 0x15
    jc .no_mouse

    ; Set mouse callback function (ES:BX)
    push cs
    pop es
    mov bx, Mouse.callbackDummy
    mov ax, 0xC207
    int 0x15
    jc .no_mouse

    ; cf = 0 -> success
    clc
    jmp .finished

.no_mouse:
    ; cf = 1 -> error
    stc

.finished:
    pop bx
    pop es
endproc

;; Function:
;;      Enable the mouse
proc Mouse.enable
begin
    push es
    push bx
    push ax

    ; disable mouse before enabling
    call Mouse.disable

    ; set mouse callback function (ES:BX)
    push cs
    pop es
    mov bx, Mouse.callback
    mov ax, 0xc207
    int 0x15

    ; enable / disable mouse
    mov ax, 0xc200
    ; bh = 1 to enable
    mov bh, 1 
    int 0x15

    pop ax
    pop bx
    pop es
endproc

;; Function:
;;      Disable the mouse
proc Mouse.disable
begin
    push es
    push bx
    push ax

    ; enable / disable mouse
    mov ax, 0xc200
    ; bh = 0 to disable
    xor bx, bx 
    int 0x15

    ; clear callback function (es:bx = 0:0)
    mov es, bx
    mov ax, 0xc207
    int 0x15

    pop ax
    pop bx
    pop es
endproc

;; Function:
;;      called by the interrupt handler to process a mouse data packet
;;      All registers that are modified must be saved and restored
;;      Since we are polling manually this handler does nothing
;;
;; Parameters:
;;      * wUnused       0
;;      * wDy           movement y
;;      * wDx           movement x
;;      * byStatus      mouse status byte
farproc Mouse.callback
    %arg wUnused:word
    %arg wDy:word
    %arg wDx:word
    %arg byStatus:byte
begin
    pusha
    push ds
    push es

    ; ds = cs, cs = where our variables are stored
    push cs
    pop ds

    call Graphics.hideCursor

    mov al, [byStatus]
    ; bl = copy of status byte
    mov bl, al
    ; Shift signY (bit 5) left 3 bits
    mov cl, 3
    ; cf = signY; Sign bit of al = SignX
    shl al, cl

    ; dh = SignY value set in all bits
    ; ah = SignX value set in all bits
    sbb dh, dh 
    cbw 
    ; dl = movementY
    ; al = movementX
    mov dl, [wDy]
    mov al, [wDx]

    ; new mouse X_coord = X_Coord + movementX
    mov cx, [Mouse.wMouseX]
    ; ax = new mouse X_coord
    add ax, cx

    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [Mouse.wMouseY]
    ; dx = new mouse Y_coord
    add dx, cx

    ; Status
    ; Keep two lowest bits (left and right button info)
    and bl, 3
    ; Update the current status with the new bits
    mov [Mouse.byButtonStatus], bl

    ; Update current mouseX coord
    ; ax = max(0, min(ax, 319))
    mov     bx, 319
    cmp     ax, bx
    cmovg   ax, bx  ; use conditional mov
    mov     bx, 0
    cmp     ax, bx
    cmovl   ax, bx
    mov [Mouse.wMouseX], ax

    ; Update current mouseY coord
    ; dx = max(0, min(ax, 199))
    mov     bx, 199
    cmp     dx, bx
    cmovg   dx, bx ; use conditional mov
    mov     bx, 0
    cmp     dx, bx
    cmovl   dx, bx
    mov [Mouse.wMouseY], dx

    call Graphics.drawCursor

.ret:
    pop es
    pop ds
    popa
endproc

farproc Mouse.callbackDummy
begin
    ; nop
endproc

;; Current mouse X coordinate
Mouse.wMouseX: dw 0

;; Current mouse Y coordinate
Mouse.wMouseY: dw 0

;; Current button status:
;; 1: left pushed
;; 2: right pushed
;; 3: both pushed
Mouse.byButtonStatus: db 0
