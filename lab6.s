	AREA interrupts, CODE, READWRITE
	IMPORT uart_init
	IMPORT output_string
	IMPORT read_string
	IMPORT write_character
	IMPORT read_character
		
	IMPORT newline
		
	EXPORT FIQ_Handler
	EXPORT lab6
	IMPORT store_string
		
BASE EQU 0x40000000
	
prompt = "Welcome to lab #6",10
	ALIGN
the_board = "|---------------|\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|       *       |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|---------------|"
	ALIGN	

lab6
	stmfd sp!, {r4 - r12, lr}
	
	bl uart_init	
	
;loop
;	ldr r4, =the_board
;	bl output_string
;	bl read_string
;	ldr r4, =store_string
;	bl output_string
;	ldr r4, =newline
;	bl output_string
;	;mov r0, #0
;	;bl write_character
	
;	b loop	

	ldmfd sp!, {r4 - r12, lr}
	bx lr
	
		
interrupt_init
	stmfd sp!, {r4 - r12, lr}
	
	ldr r4, =0xFFFFF010 ;interrupt enable register	(VICIntEnable)
	ldr r5, [r4]
	orr r5, r5, #0x30		;enable bits 4 and 5 for timers 0 & 1
	orr r5, r5, #0x40		;enable bit 6 for uart0 interrupt
	str r5, [r4]	;store back to enable register
	
	ldr r4, =0xFFFFF00C ; intterupt select register (VICIntSelect)
	ldr r5, [r4]
	orr r5, r5, #0x30		;enable bits 4 and 5 for fast interrupts
	orr r5, r5, #0x40		;enable bit 6 for fast interrupt
	str r5, [r4]	;store back to select register

	ldr r4, =0xE000C004	;enable uart interrupt read_data_available
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]
	
	MRS r0, CPSR	; Enable FIQ's, Disable IRQ's
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0


	ldmfd sp!, {r4 - r12, lr}
	bx lr
		
		
		
FIQ_Handler		
	ldmfd sp!, {r0 - r1, lr}	
read_data_interrupt
	LDR r0, =0xE000C008
	LDR r1, [r0]
	and r1, r1, #1	;interrupt identification
	cmp r1, #1		;set to 1 if no pending interrupts
	beq FIQ_Exit
				
	bl data_available_handler

FIQ_Exit
	LDMFD SP!, {r0 - r1, lr}
	SUBS pc, lr, #4
		
		
		
data_available_handler
	STMFD SP!, {r0, r4, lr}
	
	BL read_character

		CMP r0, #105 ; input i - move up
		BEQ move_up

		CMP r0, #106	; input j - move left
		BEQ move_left

		CMP r0, #107	; input k - move right
		BEQ move_right

		CMP r0, #109	; input m - move down
		BEQ move_right

		ldr r4, =newline
		bl output_string
		
		B read_data_handler_exit

move_up
	stmfd sp!, {r0 - r3}
	
	;move up algorithm
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	   
move_left
	stmfd sp!, {r0 - r3}
	
	;move left algorithm
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
move_right
	stmfd sp!, {r0 - r3}
	
	;move right algorithm
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
move_down
	stmfd sp!, {r0 - r3}
	
	;move down algorithm 
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
read_data_handler_exit
    LDMFD SP!, {r0, r4, lr}
    BX LR
	
		
	end