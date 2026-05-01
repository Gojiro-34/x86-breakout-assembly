org 0x0100
jmp start

; ==============================================================
; ASCII ART: ATARI BREAKOUT
; ==============================================================

title1: db '   ###    #####    ###    ####     #####',0
title2: db '  #   #     #     #   #   #   #      #',0
title3: db '  #####     #     #####   ####       #',0
title4: db '  #   #     #     #   #   #   #      #',0
title5: db '  #   #     #     #   #   #   #    #####',0 

title6: db '###  ###  ####  ###  #  #  ###  #  # #####',0
title7: db '#  # #  # #    #   # # #  #   # #  #   #',0
title8: db '###  ###  ###  ##### ##   #   # #  #   #',0
title9: db '#  # #  # #    #   # # #  #   # #  #   #',0
title10: db '###  #  # #### #   # #  #  ###   ##    #',0

option1: db '1. Play Game',0
option2: db '2. Instructions',0
option3: db '3. Exit',0

instTitle: db '===== INSTRUCTIONS =====',0
instLine1: db 'Ball: NORMAL | Paddle: FAST',0
instLine2: db 'Top bricks need 2 hits',0
instLine3: db 'Control using:',0
instLine4: db '  Left Arrow - Move Left',0
instLine5: db '  Right Arrow - Move Right',0
instLine6: db 'Destroy all 48 tiles',0
instLine7: db 'You have 3 lives!',0
instLine8: db '',0
instBack: db 'Press ESC to return to menu',0

currentScreen: db 0
score: dw 0
lives: db 3
ballX: db 40
ballY: db 20
ballDX: db 1
ballDY: db -1
paddleX: db 35
paddleSize: db 10
gameOver: db 0

; 48 bricks (12 columns * 4 rows)
bricks: times 48 db 1

oldBallX: db 40
oldBallY: db 20
oldPaddleX: db 35

; NEW: Timer variables to separate paddle speed from ball speed
ballTimer: db 0
ballThreshold: db 24  ; CHANGED: 16 -> 24 (Slower for better control)

scoreText: db 'Score: ',0
livesText: db 'Lives: ',0
gameOverText: db 'GAME OVER! Final Score: ',0
winText: db 'YOU WIN! Final Score: ',0
pressEsc: db 'Press ESC to return to menu',0

; Color table for 48 bricks
brickColors: 
    ; Row 1 colors
    db 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C
    ; Row 2 colors
    db 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E
    ; Row 3 colors
    db 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
    ; Row 4 colors
    db 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09

clearScreen:
    mov ax, 0xB800
    mov es, ax
    mov di, 0
    mov cx, 2000
    mov ax, 0x0020
clearLoop:
    stosw
    loop clearLoop
    ret

printString:
    push bx
    mov bl, ah
    mov ax, 0xB800
    mov es, ax
printLoop:
    lodsb
    cmp al, 0
    je endPrint
    mov ah, bl
    stosw
    jmp printLoop
endPrint:
    pop bx
    ret

drawMainMenu:
    call clearScreen
    mov ah, 0x0C 
    mov si, title1
    mov di, 524
    call printString
    mov si, title2
    mov di, 684
    call printString
    mov si, title3
    mov di, 844
    call printString
    mov si, title4
    mov di, 1004
    call printString
    mov si, title5
    mov di, 1164
    call printString
    
    mov ah, 0x0E
    mov si, title6
    mov di, 1474
    call printString
    mov si, title7
    mov di, 1634
    call printString
    mov si, title8
    mov di, 1794
    call printString
    mov si, title9
    mov di, 1954
    call printString
    mov si, title10
    mov di, 2114
    call printString

    mov ah, 0x0F
    mov si, option1
    mov di, 2788
    call printString
    mov si, option2
    mov di, 2948
    call printString
    mov si, option3
    mov di, 3108
    call printString
    ret

drawInstructions:
    call clearScreen
    mov si, instTitle
    mov di, 868
    mov ah, 0x0E
    call printString
    mov si, instLine1
    mov di, 1348
    mov ah, 0x0F
    call printString
    mov si, instLine2
    mov di, 1508
    call printString
    mov si, instLine3
    mov di, 1668
    call printString
    mov si, instLine4
    mov di, 1828
    call printString
    mov si, instLine5
    mov di, 1988
    call printString
    mov si, instLine6
    mov di, 2148
    call printString
    mov si, instLine7
    mov di, 2308
    call printString
    mov si, instBack
    mov di, 3028
    mov ah, 0x0A
    call printString
    ret

