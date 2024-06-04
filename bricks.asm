.286
.model small
.stack 100h
.data
	studentID db "260987312$" ; change the content of the string to your studentID (do not remove the $ at the end)
	ball_x dw 160	 ; Default value: 160
	ball_y dw 144	 ; Default value: 144
	ball_x_vel dw 0	 ; Default value: 0
	ball_y_vel dw -1 ; Default value: -1 
	paddle_x dw 144  ; Default value: 144
	paddle_length dw 32 ; Default value: 32
	countSinceUsedPowerOne dw 0	; counts the loops since you've used a power until 500
	countSinceUsedPowerTwo dw 0	; counts the loops since you've used a power until y=whatever
	countScoreSincePower dw 0	; counts the score since the last power up
	diffOfScoreLastTurn dw 0	; difference between score of this turn and last turn
	previousTurnScore dw 0
	powerUpTwoXCoord dw 160
	
.code

; get the functions from the util_br.obj file (needs to be linked)
EXTRN setupGame:PROC, drawBricks:PROC, checkBrickCollision:PROC, sleep:PROC, decreaseLives:PROC, getScore:PROC, clearPaddleZone:PROC

start:
        mov ax, @data
        mov ds, ax
	
	push OFFSET studentID ; do not change this, change the string in the data section only
	push ds
	call setupGame ; change video mode, draw walls & write score, studentID and lives
	call drawPaddle
	call drawBricks
	call drawBall
	jmp keyboardInput
	
main_loop:
	
	mov ax, 0
	mov bx, 100	
	call drawBall
	call sleep

	call getScore			; these 6 lines do this -> countScoreSincePower += (getScore() - previousScore); previousScore = getScore();
	mov cx, previousTurnScore
	sub ax, cx
	add countScoreSincePower, ax
	call getScore
	mov previousTurnScore, ax
	mov ax, 0

	mov cx, countSinceUsedPowerOne
	cmp cx, 0
	je afterIteratePowerOne
	call iteratePowerOne		; add one to the variable, that's it. If it's zero then we skip cus power is not in use.
	
afterIteratePowerOne:
	mov cx, countSinceUsedPowerTwo
	cmp cx, 0
	je afterIteratePowerTwo
	call iteratePowerTwo

afterIteratePowerTwo:
	mov cx, ball_y
	cmp cx, 199			; i should be reseting power up from this condition
	jle keypressCheck
	call resetAfterBallLoss

	cmp ax, 0
	jg keyboardInput
	jmp keyBoardInputEnd
	
keypressCheck:
	mov ah, 01h ; check if keyboard is being pressed
	int 16h ; zero flag (zf) is set to 1 if no key pressed
	jz main_loop ; if zero flag set to 1 (no key pressed), loop back

keyboardInput:
	; else get the keyboard input
	mov ah, 00h
	int 16h

	cmp al, 1bh
	je exit
	cmp al, 61h
	je leftPaddle
	cmp al, 41h
	je leftPaddle
	cmp al, 64h
	je rightPaddle
	cmp al, 44h
	je rightPaddle
	cmp al, 31h
	je powerUpOneBranch
	cmp al, 32h	
	je powerUpTwoBranch

	jmp main_loop

keyboardInputEnd:
	mov ah, 00h
	int 16h

	cmp al, 1bh
	je exit
	jmp keyboardInputEnd

exit:
        mov ax, 4f02h	; change video mode back to text
        mov bx, 3
        int 10h

	;push ax
	;push dx

	;mov ah, 6
	;mov dx, counter
	;int 21h	

	;pop dx
	;pop dx
	

        mov ax, 4c00h	; exit
        int 21h

powerUpOneBranch:
	call powerUpOne
	jmp main_loop
powerUpTwoBranch:
	call powerUpTwo
	jmp main_loop

leftPaddle:
	push bx
	
	mov bx, paddle_x
	sub bx, 8
	
	cmp bx, 0
	jl setToZero

	mov paddle_x, bx
	call drawPaddle

	pop bx		
	
	jmp main_loop

setToZero:
	mov paddle_x, 0
	call drawPaddle

	pop bx
	jmp main_loop

rightPaddle:
	
	push bx
	push ax
	
	add paddle_x, 8
	mov bx, paddle_x
	mov ax, 320
	sub ax, paddle_length
	cmp bx, ax
	jg setToThreeHTw
	
	call drawPaddle

	pop ax
	pop bx
	
	jmp main_loop

setToThreeHTw:
	
	mov paddle_x, ax
	call drawPaddle	

	pop ax
	pop bx
	jmp main_loop


