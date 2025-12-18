;  DRAW_LIB  -  written by Nitsan Weingart

DATASEG
;------------
color dw ?
lenX dw ?
lenY dw ?
x_temp dw ?
y_temp dw ?
sign_or_num db 0
CODESEG
;===========================
; PROC : draw_symbol: draws symbol
; IN : [x_coordinate], [y_coordinate], [code] (0 - 12), [sign_or_num]
; OUT: draws a symbol
; AFFECTED REGISTERS : None (pusha and popa)
proc draw_symbol
	pusha
	;hide cursor
		mov ax, 2h
		int 33h
	;דגל צריך להיות מעל, לא צריך רקע
		cmp [code], 11
		jne @@not_eleven
		call draw_flag
		jmp @@endProc
	@@not_eleven:
	cmp [code], 12
	je @@white_outline
	mov [color], 8;dark grey
	jmp @@draw_outline
	@@white_outline:
	mov [color], 15;white
	
	@@draw_outline:
	mov [lenX], 8
	mov ax, [y_coordinate]
	mov [y_temp], ax
	call draw_line
	mov ax, [x_coordinate]
	mov [x_temp], ax
	mov [lenY], 8
	call draw_row
	
	cmp [code], 10
	je @@red_background
	mov [color], 7	;אפור בהיר
	jmp @@draw_background
	@@red_background:
	mov [color], 4	;אדום
	
	@@draw_background:
	;draw grey rect(base):
	inc [x_coordinate]
	inc [y_coordinate]
	mov [lenX], 7
	mov [lenY], 7
	call draw_rect
	dec [x_coordinate]
	dec [y_coordinate]
	
	cmp [code], 1
	je @@one
	cmp [code], 2
	je @@two
	cmp [code], 3
	je @@three
	cmp [code], 4
	je @@four
	cmp [code], 5
	je @@five
	cmp [code], 6
	je @@six
	cmp [code], 7
	je @@seven
	cmp [code], 8
	je @@eight
	cmp [code], 9
	je @@nine
	cmp [code], 10
	je @@nine	
	
	
	jmp @@twelve
	
	@@one:
	call draw_1
	jmp @@endProc
	@@two:
	call draw_2
	jmp @@endProc
	@@three:
	call draw_3
	jmp @@endProc
	@@four:
	call draw_4
	jmp @@endProc
	@@five:
	call draw_5
	jmp @@endProc
	@@six:
	call draw_6
	jmp @@endProc
	@@seven:
	call draw_7
	jmp @@endProc
	@@eight:
	call draw_8
	jmp @@endProc
	@@nine:
	cmp [sign_or_num], 0
	jne @@not_mine
	call draw_mine
	jmp @@endProc
	@@not_mine:
		call draw_num_9
	jmp @@endProc
	
	@@twelve:
	cmp [sign_or_num], 0
	jne @@not_hidden
	call draw_hidden
	jmp @@endProc
	@@not_hidden:
		call draw_num_0
		
	
	
	@@endProc:
	;show cursor
		mov ax, 1h
		int 33h
	mov [sign_or_num], 0
	popa
	ret
endp

proc draw_1
	pusha
		mov [color], 32
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [x_temp], 3
		mov ax, [y_coordinate]
		mov [y_temp], ax
		add [y_temp], 3
		
		call draw_pixel
		add [y_temp], 3
		call draw_pixel
		
		add [y_coordinate], 2
		inc [x_temp]
		mov [lenY], 5
		call draw_row
		
		inc [x_temp]
		dec [y_temp]
		call draw_pixel
		
		;מחזיר למיקום ההתחלתי
		sub [y_coordinate], 2
	popa
	ret
endp draw_1

proc draw_2
	pusha
		mov [color], 2
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		mov [lenX], 5
		mov cx, 3
		@@threeLines:
			add [y_temp], 2
			call draw_line
			loop @@threeLines
		dec [x_temp]
		sub [y_temp], 3
		call draw_pixel
		add [y_temp], 2
		sub [x_temp], 4
		call draw_pixel
		
		sub [x_coordinate], 2
	popa
	ret
endp draw_2