initGame:
    mov word [score], 0
    mov byte [lives], 3
    mov byte [ballX], 40
    mov byte [ballY], 15
    mov byte [ballDX], 1
    mov byte [ballDY], -1
    mov byte [paddleX], 35
    mov byte [gameOver], 0
    mov byte [oldBallX], 40
    mov byte [oldBallY], 15
    mov byte [oldPaddleX], 35
    
    ; Initialize Ball Timer
    mov byte [ballTimer], 0
    
    mov di, bricks
    
    ; Top row (12 bricks) = 2 Hits
    mov cx, 12
    mov al, 2
initTopRow:
    mov [di], al
    inc di
    loop initTopRow
    
    ; Remaining 3 rows (36 bricks) = 1 Hit
    mov cx, 36
    mov al, 1
initRestRows:
    mov [di], al
    inc di
    loop initRestRows
    ret

drawBorder:
    mov ax, 0xB800
    mov es, ax
    mov di, 160
    mov cx, 80
    mov ax, 0x7FDB
topBorder:
    stosw
    loop topBorder
    mov di, 3840
    mov cx, 80
bottomBorder:
    stosw
    loop bottomBorder
    mov cx, 22
    mov di, 320
sideBorders:
    mov word [es:di], 0x7FDB
    mov word [es:di+158], 0x7FDB
    add di, 160
    loop sideBorders
    ret

drawBricks:
    mov ax, 0xB800
    mov es, ax
    mov si, bricks
    mov bx, brickColors 
    
    mov di, 500        ; Row 1
    mov cx, 12         ; 12 bricks
    call drawBrickRow
    mov di, 660        ; Row 2
    mov cx, 12
    call drawBrickRow
    mov di, 820        ; Row 3
    mov cx, 12
    call drawBrickRow
    mov di, 980        ; Row 4
    mov cx, 12
    call drawBrickRow
    ret

drawBrickRow:
    push cx
drawBrickLoop:
    lodsb             ; Load HP
    mov ah, [bx]      ; Get Color
    inc bx
    cmp al, 0         ; If HP 0, skip
    je skipBrick
    
    ; Draw brick: 5 characters wide
    mov al, 0xDB
    mov [es:di], ax
    mov [es:di+2], ax
    mov [es:di+4], ax
    mov [es:di+6], ax
    mov [es:di+8], ax
    
skipBrick:
    add di, 10        ; 5 chars * 2 bytes = 10 bytes
    loop drawBrickLoop
    pop cx
    ret

eraseBrick:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, bx
    mov bl, 12        ; DIVIDE BY 12 (Columns)
    div bl            ; AL=Row, AH=Col
    mov dl, al
    mov dh, ah

    xor ah, ah
    mov al, dl
    add al, 3
    xor ah, ah
    mov bl, 80
    mul bl
    add ax, 10        ; Add 10 padding
    push ax

    mov al, dh
    xor ah, ah
    mov bl, 5         ; MULTIPLY BY 5 (Brick Width)
    mul bl
    pop bx
    add ax, bx
    shl ax, 1
    mov di, ax

    mov ax, 0xB800
    mov es, ax
    mov ax, 0x0020
    mov cx, 5         ; ERASE 5 CHARS
eraseBrickLoop2:
    stosw
    loop eraseBrickLoop2

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

eraseOldPaddle:
    mov ax, 0xB800
    mov es, ax
    mov di, 3680
    xor ax, ax
    mov al, [oldPaddleX]
    shl ax, 1
    add di, ax
    
    mov ah, 0x00
    mov al, ' '
    mov cl, [paddleSize]
    xor ch, ch
eraseOldPaddleLoop:
    mov [es:di], ax
    add di, 2
    loop eraseOldPaddleLoop
    ret