; draw a single pixel specific to Mode 13h (320x200 with 1 byte per color)
drawPixel:
	color EQU ss:[bp+4]
	x1 EQU ss:[bp+6]
	y1 EQU ss:[bp+8]

	push	bp
	mov	bp, sp

	push	ax
	push	bx
	push	cx
	push	dx
	push	es

	; set ES as segment of graphics frame buffer
	mov	ax, 0A000h
	mov	es, ax


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1
	mov	cx, 320
	xor	dx, dx
	mov	ax, y1
	mul	cx
	add	bx, ax

	; DX = color
	mov	dx, color

	; plot the pixel in the graphics frame buffer
	mov	BYTE PTR es:[bx], dl

	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	pop	bp

	ret	6

drawBall:
	push	bp
	mov	bp, sp

	push ax
	push bx
	push cx
	push dx
	

	;add counter, 1	

	; draw the current pixel as black
	; set the current pixel based on the trajectory of the velocity
	; paint the current pixel 0Fh color
		
	mov ax, ball_x
	mov bx, ball_y

	; color the current ball position black
	push bx ; y-coord
	push ax ; x-coord
	push 00h; color
	call drawPixel

	mov cx, ball_x_vel
	mov dx, ball_y_vel

	; Before we update the position of the ball, we need to check if we are colliding with a wall.
	; So we make ax and bx the interim-next-position and we check if it's a wall.
	; If it is then we change the velocity and keep going.
	; Else we just keep going.
	add ax, cx
	add bx, dx

	push bx
	push ax
	call handleCollisions

	; add the velocities to their respective ball-locations
	add ball_x, cx
	add ball_y, dx

	mov ax, ball_x
	mov bx, ball_y
	
	; color the next position
	push bx; y-coord
	push ax; x-coord
	push 0Fh; color
	call drawPixel

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp

	ret

drawPaddle:

	push	bp
	mov	bp, sp

	push ax
	push bx
	push cx	

	call clearPaddleZone
	
	mov ax, 183
yLoop:
	cmp ax, 187
	je paddleExit

	add ax, 1
	
	; three x-loops (1) paddle_x to (pad_len-4)/2 (2) 4 times (3) until paddle_length

	; bx = paddle_x + (paddle_length -4)/2
	mov bx, paddle_length
	sub bx, 4
	sar bx, 1
	add bx, paddle_x

	; cx = paddle_x
	mov cx, paddle_x
	sub cx, 1	;so that it starts at this number plus one.
	
xLoopA:
	cmp cx, bx
	je before_xLoopB
	add cx, 1
	
	push ax ; y-coord
	push cx ; x-coord
	push 2Ch; color
	call drawPixel
	
	jmp xLoopA	

before_xLoopB:
	; bx = bx + 4
	add bx, 4
xLoopB:
	cmp cx, bx
	je before_xLoopC
	add cx, 1
	
	push ax ; y-coord
	push cx ; x-coord
	push 2Dh; color
	call drawPixel
	
	jmp xLoopB
before_xLoopC:
	; bx = end of the paddle plus one
	; bx = left_paddle + paddle_length
	mov bx, paddle_x
	add bx, paddle_length
xLoopC:
	cmp cx, bx
	je yLoop
	add cx, 1
	
	push ax ; y-coord
	push cx ; x-coord
	push 2Eh; color
	call drawPixel
	
	jmp xLoopC

paddleExit:
	pop cx
	pop bx	
	pop ax

	mov sp, bp
	pop bp

	ret

resetAfterBallLoss:

	push	bp
	mov	bp, sp

	push cx
	push bx

	mov ball_x, 160
	mov ball_y, 144
	mov ball_x_vel, 0
	mov ball_y_vel, -1
	mov paddle_x, 144
	mov paddle_length, 32

	mov cx, ball_x
	mov bx, ball_y
	
	; color the next position
	push bx; y-coord
	push cx; x-coord
	push 0Fh; color
	call drawPixel

	call drawPaddle

	call decreaseLives

	pop bx
	pop cx

	mov sp, bp
	pop bp

	ret

handleCollisions:
	
	x EQU ss:[bp+4]
	y EQU ss:[bp+6]

	push	bp
	mov	bp, sp
	
	push ax
	push bx
	push cx

	mov bx, y
	mov cx, x

	push ball_y_vel
	push ball_x_vel
	push ball_y
	push ball_x
	call checkBrickCollision

	cmp ax, 0
	jne brickCollision

	push bx
	push cx
	call checkPaddleCollision

	cmp ax, 1
	je negativeXVel
	cmp ax, 2
	je zeroXVel
	cmp ax, 3
	je plusXVel

	jmp noPaddleCollision

