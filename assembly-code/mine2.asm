;all the proc has pusha & popa so there aren't any affcted registers
IDEAL
MODEL small
STACK 100h
p186
DATASEG
; --------------------------
; Your variables here
line equ 25
row equ 40
numOfSquares equ 1000	;equ: קבוע בתוכנית כדי שיהיה ברור ואם רוצים לשנות משהו בכל התוכנית

field db numOfSquares+1 dup(0)
status_square db numOfSquares+1 dup (0) 	;0-hidden, 1-revealed, 2-flag

numOfMines dw ?
numBlocksRevealed dw ?
currentNonMine dw ?
;numOfSquares-numOfMines = numBlocksRevealed

code db ? 	;a number between 0-12
x_coordinate dw ?
y_coordinate dw ?
firstClick dw ?
eight db 8
win_or_fail db ?	; 1-win, 0-fail
current_click db ? ;זוכר מה המקש הנוכחי של העכבר
;get_square_number:
	square_number dw ?
	line_number db ?
	row_number db ?
exit_game db ? ;0 - continue, 1 - stop
;pictures:
	openning db 'mine.bmp', 0
	difficulty db 'diff.bmp', 0
	customize db 'cust.bmp', 0
	won db 'win.bmp', 0
	failed db 'fail.bmp', 0
	
	;mouse proc:
		which_click dw ?
		click_or_release db 1
;custom
	is_start db 0
	hun db 1
	ten db 0
	unit db 0
	num_hundred db 100
	num_ten db 10
; --------------------------
CODESEG
start:
	mov ax, @data
	mov ds, ax	
; --------------------------
; Your code here
mov [exit_game], 0
;Graphic mode
	mov ax, 13h
	int 10h
;initiate cursor
	xor ax, ax
	int 33h
mov dx, offset openning 
call MOR_LOAD_BMP 

mov [which_click], 1
call mouse_click

mov [which_click], 1
mov [click_or_release], 2
call mouse_click
;Wait for key press
;mov ah,8
;int 21h
	
;mov cl, 0
@@loop_games:
	call new_game
cmp [exit_game], 1
jne @@loop_games
;Back to text mode
	mov ax, 2h
	int 10h
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
	mov [win_or_fail], 0
	mov [is_start], 0
	
	@@difficulty:
	mov dx, offset difficulty
    call MOR_LOAD_BMP
	;show cursor
		mov ax, 1h
		int 33h
	mov [which_click], 1
	call mouse_click
	shr cx, 1
	cmp cx, 214
	jbe @@not_right_side
	cmp dx, 171
	jb @@hard
	jmp @@custom
	
	@@not_right_side:
	cmp cx, 106
	ja @@mid
	
	cmp dx, 171	;check if to quit
	jb @@easy
	mov [exit_game], 1
	jmp @@end_game
	
	@@easy:
	mov [numOfMines], 40
	jmp @@next
	@@mid:
	mov [numOfMines], 100
	jmp @@next
	@@Hard:
	mov [numOfMines], 150
	jmp @@next
	@@custom:
		call custom
		cmp [is_start], 1
		jne @@difficulty
	@@next:
	cmp [numOfMines], 991
	jbe @@normal_input
	mov [numOfMines], 991
	
	
	@@normal_input:
	cmp [numOfMines], 0
	ja @@normal_input2
	mov [numOfMines], 1
	@@normal_input2:
	mov ax, numOfSquares
	sub ax, [numOfMines]
	mov [numBlocksRevealed], ax
	
	;hide cursor
	mov ax, 2h
	int 33h
	
		;Back to text mode
		mov ax, 2h
		int 10h
		;Graphic mode
		mov ax, 13h
		int 10h
	
	call print_hidden_field
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
		mov [which_click], 2
		mov [click_or_release], 2
		call mouse_click
			@@not_flag:
		cmp bx, 1 	;check left mouse click
		jne @@first_click_loop 	;if left click not pressed….
		
		call get_line_and_row
		call get_square_number
		mov ax, [square_number]
		mov [firstClick], ax
		
		
		call setup_field
		
		mov [line_number], dl
		mov [row_number], cl
		call blank	;reveal_square
	
	mov ax, [numBlocksRevealed]
	cmp [currentNonMine], ax
	jae @@win
	call game_loop
	
	mov ax, [numBlocksRevealed]
	cmp [currentNonMine], ax
	jae @@win
	
	call hide_cursor
	mov dx, offset failed
	jmp @@show_picture
	@@win:
	call hide_cursor
	mov dx, offset won
	@@show_picture:
	
	call MOR_LOAD_BMP 
	@@wait_for_click:
	
	mov [which_click], 1
	call mouse_click
	
	mov [which_click], 1
	mov [click_or_release], 2
	call mouse_click
	@@end_game:
popa
ret
endp new_game

; proc print_hidden_field - print all the covered squares (running at the begining)
; in - row, line
; out - [x_coordinate], [y_coordinate](affcted not intended)
; AFFECTED REGISTERS : None (pusha and popa)
proc print_hidden_field
pusha
	mov [x_coordinate], 0
	mov [y_coordinate], 0
	mov cl, 1
	@@PrintLineLoop:
		mov ch, 1
		@@PrintRowLoop:
			mov [code], 12
			call draw_symbol
			add [x_coordinate], 8
		inc ch
		cmp ch, row
		jbe @@PrintRowLoop
		;enter
		add [y_coordinate], 8
		mov [x_coordinate], 0
	inc cl
	cmp cl, line
	jbe @@PrintLineLoop
popa
ret
endp print_hidden_field

; PROC : setup_field: setup the field arrey
; IN : [numOfMines],[firstClick], row, line, numOfSquares
; OUT: [field]
; AFFECTED REGISTERS : None (pusha and popa)
proc setup_field
pusha
	;setup mines
	mov cx, [numOfMines]
	@@SetupMines:		;שם מוקשים במקומות אקראיים
		@@randomMine:
			mov ax, numOfSquares
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
				cmp cl, line
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
			cmp ch, row	;בודק אם הריבוע צמוד לימין
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
				cmp cl, line
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
			cmp cl, line
			jae @@NextSquare
				cmp [field + si], 9			;למטה
				jne @@NextSquare
					inc [field + bx]
			@@NextSquare:
		inc ch
		cmp ch, row
		jbe @@RowLoop1
	inc cl
	cmp cl, line
	jbe @@LineLoop1
popa	
ret
endp setup_field

; proc game_loop - the main loop of the game
; in - [status_square], [field], [numBlocksRevealed], [currentNonMine]
; out - [win_or_fail]
; AFFECTED REGISTERS : None (pusha and popa)
proc game_loop
pusha
	@@game_loop:
			@@wait_for_input:
				; DELAY
				mov ax, 70
				call MOR_SLEEP
				;read mouse status and position
					mov ax,3h 	
					int 33h
				cmp bx, 1
				je @@left_click
				cmp bx, 2
				je @@right_click
			jmp @@wait_for_input
					
			@@right_click:
				call get_line_and_row
				call flag
				jmp @@after_click
			@@left_click:
				call get_line_and_row
				call get_square_number
				mov bx, [square_number]
				cmp [status_square + bx], 2		;if it has no flag
				je @@after_click
					call blank
						cmp [field + bx], 9
						je @@after_game_loop
				mov ax, [numBlocksRevealed]
				cmp [currentNonMine], ax
				jae @@after_game_loop
		@@after_click:
			@@wait_for_release:
				; DELAY
				mov ax, 70
				call MOR_SLEEP
				;read mouse status and position
					mov ax,3h 	
					int 33h
				cmp bx, 0
				jne @@wait_for_release
		jmp @@game_loop
		@@after_game_loop:
popa
ret
endp game_loop