drawPaddle:
    call eraseOldPaddle
    mov ax, 0xB800
    mov es, ax
    mov di, 3680
    xor ax, ax
    mov al, [paddleX]
    shl ax, 1
    add di, ax
    
    mov ah, 0x1F
    mov al, 0xDB
    mov cl, [paddleSize]
    xor ch, ch
drawPaddleLoop:
    mov [es:di], ax
    add di, 2
    loop drawPaddleLoop
    
    mov al, [paddleX]
    mov [oldPaddleX], al
    ret

eraseOldBall:
    mov ax, 0xB800
    mov es, ax
    xor ax, ax
    mov al, [oldBallY]
    mov bx, 160
    mul bx
    mov di, ax
    xor ax, ax
    mov al, [oldBallX]
    shl ax, 1
    add di, ax
    mov word [es:di], 0x0020
    ret

drawBall:
    call eraseOldBall
    mov ax, 0xB800
    mov es, ax
    xor ax, ax
    mov al, [ballY]
    mov bx, 160
    mul bx
    mov di, ax
    xor ax, ax
    mov al, [ballX]
    shl ax, 1
    add di, ax
    
    mov ah, 0x0F
    mov al, 'O'
    mov [es:di], ax
    
    mov al, [ballX]
    mov [oldBallX], al
    mov al, [ballY]
    mov [oldBallY], al
    ret

drawStatus:
    mov ax, 0xB800
    mov es, ax
    mov di, 164
    mov si, scoreText
    mov ah, 0x0F
    call printString
    mov ax, [score]
    call printNumber
    mov di, 280
    mov si, livesText
    mov ah, 0x0F
    call printString
    xor ax, ax
    mov al, [lives]
    call printNumber
    ret

printNumber:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
convertLoop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz convertLoop
    mov ax, 0xB800
    mov es, ax
printDigits:
    pop ax
    add al, '0'
    mov ah, 0x0F
    stosw
    loop printDigits
    pop dx
    pop cx
    pop bx
    pop ax
    ret

checkWin:
    mov si, bricks
    mov cx, 48
checkWinLoop:
    lodsb
    cmp al, 0     
    jg notWinYet  
    loop checkWinLoop
    mov byte [gameOver], 2
    ret
notWinYet:
    ret

moveBall:
    mov al, [ballDX]
    add [ballX], al
    mov al, [ballDY]
    add [ballY], al
    
    ; Check Left Wall
    cmp byte [ballX], 2
    jg checkRightWall
    mov byte [ballDX], 1
    mov byte [ballX], 2
    jmp checkY
    
checkRightWall:
    cmp byte [ballX], 77
    jl checkY
    mov byte [ballDX], -1
    mov byte [ballX], 77

checkY:
    cmp byte [ballY], 2
    jle reverseDY
    
    cmp byte [ballY], 23
    je checkPaddle
    
    cmp byte [ballY], 24
    jge lostLife
    
    jmp checkBricks
    
reverseDY:
    neg byte [ballDY]
    jmp checkBricks
    
checkPaddle:
    mov al, [ballX]
    mov bl, [paddleX]
    cmp al, bl
    jl checkBricks
    
    mov cl, bl
    add cl, [paddleSize]
    cmp al, cl
    jge checkBricks
    
    mov byte [ballDY], -1
    
    ; Paddle Section Physics (4-2-4 split)
    add bl, 4              ; Left Zone (0-3)
    cmp al, bl
    jl paddleHitLeft
    
    add bl, 2              ; Center Zone (4-5)
    cmp al, bl
    jl paddleHitCenter
    
    mov byte [ballDX], 1   ; Right Zone (6-9)
    jmp checkBricks

paddleHitLeft:
    mov byte [ballDX], -1
    jmp checkBricks
    
paddleHitCenter:
    ; straight up logic removed, ball keeps horizontal direction
    jmp checkBricks
    
lostLife:
    dec byte [lives]
    mov byte [ballX], 40
    mov byte [ballY], 15
    mov byte [ballDX], 1
    mov byte [ballDY], -1
    mov byte [oldBallX], 40
    mov byte [oldBallY], 15
    
    cmp byte [lives], 0
    jne checkBricks
    mov byte [gameOver], 1
    
