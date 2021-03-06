	AREA    lib, CODE, READWRITE
	EXPORT output_string
	EXPORT read_string
	EXPORT display_digit
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	EXPORT write_character
	EXPORT read_character
	EXPORT clear_display

	EXPORT newline
	EXPORT store_string

Base EQU 0x40000000

newline = "\n"
	ALIGN
		
store_string = "                                "
    ALIGN

digits_SET	
		DCD 0x00001F80 ; 0
        DCD 0x00000300 ; 1 
        DCD 0x00002d80 ; 2
        DCD 0x00002780 ; 3
        DCD 0x00003300 ; 4
        DCD 0x00003680 ; 5
        DCD 0x00003e80 ; 6
        DCD 0x00000380 ; 7
        DCD 0x00003f80 ; 8
        DCD 0x00003780 ; 9
        DCD 0x00003b80 ; A
        DCD 0x00003e00 ; b
        DCD 0x00001c80 ; C
        DCD 0x00002f00 ; d
        DCD 0x00003c80 ; E
        DCD 0x00003880 ; F

	ALIGN	


uart_init										
	STMFD SP!, {R4 - R5, lr}
   	ldr r4, =0xE000C00C
   	MOV r5, #131
   	STRB r5, [r4]

   	ldr r4, =0xE000C000
   	MOV r5, #120
   	STRB r5, [r4]
						   
   	ldr r4, =0xE000C004
   	MOV r5, #0
   	STRB r5, [r4]   

	ldr r4, =0xE000C00C
   	MOV r5, #3
   	STRB r5, [r4]
 	LDMFD SP!, {R4 - R5, lr}
	BX lr


directory
	STMFD SP!, {R4 - R5, lr}
	LDR r4, =store_string
	LDRB r0, [r4]

	CMP r0, #49
	BNE first
	BL 	display_digit

first	
	CMP r0, #50 ;checks to see if r0 is 2
	BNE second
	BL read_push_btns

second	
	CMP r0, #51 ;checks to see if r0 is 3
	BNE third
	BL LEDs

third	
	CMP r0, #52 ;checks to see if r0 is 4
	BNE fourth
	BL RBG_LED

fourth 	
	CMP r0, #53
	BNE endf
	;BL gain_super_powers
		
endf	
	LDMFD SP!, {R4 - R5, lr}
	BX LR
	
	
	;saves string to store_string
read_string    
    STMFD SP!, {r0 - r1, lr}                 
    LDR r1, =store_string  ;account for prompt
read_string_loop        
    bl read_character ;reads character
    CMP r0, #13 ;checks for enter button
	
	;store and loop if not enter
    strbne r0, [r1], #1 ;stores the character at the address
    bne read_string_loop
	
	;must be enter
	MOV r0, #0 ;puts last character at address to 0 so easier to find
	strb r0, [r1], #1 ;stores the 0
	LDMFD SP!, {r0 - r1, lr}     
    bx lr  
	
	
;outputs characters from string at r4 untill null termination	
output_string
    STMFD SP!, {R0 - R3, R5 - R12, lr}
loop    
	LDRB r0, [r4], #1
    BL write_character
    CMP r0, #0
    BNE loop ;output_string
    LDMFD SP!, {R0 - R3, R5 - R12, lr}
    BX LR


;reads character to r0
read_character 
    STMFD SP!, {R1 - R3, lr}    ; Store register lr on stack
tloop    
	LDR r1, =0xE000C014
    LDR r2, [r1]
    AND r3, r2, #1
    CMP r3, #0
    BEQ tloop
    
	LDR r1, =0xE000C000
    LDRB r0, [r1]
    BL write_character

    LDMFD SP!, {R1 - R3, lr}
    BX LR


;prints r0 to display
write_character
    STMFD SP!, {R1 - R3, lr}
wloop    
	LDR r1, =0xE000C014
    LDR r2, [r1]
    AND r3, r2, #32
    CMP r3, #0
    BEQ wloop
	
    LDR r1, =0xE000C000
    STRB r0 , [r1]
    LDMFD SP!, {R1 - R3, lr}
    BX LR    


read_push_btns
	STMFD SP!, {R1-R12, lr}

stag1		
	LDR r4, =0xE0028018	 ; bit set
	MOV r0, #0x00000000
	STR r0, [r4]
			
	LDR r4, =0xE002801C	 ; bit clear
	MOV r0,	#0x00F00000
	STR r0, [r4]
				
	LDR r4, =0xE0028010 ;loads intput register address
	LDR r0, [r4]; reads what was entered 
	mvn r2, r0
	and r2, r2, #0x00F00000			
			;CMP r0, r2 ; if not changed read again
			
			;beq tagain1 		
	mov r0, r2
	lsr r0, r0, #20
	mov r1,r0
	MOV r8, #0
	and r7, r1, #8
	CMP r7, #8
	addeq r8, r8, #1
			
	and r7, r1, #4
	CMP r7, #4
	addeq r8, r8, #2

	and r7, r1, #2
	CMP r7, #2
	addeq r8, r8, #4

	and r7, r1, #1
	CMP r7, #1
	addeq r8, r8, #8	

	add r0, r8, #48
	cmp r0, #57
	addgt r0, r0, #7

	BL write_character ;if there is a bit equal print one
	add r0, r0, #0			
	
	b stag1
			
