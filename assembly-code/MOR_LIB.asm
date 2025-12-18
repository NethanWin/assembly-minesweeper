;  MOR_LIB  -  written by Oren Gross
;

Clock  	  equ es:6Ch ; BIOS 55 msec ticks counter

DATASEG 
msg_MOR_LIB db    ' MOR LIB '
MOR_lastrand    dw    0 ; needed for randomizing
	;filename db 'test.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error in opening file :', 13, 10,'1) Check if file exist', 13, 10,'2) Check if its name is correct.', 13, 10,'$'


CODESEG

Proc MOR_SLEEP
;DO : sleep and return after AX mili second
;IN  : AX - unsigned - hold delay time in msec   ( accuracy is +- 55 msec )
;OUT : NONE

	; STORE
	push ax
    push cx
    push dx
	push es

;	mov ax,dx
;	mov dl,55
;	div dl   ;	DIV BYTE :  AL = AX / operand  , AH = remainder (modulus) 

	; calc dx:ax / 55 
	mov dx,0  ; AX - already holds the msec as a parameter
	mov cx , 55
	div cx   ;DIV  word: AX = (DX AX) / operand ,DX = remainder (modulus) 
	
	cmp ax,0
	je @@Finish ; no delay needed
	mov cx, ax  
	
	; the delay : based on gvahim asm book chap. 13
	; wait for first change in timer 
	mov  ax, 40h 
	mov  es, ax 
	mov  ax, [Clock] 
	FirstTick:  
	cmp  ax, [Clock] 
	je  FirstTick 
	

	; count CX ticks 
@@DelayLoop: 
	mov  ax, [Clock] 
	Tick: 
	cmp  ax, [Clock] 
	je  Tick 

	loop  @@DelayLoop 

@@Finish:	
	; RESTORE
	pop es 
	pop dx
	pop cx
	pop ax
	ret 
endp MOR_SLEEP	

Proc MOR_GET_KEY  
;DO :  get key from Type Ahead Buffer (TAB)
;IN  : NONE
;OUT :  ZF - FALSE (0) when key exist  AL - ASCII  AH - scan code

	; check if key pressed
	mov ah, 1   
	Int 16h   ; ret ZF=FALSE when key exi
	jnz  @@key_exist
    ret   ; with ZF = TRUE
	
@@key_exist:
	
	; pop the key from the buffer
	mov  ah, 0  
	int  16h  ; read key : ah := scan code  al = ascii

	ret 

endp MOR_GET_KEY


;
; random - pseudo generate random number
;
; Register Arguments:
;    None.
;
; Returns:
;    ax - random number.
;
codeseg
proc    MOR_RAND_BASIC
    push   dx
    push   bx
    mov    bx, [MOR_lastrand]
    mov    ax, bx
    mov    dx, 401  ; RANDPRIME
    mul    dx
    mov    dx, ax
    call   MOR_55_MSEC_TICKS
    xor    ax, dx
    xchg   dh, dl
    xor    ax, dx
    xchg   bh, bl
    xor    ax, bx
    mov    [MOR_lastrand], ax
    pop    bx
    pop    dx
    ret
endp MOR_RAND_BASIC

;
; rand_max - pseudo generate random number in a range
;
; Register Arguments:
;    ax - the range : 0 till ax-1
;
; Returns:
;    ax - the random number whtin the range 
;
proc    MOR_RANDOM
    push   dx
    push   bx

	mov bx,ax ; store max
	call MOR_RAND_BASIC ; -> ax
	xor dx,dx
	div bx
	mov ax,dx	; the reminder [0..max]
	
    pop    bx
    pop    dx
    ret
endp MOR_RANDOM



;
; timeticks - get time ticks from bios data segment.
;
; Register Arguments:
;    None.
;
; Returns:
;    ax - current ticks
;

proc    MOR_55_MSEC_TICKS
    push es
	mov  ax, 40h   ; clock is at 40:6c
	mov  es, ax 
	mov  ax, [Clock] 
    pop  es
    ret
endp  MOR_55_MSEC_TICKS



;---------------------------------------------------
;  MOR_PRINT_NUM - 
;         Prints a number in base 10 
;
;         IN: AX - Number
;             
;
;        OUT: None
;---------------------------------------------------
proc MOR_PRINT_NUM
	push   ax
	push   bx
    push   cx
    push   dx


    mov  cx, 0
	mov  bx,10 ; BASE

@@DIGIT_LOOP:
    mov  dx, 0
    div  bx  ; DX:AX / BX = AX and Remainder: DX
 
    push dx
    inc  cx

    cmp  ax, 0
    jne  @@DIGIT_LOOP

@@PRINT:
    pop  dx
	add dl,'0'
	mov ah,2
	int 21h

    loop @@PRINT


	pop   dx
	pop   cx
    pop   bx
    pop   ax
    ret

endp MOR_PRINT_NUM
 

proc MOR_LOAD_BMP
; load a BMP picture from a file
; in DX - offset of file name
; out - if loading fails an error message is printed on the screen
; effected register - FLAGS ONLY 

; Process BMP file
push ax
push bx
push cx
push dx
push si
push di

	call OpenFile
	jc return1 ; error 
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFile

return1:
pop di
pop si
pop dx
pop cx
pop bx
pop ax

ret 
endp MOR_LOAD_BMP




proc OpenFile
; in DX - offset of file name
; out - CF = TRUE if error 
; out - [filehandle]

; Open file
	
	mov ah, 3Dh
	xor al, al
	;mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax

	
ret
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	; Wait for key press
	mov ah,8
	int 21h
	 
ret
endp OpenFile

proc ReadHeader
; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
ret
endp ReadHeader

proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
ret
endp ReadPalette

proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
; Copy starting color to port 3C8h
	out dx,al
; Copy palette itself to port 3C9h
	inc dx
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] ; Get red value.
	shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
	out dx,al ; Send it.
	mov al,[si+1] ; Get green value.
	shr al,2
	out dx,al ; Send it.
	mov al,[si] ; Get blue value.
	shr al,2
	out dx,al ; Send it.
	add si,4 ; Point to next color.
	loop PalLoop
ret
endp CopyPal

proc CopyBitmap
; BMP graphics are saved upside-down.
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
PrintBMPLoop:
	push cx
; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,320
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code:
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
 ;loop until cx=0
	pop cx
	loop PrintBMPLoop
ret
endp CopyBitmap

proc CloseFile
	
	mov ah, 3Eh
	MOV BX,[filehandle]
	xor al, al
	;mov dx, offset filename
	int 21h
ret
endp CloseFile


