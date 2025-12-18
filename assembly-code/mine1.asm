;all the proc has pusha & popa so there aren't any affcted registers
IDEAL
MODEL small
STACK 100h
p186
DATASEG
; --------------------------
; Your variables here
line db ?
row db ?
numOfMines dw ?
field db 1001 dup(0)
status_square db 1001 dup (0) 	;0-hidden, 1-revealed, 2-flag
msg db "choose difficulty 1/2/3 (easy/medium/hard) $"
numOfSquares dw ?
numOfNonMine dw ?
numBlocksRevealed dw ?

currentNonMine dw ?
;numOfSquares-numOfMines = numOfNonMine

code db ? 	;a number between 0-12
x_coordinate dw ?
y_coordinate dw ?
firstClick dw ?
eight db 8
win_or_fail db ?	; 1-win, 0-fail
;get_square_number:
	square_number dw ?
	line_number db ?
	row_number db ?
; --------------------------
CODESEG
start:
	mov ax, @data
	mov ds, ax	
; --------------------------
; Your code here
mov cl, 0
@loop_games:
	call new_game
	;wait for character
		mov ah, 1
		int 21h
cmp al, 'q'
jne @loop_games
; --------------------------
	
exit:
	mov ax, 4c00h
	int 21h
;proc new_game - starts a new game
proc new_game
pusha
	mov bx, 1
	@@init_field_zero:
		mov [field + bx], 0
		mov [status_square + bx], 0
	inc bx
	cmp bx, 1000
	jbe @@init_field_zero
	mov [currentNonMine], 0
	mov [numBlocksRevealed], 0
	mov [line], 25
	mov [row], 40
	mov [win_or_fail], 0
	mov dx, offset msg
	mov ah, 9
	int 21h
	;input
	mov ah, 1
	int 21h
	sub al, '0'
	cmp al, 3
	je @@Hard
	cmp al, 2
	je @@med
	
	mov [numOfMines], 10
	jmp @@next
	@@med:
	mov [numOfMines], 150
	jmp @@next
	@@Hard:
	mov [numOfMines], 200
	@@next:
	xor ah, ah
	mov al, [line]
	mul [row]
	
	mov [numOfSquares], ax
	
	sub ax, [numOfMines]
	mov [numOfNonMine], ax
	
	mov ax, 13h
	int 10h	;מצב גרפי
	call print_hidden_field
	
		
	;initiate cursor
		xor ax, ax
		int 33h
	;show cursor
		mov ax, 1h
		int 33h
	@@first_click_loop:
		; DELAY
		mov ax, 70
	    call MOR_SLEEP
		;read mouse status and position
			mov ax,3h 	
			int 33h
			
			cmp bx, 2
			jne @@not_flag
			mov [y_coordinate], dx
			shr dx, 3
			inc dl
			mov [line_number], dl

			shr cx, 1
			mov [x_coordinate], cx
			shr cx, 3
			inc cl
			mov [row_number], cl
			call flag
			@@not_flag:
		cmp bx, 1 	;check left mouse click
		jne @@first_click_loop 	;if left click not pressed….
		
	
	;mov cursor's coordinates to the rectangle's coordinates
		mov [y_coordinate], dx
		shr dx, 3
		inc dl
		;dl = [row_number]
		mov [line_number], dl
		
		shr cx, 1
		mov [x_coordinate], cx
		shr cx, 3
		inc cl
		;cl = [line_number]
		mov [row_number], cl
		
		call get_square_number
		mov ax, [square_number]
		mov [firstClick], ax
		call setup_field
		
		mov [line_number], dl
		mov [row_number], cl
		call blank	;reveal_square
	call game_loop
	
	;hide cursor
	mov ax, 2h
	int 33h	
	
	cmp [win_or_fail], 1
	je @@win
	call fail
	jmp @@end_game
	@@win:
	call win
	@@end_game:
	;יציאת ממצב גרפי
	mov ax, 2h
	int 10h