quit1	
	LDMFD SP!, {R1-R12, lr}
	BX LR
	
	

LEDs
	STMFD SP!, {r0 - r1, r4, r7 - r8, lr}
			
stag2		
	LDR r4,=newline ;add a new line
	BL output_string 
	BL read_string ;write number			
	LDR r4, =store_string ;load number			
	LDRB r0, [r4]			
	CMP r0, #0x71 ;check if equal to q			
	BEQ quit2;quit			
	CMP r0, #0x51 ;check if equal to Q			
	BEQ quit2;quit	
led1	
led2		
	LDR r4, =store_string;load value
	mov r1, #0

led3		
	ldrb r0, [r4],#1 
	cmp r0, #0
	beq led4
	mov r7, #10; stores the value ten in a register
	;character must be a number
	sub r0, r0, #48 ; convert to int
	mul r1, r7, r1 ;multiplies number holder by ten
	add r1, r1, r0
	b led3
			
led4		
	MOV r8, #0
	and r7, r1, #8
	CMP r7, #8
	addeq r8, r8, #1
			
	and r7, r1, #4
	CMP r7, #4
	addeq r8, r8, #2

	and r7, r1, #2
	CMP r7, #2
	addeq r8, r8, #4

	and r7, r1, #1
	CMP r7, #1
	addeq r8, r8, #8
			
	MOV r1, r8
	MVN r1, r1, LSL #16 ;shifts value to store_string in board
			
	LDR r4, =0xE002801C  ;load clear for uart
			
	MOV r0, #0x00FF0000 ;value to cleas
			
	STR r0, [r4] ;clear
			
	MOV r0, #0x000F0000 ;value that you write to			
	LDR r4, =0xE0028018 ;setter to write(make it an output)			
	STR r0, [r4];make output						
	LDR r4, =0xE0028014 ;load output uart			
	STR r1, [r4] ;store value writen
			
	B stag2 ;go back
quit2		
	LDMFD SP!, {R1-R12, lr}
	BX LR



RBG_LED
	STMFD SP!, {R1-R12, lr}
	
stag3		
	LDR r4, =newline ;newline			
	BL output_string ;print new line			
	BL read_string ;write to terminal			
	LDR r4, =store_string ;read what was writen			
	LDRB r0, [r4] ;load what was writen			
	CMP r0, #0x71 ;checks if q			
	BEQ quit3; if q exit		
	CMP r0, #0x51 ;checks if Q			
	BEQ quit3; if Q exit			
			
	LDR r4, =0xE0028008;load what depends to write or read			
	MOV r1, #0x00260000;load value to clear/whats writen to			
	STR r1, [r4];clear original			
	LDR r4, =0xE002800C;load clear		
	STR r1, [r4];store to write to uart			
	LDR r4, =store_string ;load what was writen			
	LDRB r0, [r4] ;store in r0	
	LDR r4, =0xE0028004 ;load where to write in uart
			
	CMP r0, #119; w in Ascii		
	BNE nwhite ;if not white			
	MOV r1, #0x00000000 ;white			
	STR r1, [r4];print white

nwhite		
	CMP r0, #121;y in Ascii			
	BNE nyellow; if not yellow			
	MOV r1, #0x00040000 ;yellow			
	STR r1, [r4];print yellow

nyellow		
	CMP r0, #112;p in Ascii			
	BNE npurple; if not purple			
	MOV r1, #0x00200000 ;purple
	STR r1, [r4];print purple

npurple		
	CMP r0, #98;b in Ascii			
	BNE nblue; if not blue			
	MOV r1, #0x00220000 ;blue			
	STR r1, [r4];print blue
			
nblue		
	CMP r0, #103;g in Ascii 
	BNE ngreen;if not green
	MOV r1, #0x00060000 ;green
	STR r1, [r4];print green

ngreen		
	CMP r0, #114;r in Ascii			
	BNE stag3 ;go to the begining			
	MOV r1, #0x00240000 ;red			
	STR r1, [r4];print red			
	B stag3;go again
			
quit3	
	LDMFD SP!, {R1-R12, lr}
	BX LR


clear_display
    STMFD SP!, {R0 - R9, r11, r12, lr}
	LDR r4, =0xE0028008
	MOV r1, #0x00003f80;load value to clear/whats writen to
	STR r1, [r4];clear original	
	LDR r4, =0xE002800C;load clear
	STR r1, [r4];
    LDMFD SP!, {R0 - R9, r11, r12, lr}
    BX LR


display_digit
	STMFD SP!, {R1-R9, r11, r12, lr}
	
	ldr r4, =0xE0028000 ; base address
	
	MOV r1, #0x00003f80;load value to clear/whats writen to
	STR r1, [r4, #0xC] ; IOCLR
	
	LDR r3, =digits_SET
	MOV r0, r0, LSL #2 ; multiply by 4
	LDR r2, [r3, r0]
	STR r2, [r4, #4] ; store to IOSET

	LDMFD SP!, {r1 - r4, lr}
	BX LR
	

pin_connect_block_setup_for_uart0
    STMFD sp!, {r0, r1, lr}
    LDR r0, =0xE002C000  ; PINSEL0
    LDR r1, [r0]
    ORR r1, r1, #5
    BIC r1, r1, #0xA
    STR r1, [r0]
    LDMFD sp!, {r0, r1, lr}
    BX lr

	END