checkBricks:
    mov al, [ballY]
    cmp al, 3
    jl doneBricks
    cmp al, 7
    jge doneBricks
    
    mov al, [ballY]
    sub al, 3
    mov bl, al      ; bl = row

    mov al, [ballX]
    sub al, 10      ; Padding
    js doneBricks
    xor ah, ah
    mov cl, 5       ; DIVIDE BY 5
    div cl
    mov bh, al      ; bh = col

    cmp bh, 12      ; CHECK 0..11
    jae doneBricks

    mov al, bl
    xor ah, ah
    mov cl, 12      ; MULTIPLY BY 12
    mul cl
    xor ah, ah
    add al, bh
    xor ah, ah
    mov bx, ax      ; BX = brick index

    mov si, bricks
    add si, bx
    cmp byte [si], 0
    je doneBricks

    dec byte [si]
    jnz brickBounce

    push bx
    call eraseBrick
    pop bx
    add word [score], 10

brickBounce:
    neg byte [ballDY]

doneBricks:
    ret

playGame:
    call initGame
    call clearScreen
    call drawBorder
    
gameLoop:
    call drawBricks
    call drawStatus
    call drawPaddle
    call drawBall
    
    cmp byte [gameOver], 0
    jne endGameCheck
    call checkWin
    
endGameCheck:
    cmp byte [gameOver], 0
    jne showEndScreen
    
    ; --- FIX: BALL TIMER LOGIC ---
    inc byte [ballTimer]
    mov al, [ballThreshold]
    cmp byte [ballTimer], al
    jl skipBallMove
    
    ; Time to move ball
    mov byte [ballTimer], 0
    call moveBall

skipBallMove:
    ; --- FIX: FAST LOOP FOR PADDLE ---
    ; Controls Game FPS (Paddle smoothness)
    mov cx, 0x2500   
delayLoop:
    loop delayLoop
    
    mov ah, 0x01
    int 0x16
    jz gameLoop
    
    mov ah, 0x00
    int 0x16
    
    cmp ah, 0x01  
    je exitGame
    
    cmp ah, 0x4B  
    je moveLeft
    
    cmp ah, 0x4D 
    je moveRight
    
    jmp gameLoop
    
moveLeft:
    cmp byte [paddleX], 2
    jle gameLoop
    dec byte [paddleX]
    dec byte [paddleX] ; Fast Paddle
    jmp gameLoop
    
moveRight:
    mov al, [paddleX]
    add al, [paddleSize]
    cmp al, 77
    jge gameLoop
    inc byte [paddleX]
    inc byte [paddleX] ; Fast Paddle
    jmp gameLoop

showEndScreen:
    call clearScreen
    mov di, 1600
    cmp byte [gameOver], 1
    je showGameOverMsg
    mov si, winText
    mov ah, 0x0E
    call printString
    jmp showFinalScore
showGameOverMsg:
    mov si, gameOverText
    mov ah, 0x0C
    call printString
showFinalScore:
    mov ax, [score]
    call printNumber
    mov di, 1920
    mov si, pressEsc
    mov ah, 0x0F
    call printString
waitEndKey:
    mov ah, 0x00
    int 0x16
    cmp ah, 0x01
    jne waitEndKey
exitGame:
    ret

start:
    mov ah, 0x01
    mov ch, 0x20
    mov cl, 0x00
    int 0x10
    mov byte [currentScreen], 0
mainLoop:
    cmp byte [currentScreen], 0
    je showMenu
    cmp byte [currentScreen], 1
    je showInst
    cmp byte [currentScreen], 2
    je startGame
showMenu:
    call drawMainMenu
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je selectGame
    cmp al, '2'
    je selectInst
    cmp al, '3'
    je exitProgram
    jmp mainLoop
selectGame:
    mov byte [currentScreen], 2
    jmp mainLoop
selectInst:
    mov byte [currentScreen], 1
    jmp mainLoop
showInst:
    call drawInstructions
waitInstKey:
    mov ah, 0x00
    int 0x16
    cmp ah, 0x01
    je backToMenu
    jmp waitInstKey
backToMenu:
    mov byte [currentScreen], 0
    jmp mainLoop
startGame:
    call playGame
    mov byte [currentScreen], 0
    jmp mainLoop
exitProgram:
    mov ax, 0x4C00
    int 0x21