popa
ret
endp 
; proc print_hidden_field - print all the covered squares (running at the begining)
; in - [row], [line]
; out - print blank screen
; AFFECTED REGISTERS : None (pusha and popa)
proc print_hidden_field
pusha
	mov [x_coordinate], 0
	mov [y_coordinate], 0
	mov cl, 1
	@@PrintLineLoop:
		mov ch, 1
		@@PrintRowLoop:
			;mov [row_number], ch
			;mov [line_number], cl
			;call get_square_number
			;mov bx, [square_number]
			mov [code], 12
			call draw_symbol
			add [x_coordinate], 8
		inc ch
		cmp ch, [row]
		jbe @@PrintRowLoop
		;enter
		add [y_coordinate], 8
		mov [x_coordinate], 0
	inc cl
	cmp cl, [line]
	jbe @@PrintLineLoop
popa
ret
endp print_hidden_field

; PROC : setup_field: setup the field arrey
; IN : [numOfMines],[numOfSquares], [row], [line]
; OUT: [field]
; AFFECTED REGISTERS : None (pusha and popa)
proc setup_field
pusha
	;setup mines
	mov cx, [numOfMines]
	@@SetupMines:		;שם מוקשים במקומות אקראיים
		@@randomMine:
			mov ax, [numOfSquares]
			call MOR_RANDOM 	;0 until 999
			inc ax		;1 until 1000
			mov bx, ax
			
			cmp bx, [firstClick]	;אסור שיהיה מוקש בלחיצה הראשונה
			je @@RandomMine
			inc bx
			cmp bx, [firstClick]
			je @@RandomMine
			sub bx, 2
			cmp bx, [firstClick]
			je @@RandomMine
			inc bx
			
			call get_di_and_si
			
			cmp si, [firstClick]	
			je @@RandomMine
			inc si
			cmp si, [firstClick]
			je @@RandomMine
			sub si, 2
			cmp si, [firstClick]
			je @@RandomMine
			
			cmp di, [firstClick]	
			je @@RandomMine
			inc di
			cmp di, [firstClick]
			je @@RandomMine
			sub di, 2
			cmp di, [firstClick]
			je @@RandomMine
			
		cmp [field + bx], 9		;בודק אם יש באותו מקום מוקש עד שאין שם
		je @@RandomMine
		;place mine
		mov [field + bx], 9
	loop @@SetupMines
	;setup blocks:
	mov cl, 1	;number of line
	@@LineLoop:
		mov ch, 1	;number of row
		@@RowLoop:
			mov [line_number] ,cl
			mov [row_number] ,ch
			call get_square_number
			mov bx, [square_number]
			call get_di_and_si
			
			cmp [field + bx], 9	;אם המשבצת היא מוקש
			je @@NextSquare1
			;איזה ערכים הוא משנה ביחס למשבצת:
			cmp ch, 1	;בודק אם הריבוע צמוד לשמאל
			jbe @@notLeft
			;left
				cmp [field + bx - 1], 9	;אם משמאל למשבצת יש מוקש
				jne @@notMidLeft				;שמאל אמצע
					inc [field + bx]
				@@notMidLeft:	
				cmp cl, 1
				jbe @@notUpperLeft
					cmp [field + di - 1], 9	 ;שמאל למעלה
					jne @@notUpperLeft
						inc [field + bx]
				@@notUpperLeft:
				cmp cl, [line]
				jae @@notLeft
					cmp [field + si - 1], 9	;שמאל למטה
					jne @@notLeft
						inc [field + bx]
			@@notLeft:
			jmp @@checkRight
			;relative jump out fo range fix:	
				@@NextSquare1:
					jmp @@NextSquare
				@@RowLoop1:
					jmp @@RowLoop
				@@LineLoop1:
					jmp @@LineLoop
			@@checkRight:
			cmp ch, [row]	;בודק אם הריבוע צמוד לימין
			jae @@notRight
			;right
				cmp [field + bx + 1], 9	;אם מימין למשבצת יש מוקש
				jne @@notMidRight				;ימין אמצע
					inc [field + bx]
				@@notMidRight:
				cmp cl, 1
				jbe @@notUpperRight
					cmp [field + di + 1], 9	 ;ימין למעלה
					jne @@notUpperRight
						inc [field + bx]
				@@notUpperRight:
				cmp cl, [line]
				jae @@notRight
					cmp [field + si + 1], 9		;ימין למטה
					jne @@notRight
						inc [field + bx]
			@@notRight:
			cmp cl, 1
			jbe @@notUp
				cmp [field + di], 9			;למעלה
				jne @@notUp
					inc [field + bx]
			@@notUp:
			cmp cl, [line]
			jae @@NextSquare
				cmp [field + si], 9			;למטה
				jne @@NextSquare
					inc [field + bx]
			@@NextSquare:
		inc ch
		cmp ch, [row]
		jbe @@RowLoop1
	inc cl
	cmp cl, [line]
	jbe @@LineLoop1