; proc flag - put or remove flag symbol from a square
; in - [line_number], [row_number], [status_square], [eight], [field]
; out - [status_square], [x_coordinate], [y_coordinate], [code], [currentNonMine]
; AFFECTED REGISTERS : None (pusha and popa)
proc reveal_square
pusha
	call get_square_number
	mov bx, [square_number]
	cmp [status_square + bx], 0
	jne @@dont_reveal	;if there is a revealed flag jump to the end of the proc
		cmp [field + bx], 9
		je @@reveal
			inc [currentNonMine]
		@@reveal:
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

; proc flag - put or remove flag symbol from a square
; in - [line_number], [row_number], [status_square], [eight]
; out - [status_square], [x_coordinate], [y_coordinate], [code]
; AFFECTED REGISTERS : None (pusha and popa)
proc flag 
pusha
	call get_square_number
	mov bx, [square_number]
	cmp [status_square + bx], 1
	je @@revealed	;אם המקום כבר חשוף אל תשים או תוריד דגל	
		;calculating the x and y for the draw_symbol
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
			mov [code], 12	;מוריד דגל
			jmp @@draw
		@@hidden:
			mov [status_square + bx], 2
			mov [code], 11	;דגל
		@@draw:
		call draw_symbol
	@@revealed:
popa
ret
endp flag

; proc get_square_number - calculating the square number and move it to [square_number]
; in - [line_number], [row_number], row
; out - [square_number]
; AFFECTED REGISTERS : None (pusha and popa)
proc get_square_number
pusha
	;[square_number] = ([line_number] - 1) * [row] + [row_number]
		mov al, [line_number]
		dec al
		mov bl, row
		mul bl
		mov [square_number], ax	;[square_number] = ([line_number] - 1) * [row]
		mov al, [row_number]	;ax = [row_number]
		xor ah, ah
		add [square_number], ax
popa
ret
endp get_square_number

; proc blank - revealing all the blank squares around the blank square (the proc calls itself)
; in - [row_number], [line_number], row, line
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
	;איזה ערכים הוא משנה ביחס למשבצת:
	cmp ch, 1	;בודק אם הריבוע צמוד לשמאל
	jbe @@not_left
	;left
		dec [row_number]
		call blank
		inc [row_number]

	@@not_left:
	cmp ch, row
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
	cmp cl, line
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
		cmp cl, line
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
	cmp ch, row
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
		cmp cl, line
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
; in - row, bx - square_number
; out - di, si
; AFFECTED REGISTERS : di, si, ax
proc get_di_and_si
	;ax = row:
			mov al, row	
			xor ah, ah
	mov si, bx	;si = bx + row
	add si, ax
	mov di, bx	;di = bx - row
	sub di, ax
ret
endp get_di_and_si

; proc get_line_and_row
; in - dx, cx
; out - [x_coordinate], [y_coordinate], [line_number], [row_number]
; AFFECTED REGISTERS : dx, cx
proc get_line_and_row
	mov [y_coordinate], dx
	shr dx, 3
	inc dl
	mov [line_number], dl

	shr cx, 1
	mov [x_coordinate], cx
	shr cx, 3
	inc cl
	mov [row_number], cl
ret
endp get_line_and_row

; proc mouse_click
; in - [which_click]: 1=left click, 2=right click [click_or_release]: defalte wait for click, != 1: wait for release
; out - [click_or_release]
; AFFECTED REGISTERS : ax
proc mouse_click
	@@loop:
		; DELAY
		mov ax, 70
		call MOR_SLEEP
		;read mouse status and position
			mov ax,3h 	
			int 33h
		
		;check if to click or release
		cmp [click_or_release], 1
		je @@wait_for_click
		
		cmp bx, [which_click]
		je @@loop
		jmp @@out_of_loop
		
		@@wait_for_click:
		cmp bx, [which_click]
		jne @@loop
	@@out_of_loop:
	mov [click_or_release],1