proc draw_3
	pusha
		mov [color], 4
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		mov [lenX], 4
		add [y_temp], 2
		call draw_line
		add [y_temp], 4
		call draw_line
		inc [x_coordinate]
		dec [lenX]
		sub [y_temp], 2
		call draw_line
		
		add [y_coordinate], 2
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [x_temp] , 3
		mov [lenY], 5
		call draw_row
		
		sub [x_coordinate], 3
		sub [y_coordinate], 2
	popa
	ret
endp draw_3

proc draw_4
	pusha
		mov [color], 1
		add [y_coordinate], 2
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [x_temp], 5
		mov [lenY], 6
		call draw_row
		
		sub [x_temp], 3
		mov [lenY], 3
		call draw_row
		
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		add [y_temp], 3
		mov [lenX], 5
		call draw_line
		
		sub [x_coordinate], 2
		sub [y_coordinate], 2
	popa
	ret
endp draw_4

proc draw_5
	pusha
		mov [color], 6
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		mov [lenX], 5
		mov cx, 3
		@@threeLines:
			add [y_temp], 2
			call draw_line
			loop @@threeLines
		sub [x_temp], 5
		sub [y_temp], 3
		call draw_pixel
		add [y_temp], 2
		add [x_temp], 4
		call draw_pixel
		
		sub [x_coordinate], 2
	popa
	ret
endp draw_5

proc draw_6
	pusha
		mov [color], 3
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		mov [lenX], 5
		mov cx, 3
		@@threeLines:
			add [y_temp], 2
			call draw_line
			loop @@threeLines
		sub [x_temp], 5
		sub [y_temp], 3
		call draw_pixel
		add [y_temp], 2
		add [x_temp], 4
		call draw_pixel
		sub [x_temp], 4
		call draw_pixel
		
		sub [x_coordinate], 2
	popa
	ret
endp draw_6

proc draw_7
	pusha
		mov [color], 0
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		add [y_temp], 2
		mov [lenX], 4
		call draw_line
		
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [x_temp], 4
		add [y_coordinate], 2
		mov [lenY], 3
		call draw_row
		dec [x_temp]
		add [y_coordinate], 2
		mov [lenY], 2
		call draw_row
		dec [x_temp]
		inc [y_coordinate]
		mov [lenY], 3
		call draw_row
		
		sub [x_coordinate], 2
		sub [y_coordinate], 5
	popa
	ret
endp draw_7

proc draw_8
	pusha
		mov [color], 23 ;אפור
		add [x_coordinate], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		mov [lenX], 5
		mov cx, 3
		@@threeLines:
			add [y_temp], 2
			call draw_line
			loop @@threeLines
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [y_coordinate], 2
		mov [lenY], 4
		call draw_row
		add [x_temp], 4
		call draw_row
		
		sub [x_coordinate], 2
		sub [y_coordinate], 2
	popa
	ret
endp draw_8

proc draw_mine
	pusha
		mov [color], 0
		mov bl, 1
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [x_temp], 2
		mov ax, [y_coordinate]
		mov [y_temp], ax
		add [y_temp], 2
		@@three_lines:
			mov bh, 1
			@@one_line:
				call draw_pixel
				add [x_temp], 2
				inc bh
			cmp bh, 3
			jbe @@one_line
			sub [x_temp], 6
			add [y_temp], 2
			inc bl
		cmp bl, 3
		jbe @@three_lines
		add [x_coordinate], 3
		add [y_coordinate], 3
		mov [lenX], 3
		mov [lenY], 3
		call draw_rect
		
		sub [x_coordinate], 3
		sub [y_coordinate], 3
	popa
	ret
endp draw_mine

proc draw_flag
	pusha
		mov [color], 0	;שחור
		add [x_coordinate], 3
		mov ax, [y_coordinate]
		mov [y_temp], ax
		add [y_temp], 6
		mov [lenX], 3
		call draw_line
		inc [y_temp]
		dec [x_coordinate]
		mov [lenX], 5
		call draw_line
		
		mov [color], 4	;אדום
		mov [lenY], 1
		mov ax, [x_coordinate]
		mov [x_temp], ax
		add [y_coordinate], 3
		mov cx, 3
		@@loop1:
			call draw_row
			inc [x_temp]
			add [lenY], 2
			dec [y_coordinate]
			loop @@loop1
		sub [x_coordinate], 2
	popa
	ret
endp draw_flag