popa	
ret
endp setup_field

proc game_loop
pusha
	@@game_loop:
		; DELAY
		mov ax, 70
	    call MOR_SLEEP
		;read mouse status and position
			mov ax,3h 	
			int 33h
			
		mov [y_coordinate], dx
		shr dx, 3
		inc dl
		mov [line_number], dl

		shr cx, 1
		mov [x_coordinate], cx
		shr cx, 3
		inc cl
		mov [row_number], cl
		
		cmp bx, 2
		jne @@not_right_click
			call flag
			jmp @@not_left_click
		@@not_right_click:
		cmp bx, 1 	;check left mouse click
		jne @@not_left_click
		call get_square_number
		mov bx, [square_number]
		cmp [status_square + bx], 2
		je @@not_left_click
			call blank
			cmp [field + bx], 9
			je @@fail
			
			mov ax, [numOfNonMine]
			cmp [currentNonMine], ax
			je @@win
	@@not_left_click:
	jmp @@game_loop
		
		@@fail:
		mov [win_or_fail], 0	;fail
		jmp @@not_win
		@@win: 
		mov [win_or_fail], 1
		
		@@not_win:
	;mov cursor's coordinates to the rectangle's coordinates
		mov [y_coordinate], dx
		shr dx, 3
		inc dl
		;dl = [row_number]
		mov [row_number], cl
		
		shr cx, 1
		mov [x_coordinate], cx
		shr cx, 3
		inc cl
		;cl = [line_number]
		mov [line_number], dl
		

		call get_square_number
		mov ax, [square_number]
		mov [firstClick], ax
		call setup_field
		
		mov [line_number], dl
		mov [row_number], cl
		call reveal_square
popa
ret
endp game_loop
proc win
pusha
	
popa
ret
endp win
proc fail
pusha

popa
ret
endp fail

;in: [line_number], [row_number], [status_square], [eight], [field]
proc reveal_square
pusha
		call get_square_number
		mov bx, [square_number]
		cmp [status_square + bx], 0
		jne @@dont_reveal	;אם יש במקום דגל או שהוא כבר חשוף על תעשה כלום
		
		mov [status_square + bx], 1	;mark as revealed
		mov al, [line_number]
		dec al
		xor ah, ah
		mul [eight]
		mov [y_coordinate], ax
		mov al, [row_number]
		dec al
		xor ah, ah
		mul [eight]
		mov [x_coordinate], ax
		
		mov al, [field + bx]
		mov [code], al
		mov [status_square + bx], 1
		call draw_symbol
		
	@@dont_reveal:
popa
ret
endp reveal_square
;in: [line_number], [row_number], [status_square], [eight]
proc flag 
pusha
	call get_square_number
	mov bx, [square_number]
	cmp [status_square + bx], 1
	je @@revealed	;אם המקום כבר חשוף אל תשים או תוריד דגל
		
		mov al, [line_number]
		dec al
		xor ah, ah
		mul [eight]
		mov [y_coordinate], ax
		mov al, [row_number]
		dec al
		xor ah, ah
		mul [eight]
		mov [x_coordinate], ax
		
		cmp [status_square + bx], 0
		je @@hidden
		;already has a flag:
			mov [status_square + bx], 0
			mov [code], 12	;מקום ריק
			jmp @@draw
		@@hidden:
			mov [status_square + bx], 2
			mov [code], 11
		
		@@draw:
		
		call draw_symbol
		
		;call draw_rect
	@@revealed:
popa
ret
endp flag
; proc get_square_number - calculating the square number and move it to [square_number]
; in - [line_number], [row_number], [row] - static from the start of the game
; out - [square_number]
; AFFECTED REGISTERS : None (pusha and popa)
proc get_square_number
pusha
	;[square_number] = ([line_number] - 1) * [row] + [row_number]
		mov al, [line_number]
		dec al
		mul [row]
		mov [square_number], ax	;[square_number] = ([line_number] - 1) * [row]
		mov al, [row_number]	;ax = [row_number]
		xor ah, ah
		add [square_number], ax
popa
ret
endp get_square_number

; proc blank - revealing all the blank squares around the blank square (the proc calls itself)
; in - [row_number], [line_number], [row], [line]
; out - [square_number]
; AFFECTED REGISTERS : None (pusha and popa)
proc blank
pusha
	call get_square_number
	mov bx, [square_number]
	mov ch, [row_number]
	mov cl, [line_number]
	
	cmp [status_square + bx], 0
	je @@hidden_square
		jmp @@end_proc
		
		@@hidden_square:
		call reveal_square
		cmp [field + bx], 0
		je @@empty_square
		
		jmp @@end_proc
	@@empty_square:
	inc [currentNonMine]
	;איזה ערכים הוא משנה ביחס למשבצת:
	cmp ch, 1	;בודק אם הריבוע צמוד לשמאל
	jbe @@not_left
	;left
		dec [row_number]
		call blank
		inc [row_number]

	@@not_left:
	cmp ch, [row]
	jae @@not_right
	;right
		inc [row_number]
		call blank
		dec [row_number]
	@@not_right:
	
	cmp cl, 1
	jbe @@not_up
	;up
		dec [line_number]
		call blank
		inc [line_number]
	@@not_up:
	cmp cl, [line]
	jae @@not_down
	;down
		inc [line_number]
		call blank
		dec [line_number]
	@@not_down:
	
	call get_di_and_si
			
	;left
	cmp ch, 1
	jbe @@not_left2
		dec [row_number]
		cmp cl, 1
		jbe @@not_up_left
		
		;up_left
		cmp [field + di - 1], 0
		je @@not_up_left
		dec [line_number]
		call reveal_square
		inc [line_number]
		
		@@not_up_left:
		cmp cl, [line]
		jae @@not_down_left
		
		;down_left
		cmp [field + si - 1], 0
		je @@not_down_left
		inc [line_number]
		call reveal_square
		dec [line_number]
		
		
	@@not_down_left:
	inc [row_number]
	@@not_left2:
	
	;right
	cmp ch, [row]
	jae @@not_right2
		inc [row_number]
		cmp cl, 1
		jbe @@not_up_right
		
		;up_right
		cmp [field + di + 1], 0
		je @@not_up_right
		dec [line_number]
		call reveal_square
		inc [line_number]
		
		@@not_up_right:
		cmp cl, [line]
		jae @@not_down_right
		
		;down_left
		cmp [field + si + 1], 0
		je @@not_down_right
		inc [line_number]
		call reveal_square
		dec [line_number]
		
		
		@@not_down_right:
		dec [row_number]
	@@not_right2:
	
	
	@@end_proc:
popa
ret
endp blank
; proc get_di_and_si
; in - [row], bx - square_number
; out - di, si
; AFFECTED REGISTERS : di, si, ax
proc get_di_and_si
	;ax = [row]:
			mov al, [row]	
			xor ah, ah
	mov si, bx	;si = bx + [row]
	add si, ax
	mov di, bx	;di = bx - [row]
	sub di, ax
ret
endp get_di_and_si

proc print_field
pusha
	mov [x_coordinate], 0
	mov [y_coordinate], 0
	mov cl, 1
	@@PrintLineLoop:
		mov ch, 1
		@@PrintRowLoop:
			mov [row_number], ch
			mov [line_number], cl
			call get_square_number
			mov bx, [square_number]
			mov al, [field + bx]
			mov [code], al
			call draw_symbol
			add [x_coordinate], 8
		inc ch
		cmp ch, [row]
		jbe @@PrintRowLoop
		;enter
		add [y_coordinate], 8
		mov [x_coordinate], 0
	inc cl
	cmp cl, [line]
	jbe @@PrintLineLoop
popa
ret
endp print_field

INCLUDE "MOR_LIB.asm"	
INCLUDE "DRAW_LIB.asm"
END start