negativeXVel:
	mov ball_x_vel, -1
	mov ball_y_vel, -1
	jmp exitHandle

zeroXVel:
	mov ball_x_vel, 0
	mov ball_y_vel, -1
	jmp exitHandle

plusXVel:
	mov ball_x_vel, 1
	mov ball_y_vel, -1
	jmp exitHandle

noPaddleCollision:
	push bx
	push cx
	call checkWallCollision
	
brickCollision: 			; handles same way as wall collision

	mov bx, ax

	mov cx, 0
	cmp bx, 0
	je afterHandle

	cmp bx, 1
	je invertXVel

	cmp bx, 2
	je invertYVel
	
	mov cx, 1
	jmp AfterHandle

invertXVel:
	mov cx, ball_x_vel
	cmp cx, 1
	je MakeXMinus
	mov ball_x_vel, 1
	
	mov cx, 0
	jmp AfterHandle

MakeXMinus: 
	mov ball_x_vel, -1
	
	mov cx, 0
	jmp AfterHandle
	
invertYVel:
	mov cx, ball_y_vel
	cmp cx, 1
	je MakeYMinus
	mov ball_y_vel, 1

	mov cx, 0
	jmp AfterHandle

MakeYMinus: 
	mov ball_y_vel, -1

	mov cx, 0
	jmp AfterHandle

AfterHandle:
	cmp cx, 0
	je exitHandle
	
invertXVel_a:
	mov cx, ball_x_vel
	cmp cx, 1
	je MakeXMinus_a
	mov ball_x_vel, 1
	
	jmp invertYVel_a

MakeXMinus_a: 
	mov ball_x_vel, -1
	
invertYVel_a:
	mov cx, ball_y_vel
	cmp cx, 1
	je MakeYMinus_a
	mov ball_y_vel, 1

	jmp exitHandle

MakeYMinus_a:
	mov ball_y_vel, -1

exitHandle:

	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp

	ret 4

checkPaddleCollision:
	; push y
	; push x
	; call checkWallCollision

	x_b EQU ss:[bp+4]
	y_b EQU ss:[bp+6]

	push	bp
	mov	bp, sp
	
	push bx
	push cx

	mov bx, x_b
	mov cx, y_b

	cmp cx, 183
	jne paddleColReturnZero

	add cx, 1
	
	push cx
	push bx
	call getPixel

	cmp ax, 0; if its black spot, return 0
	je paddleColReturnZero

	cmp ax, 2Ch ; if its... you get it
	je paddleColReturnOne

	cmp ax, 2Dh
	je paddleColReturnTwo

	cmp ax, 2Eh
	je paddleColReturnThree

	jmp paddleColReturnZero ; HERE FOR OFFICE HOURS

paddleColReturnThree:
	mov ax, 3
	jmp paddleCollisionExit

paddleColReturnTwo:
	mov ax, 2
	jmp paddleCollisionExit

paddleColReturnOne:
	mov ax, 1
	jmp paddleCollisionExit

paddleColReturnZero:
	mov ax, 0

paddleCollisionExit:
	
	pop cx
	pop bx

	mov sp, bp
	pop bp

	ret 4
	

checkWallCollision:

	; push y
	; push x
	; call checkWallCollision

	x_a EQU ss:[bp+4]
	y_a EQU ss:[bp+6]

	push	bp
	mov	bp, sp
	
	push bx
	push cx
	push dx

	mov bx, x_a
	cmp bx, 16
	je xIsSixteen	

	; when x=16 we make bx 0
	; when it's greater than we make it 1
	; when it's exactly 303 we make it 0	

	; For both x and y, I assume that they cannot exceed or be lower than the bounds given. If there's an error, the first thing I'll fix is those edge cases.

xIsNotSixteen:
	cmp bx, 303
	jl xBetweenSixteenAndThreeHThree ; the case where it's below 16 is not handled
	mov bx, 0
	jmp AfterX

xBetweenSixteenAndThreeHThree:
	mov bx, 1
	jmp AfterX
	
xIsSixteen:
	mov bx, 0		

AfterX:

	; when y=32, cx=0
	; when y is more, cx = 1

	mov cx, y_a
	cmp cx, 32
	je yIsThirtyTwo 

	cmp cx, 32
	jl yIsLessThanThirtyTwo
	
	mov cx, 1
	jmp AfterY


yIsLessThanThirtyTwo:
	mov cx, 2
	jmp AfterY

yIsThirtyTwo:
	mov cx, 0

AfterY:
	
	cmp cx, 2 
	je returnZero 		; when y is somehow less than 32	

	cmp bx, 1 
	je maybeReturnTwo	; when x is between 17 and 302 both inclusive
	
	cmp cx, 1		
	je returnOne		; when y = 32
	mov dx, 3		; when x=16 or x=303 AND y=32
	jmp afterChecks