proc draw_hidden
	pusha
		mov [color], 27	;ר' שמאל למעלה
		mov [lenX], 6
		mov ax, [y_coordinate]
		mov [y_temp], ax
		inc [y_temp]
		inc [x_coordinate]
		call draw_line
		mov ax, [x_coordinate]
		mov [x_temp], ax
		inc [y_coordinate]
		mov [lenY], 6
		call draw_row
		
		mov [color], 25	;2 נקודות בפינות
		call draw_pixel
		sub [y_temp], 6
		add [x_temp], 6
		call draw_pixel
		
		mov [color], 22	;נקודה ימין למטה
		add [y_temp], 6
		call draw_pixel
		
		mov [color], 24	;טור ימני ושורה תחתונה
		mov [lenY], 5
		inc [y_coordinate]
		call draw_row
		inc [x_coordinate]
		mov [lenX], 5
		call draw_line
		
		sub [x_coordinate], 2
		sub [y_coordinate], 2
		

	popa
	ret
endp draw_hidden

proc draw_num_9
pusha
	mov [color], 6
	add [x_coordinate], 2
	mov ax, [y_coordinate]
	mov [y_temp], ax
	mov [lenX], 5
	mov cx, 3
	@@threeLines:
		add [y_temp], 2
		call draw_line
		loop @@threeLines
	mov ax, [x_coordinate]
	mov [x_temp], ax
	add [y_coordinate], 2
	mov [lenY], 2
	call draw_row
	add [lenY], 2
	add [x_temp], 4
	call draw_row
	
	sub [x_coordinate], 2
	sub [y_coordinate], 2
popa
ret
endp draw_num_9

proc draw_num_0
pusha
	mov [color], 23 ;אפור
	add [x_coordinate], 2
	mov ax, [y_coordinate]
	mov [y_temp], ax
	sub [y_temp], 2
	mov [lenX], 5
	mov cx, 2
	@@twoLines:
		add [y_temp], 4
		call draw_line
		loop @@twoLines
	mov ax, [x_coordinate]
	mov [x_temp], ax
	add [y_coordinate], 2
	mov [lenY], 4
	call draw_row
	add [x_temp], 4
	call draw_row
	
	sub [x_coordinate], 2
	sub [y_coordinate], 2
popa
ret
endp draw_num_0

; PROC : draw_pixel: draws 1 pixel
; IN : [x_temp], [y_temp], [color]
; OUT: draws a pixel
; AFFECTED REGISTERS : None (pusha and popa)
proc draw_pixel
	pusha
	xor bh, bh ; bh = 0
	mov cx, [x_temp]
	mov dx, [y_temp]
	mov ax, [color]
	mov ah, 0ch
	int 10h
	popa
	ret
endp draw_pixel

; PROC : draw_line: draws 1 line
; IN : [x_coordinate], [y_temp](needed for draw_pixel that draw_line calls to), [color], [len]
; OUT: draws a line
; AFFECTED REGISTERS : None (pusha and popa)
proc draw_line
	pusha
	; move x_coordinate to x_temp
	mov ax, [x_coordinate]
	mov [x_temp], ax
	mov cx, [lenX]
draw:
	call draw_pixel
	inc [x_temp]
	loop draw
	popa
	ret
endp draw_line

; PROC : draw_row: draws 1 line
; IN : [y_coordinate], [x_temp](needed for draw_pixel that draw_line calls to), [color], [len]
; OUT: draws a line
; AFFECTED REGISTERS : None (pusha and popa)
proc draw_row
	pusha
	; move x_coordinate to x_temp
	mov ax, [y_coordinate]
	mov [y_temp], ax
	mov cx, [leny]
@@draw:
	call draw_pixel
	inc [y_temp]
	loop @@draw
	popa
	ret
endp draw_row

; PROC : draw_rect: draws 1 rectangle
; IN : [x_coordinate], [y_coordinate], [color], [lenX], [lenY]
; OUT: draws a rectangle
; AFFECTED REGISTERS : None (pusha and popa)
proc draw_rect
	pusha
	mov ax, [y_coordinate]
	mov [y_temp], ax
	mov cx, [lenY] 
@@rect:
	call draw_line
	inc [y_temp] ;column
	loop @@rect
	popa
	ret
endp draw_rect