ret
endp mouse_click
; proc custom - custom number of mines
; in - none
; out - [is_start]
; AFFECTED REGISTERS : none
proc custom
pusha
	mov [which_click], 1
	mov [click_or_release], 2
	call mouse_click
	call hide_cursor	
	mov dx, offset customize
	call MOR_LOAD_BMP
	call show_cursor
	
	mov [sign_or_num], 1
	mov ax, 100
	call print_digit
	mov [sign_or_num], 1
	mov ax, 10
	call print_digit
	mov [sign_or_num], 1
	mov ax, 1
	call print_digit
	
	@@loop:
	mov [which_click], 1
	call mouse_click
	mov [which_click], 1
	mov [click_or_release], 2
	call mouse_click
	
	shr cx, 1
	cmp cx, 214
	jb @@not_right
	cmp dx, 171
	ja @@start
	cmp dx, 54
	jb @@plus_unit
	jmp @@minus_unit
	
	@@not_right:
	cmp cx, 106
	jbe @@not_mid
	cmp dx, 54
	jb @@plus_ten
	jmp @@minus_ten
	
	@@not_mid:
	cmp dx, 171
	ja @@back
	cmp dx, 54
	jb @@plus_hun
	jmp @@minus_hun
	
	@@start:
		mov [is_start], 1
		jmp @@end_proc
	@@back:
		mov [is_start], 0
		call hide_cursor
		jmp @@end_proc
	@@plus_hun:
		inc [hun]
		mov ax, 100
		jmp @@after_click
	@@minus_hun:
		dec [hun]
		mov ax, 100
		jmp @@after_click
	@@plus_ten:
		inc [ten]
		mov ax, 10
		jmp @@after_click
	@@minus_ten:
		dec [ten]
		mov ax, 10
		jmp @@after_click
	@@plus_unit:
		inc [unit]
		mov ax, 1
		jmp @@after_click
	@@minus_unit:
		dec [unit]
		mov ax, 1
		
	@@after_click:
	
	cmp [unit], 10
	jne @@unit_below
	mov [unit], 0
	inc [ten]
	@@unit_below:
	cmp [unit], 255
	jne @@unit_above
	mov [unit], 9
	dec [ten]
	@@unit_above:
	
	cmp [ten], 10
	jne @@ten_below
	mov [ten], 0
	inc [hun]
	@@ten_below:
	cmp [ten], 255
	jne @@ten_above
	mov [ten], 9
	dec [hun]
	@@ten_above:
	
	cmp [hun], 10
	jne @@hun_below
	mov [hun], 0
	@@hun_below:
	cmp [hun], 255
	jne @@hun_above
	mov [hun], 9
	@@hun_above:
	
	
		mov ax, 1
		mov [sign_or_num], 1
		call print_digit
		mov ax, 10
		mov [sign_or_num], 1
		call print_digit
		mov ax, 100
		mov [sign_or_num], 1
		call print_digit
	jmp @@loop
	
	
	
	@@end_proc:
	xor ah, ah
	mov al, [hun]
	mul [num_hundred]
	mov [numOfMines], ax
	xor ah, ah
	mov al, [ten]
	mul [num_ten]
	add [numOfMines], ax
	xor ah, ah
	mov al, [unit]
	add [numOfMines], ax
	popa
ret

endp custom
proc hide_cursor
	mov ax, 2h
	int 33h
ret
endp hide_cursor
	
proc show_cursor
	mov ax, 1h
	int 33h
ret
endp show_cursor

; proc print_digit
; in - ax - 1,10,100
; out - [is_start]
; AFFECTED REGISTERS : bx
proc print_digit
	mov [x_coordinate], 146
	mov bl, [hun]
	cmp ax, 100
	je @@print
	
	add [x_coordinate], 8
	mov bl, [ten]
	cmp ax, 10
	je @@print
	
	add [x_coordinate], 8
	mov bl, [unit]
	
	@@print:
	mov [y_coordinate], 50
	mov [code], bl
	call draw_symbol
ret
endp print_digit
INCLUDE "MOR_LIB.asm"	
INCLUDE "DRAW_LIB.asm"
END start