maybeReturnTwo:
	cmp cx, 0
	jne returnZero 		; when y is > 32 then we get a not wall case, return 0
	mov dx, 2		; else return 2
	jmp afterChecks
	
returnOne:
	mov dx, 1
	jmp afterChecks

returnZero:
	mov dx, 0

afterChecks:

	mov ax, dx

	pop dx
	pop cx
	pop bx

	mov sp, bp
	pop bp

	ret 4

; gets pixel at given coord and returns colour in ax
getPixel:
	x1 EQU ss:[bp+4]
	y1 EQU ss:[bp+6]

	push	bp
	mov	bp, sp

	push	bx
	push	cx
	push	dx
	push	es

	; set ES as segment of graphics frame buffer
	mov	ax, 0A000h
	mov	es, ax


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1
	mov	cx, 320
	xor	dx, dx
	mov	ax, y1
	mul	cx
	add	bx, ax

	; plot the pixel in the graphics frame buffer
	mov	al, BYTE PTR es:[bx]
	xor ah, ah

	pop	es
	pop	dx
	pop	cx
	pop	bx

	pop	bp

	ret	4

powerUpTwo:

	push	bp
	mov	bp, sp
	
	push bx

	; check for the score being at least 50
	; check if we're already in a powerUpTwo loop

	mov bx, countScoreSincePower 	; counts the score since the last power up used
	cmp bx, 50			; if the score is less than 50 then leave
	jl powerUpTwoExit
	
	mov bx, countSinceUsedPowerTwo	; counts the loop iterations since this power up has been used
	cmp bx, 0			; if the score is not zero it means we're in the middle of a power up so leave
	jg powerUpTwoExit

	mov countScoreSincePower, 0	; reset the score tally to zero since we've just used a power up
	mov countSinceUsedPowerTwo, 1	; set this to 1 so that the code way above (in main loop) knows to iterate the power up

	; paint one pixel as defined by pdf
	; the iteration of this pixel (its movement) is not in here, it is in the iteratePowerTwo label

	; y, x, color
	
	mov bx, paddle_length
	sar bx, 1
	add bx, paddle_x
	mov powerUpTwoXCoord, bx
	
	push 183
	push bx
	push 02h
	call drawPixel

powerUpTwoExit:

	pop bx

	mov 	sp, bp
	pop 	bp

	ret

powerUpOne:

	push	bp
	mov	bp, sp
	
	push bx
	
	mov bx, countScoreSincePower 	; counts the score since the last power up used
	cmp bx, 50			; if the score is less than 50 then leave
	jl powerUpOneExit

	mov bx, countSinceUsedPowerOne	; counts the loop iterations since this power up has been used
	cmp bx, 0			; if the score is not zero it means we're in the middle of a power up so leave
	jg powerUpOneExit

	; increase size of paddle
	; do it for 500 iterations, this check won't be here tho
	; the implementation for checking the iterations is going to be in powerUpOneBranch (near the top)

	mov paddle_length, 64
	mov countScoreSincePower, 0
	mov countSinceUsedPowerOne, 1

powerUpOneExit:

	pop bx

	mov 	sp, bp
	pop 	bp

	ret

iteratePowerOne:
	add countSinceUsedPowerOne, 1
	cmp countSinceUsedPowerOne, 500
	jge setPowerOneToZero
	jmp iterPowerOneEnd

setPowerOneToZero:
	mov countSinceUsedPowerOne, 0
	mov paddle_length, 32
iterPowerOneEnd:
	ret

iteratePowerTwo:

	push bx	
	push ax

	mov bx, 183
	sub bx, countSinceUsedPowerTwo

	push -1				;ball_y_vel
	push  0				;ball_x_vel
	push bx				;ball_y
	push powerUpTwoXCoord		;ball_x
	call checkBrickCollision

	push bx					; 183 - iteration
	push powerUpTwoXCoord
	push 02h
	call drawPixel

	add bx, 1
	push bx					; paint the previous spot black again
	push powerUpTwoXCoord
	push 00h
	call drawPixel

	add countSinceUsedPowerTwo, 1

	cmp countSinceUsedPowerTwo, 151		; 183-32 = 151. If we get here the laser is done.
	jne iteratePowerTwoEnd

	mov countSinceUsedPowerTwo, 0		; paint the last spot black again

	sub bx, 1
	push bx					; paint the previous spot black again
	push powerUpTwoXCoord
	push 00h
	call drawPixel
	

iteratePowerTwoEnd:
	pop ax
	pop bx
	ret

END start

