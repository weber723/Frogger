; Lab 7 changes: Fly only appears on the 'home' spots (between the asterix)
; FOUR frogs must make it to the end instead of 2
; Items now move every 1 second (Changed timer interval)
; The frog AND CAR moves twice as fast as other objects
; Board should be 45x14 not including border
; If timer ends during level, it's game over
; Pause screen should state that it is paused AND how to resume the game
; Score, level and time should be displayed at all times
; With each level increase the interval is decreased by .05 seconds
; DUE May 3rd, 10 extra points for April 26th, 20 points for April 19th
	.data
board0:  .string "|---------------------------------------------|", 0xD, 0xA
board1:  .string "|*********************************************|", 0xD, 0xA
board2:  .string "|*****     *****     *****     *****     *****|", 0xD, 0xA
board3:  .string "|                                             |", 0xD, 0xA
board4:  .string "|                                             |", 0xD, 0xA
board5:  .string "|                                             |", 0xD, 0xA
board6:  .string "|                                             |", 0xD, 0xA
board7:  .string "|.............................................|", 0xD, 0xA
board8:  .string "|                                             |", 0xD, 0xA
board9:  .string "|                                             |", 0xD, 0xA
board10: .string "|                                             |", 0xD, 0xA
board11: .string "|                                             |", 0xD, 0xA
board12: .string "|                                             |", 0xD, 0xA
board13: .string "|                                             |", 0xD, 0xA
board14: .string "|......................&......................|", 0xD, 0xA
board15: .string "|---------------------------------------------|", 0xD, 0xA, 0

values: .string ""

	.text
	.global lab7
	.global enable_interrupts
	.global Uart0Handler
	.global Timer0Handler
	.global PortAHandler
	.global output_string
	.global output_character
	.global int_string
	.global read_character
	.global read_from_keypad
	.global random
	.global div_and_mod
	.global uart_init

pointer_board: .word board0
pointer_b3: .word board3
pointer_b4: .word board4
pointer_b5: .word board5
pointer_b6: .word board6
pointer_b7: .word board7
pointer_b8: .word board8
pointer_b9: .word board9
pointer_b10: .word board10
pointer_b11: .word board11
pointer_b12: .word board12
pointer_b13: .word board13
pointer_b14: .word board14
pointer_b15: .word board15

pointer_values: .word values

direc: .equ 0x400
dig: .equ 0x51c
data: .equ 0x3fc

cur_pos: .equ 0x1	; Offset to store which character the frog is sitting on
mov_dir: .equ 0x2	; The last direction the frog took

lab7:
	STMFD sp!, {lr}

	LDR r10, pointer_values
	MOV r0, #0x2e
	STRB r0, [r10, #cur_pos]
	BL output_board

	LDR r4, pointer_b14
	ADD r4, r4, #23

	; Enable Timer
	LDRB r2, [r7, #0xc]
	ORR r2, r2, #0x1
	STRB r2, [r7, #0xc]

wait_to_start:
	;LDRB r0, [r10, #mov_dir]
	;CMP r0, #0
	;BEQ wait_to_start

start_game:
	;BL generate_obstacles
	;BL output_board
	;BL enable_interrupts

wait:
	BL enable_interrupts
	B wait

	LDMFD sp!, {lr}
	bx lr

output_board:
	STMFD sp!, {lr, r4}

	MOV r0, #0xc
	BL output_character
	LDR r4, pointer_board
	BL output_string

	LDMFD sp!, {lr, r4}
	bx lr

Uart0Handler:
	STMFD sp!, {lr}

	BL read_character
	STRB r0, [r10, #mov_dir]
	CMP r0, #0x77
	BEQ up
	CMP r0, #0x73
	BEQ down
	CMP r0, #0x61
	BEQ left
	CMP r0, #0x64
	BEQ right
	B return

up:
	SUB r5, r4, #49
	B check_for_wall
down:
	ADD r5, r4, #49
	B check_for_wall
left:
	SUB r5, r4, #1
	B check_for_wall
right:
	ADD r5, r4, #1

check_for_wall:
	LDRB r0, [r5]
	CMP r0, #0x7c 		; Compare to '|'
	BEQ return
	CMP r0, #0x2d		; Compare to '-'
	BEQ return

	LDRB r1, [r10, #cur_pos]		; Store previous character in spot
	STRB r1, [r4]

	STRB r0, [r10, #cur_pos]		; Store current character that the frog is sitting on into cur_pos

store_new_frog:
	MOV r4, r5			; Move frog to new position
	MOV r0, #0x26
	STRB r0, [r4]

	BL output_board

return:

	LDMFD sp!, {lr}
	bx lr

Timer0Handler:
	STMFD sp!, {lr, r4}

	LDRB r2, [r7, #0x24]	; Clear Timer interrupt
	ORR r2, r2, #0x1
	STRB r2, [r7, #0x24]

	; Disable Timer Interrupt (Bit 19 of EN0, or Bit 3 of address E102)
	MOV r1, #0xe182
	MOVT r1, #0xe000
	LDRB r2, [r1]
	ORR r2, r2, #0x8
	STRB r2, [r1]

	LDR r4, pointer_b3
	ADD r4, r4, #1
	BL mov_left

	LDR r4, pointer_b5
	SUB r4, r4, #4
	BL mov_right

	LDR r4, pointer_b5
	ADD r4, r4, #1
	BL mov_left

	LDR r4, pointer_b7
	SUB r4, r4, #4
	BL mov_right

	LDR r4, pointer_b14
	SUB r4, r4, #4
	;BL mov_right
	SUB r4, r4, #4
	;BL mov_right
	SUB r4, r4, #4
	;BL mov_right
	SUB r4, r4, #4
	;BL mov_right
	SUB r4, r4, #4
	;BL mov_right
	SUB r4, r4, #4
	;BL mov_right

	B done

mov_left:
	ADD r5, r4, #1
	LDRB r3, [r5]
	CMP r3, #0x7c
	BEQ stop_mov_left
	STRB r3, [r4], #1
	B mov_left
stop_mov_left:
	MOV r3, #0x20
	STRB r3, [r4]
	bx lr

mov_right:
	SUB r5, r4, #1
	LDRB r3, [r5]
	CMP r3, #0x7c
	BEQ stop_mov_right
	STRB r3, [r4], #-1
	B mov_right
stop_mov_right:
	MOV r3, #0x20
	STRB r3, [r4]
	bx lr

done:
	BL output_board
	LDMFD sp!, {lr, r4}
	bx lr

PortAHandler:
	STMFD sp!, {lr}
	BL read_from_keypad
	CMP r0, #0
	BEQ pause
	CMP r0, #1
	BEQ resume
	LDMFD sp!, {lr}
	bx lr

pause:

resume:

generate_obstacles:
	STMFD sp!, {lr, r4}

	LDR r4, pointer_b3
loop:
	ADD r4, r4, #1
	LDRB r0, [r4]
	CMP r0, #0x2d
	BEQ end_generation
	CMP r0, #0x20
	BEQ determine_num
	CMP r0, #0x2e
	BNE loop
	MOV r8, #1
	B loop

determine_num:
	MOV r3, #100
	BL random
	CMP r0, #10
	BGT loop

generate_object:
	MOV r6, #0				; Initialize counter
	CMP r8, #1
	BEQ land
water:
	MOV r3, #4
	BL random

	CMP r0, #0
	BEQ alligator
	CMP r0, #1
	BEQ lillypad
	CMP r0, #2
	BEQ log
	CMP r0, #3
	BEQ turtle

land:
	MOV r3, #2
	BL random
	CMP r0, #0
	BEQ car
	CMP r0, #1
	BEQ truck

alligator:
	MOV r0, #0x41
	STRB r0, [r4], #1
store_al:
	LDRB r0, [r4]
	CMP r0, #0x7c
	BEQ loop
	MOV r0, #0x61
	STRB r0, [r4], #1
	ADD r6, r6, #1
	CMP r6, #5
	BLT store_al
	B loop

lillypad:
	MOV r0, #0x4f
	STRB r0, [r4], #1
	B loop

log:
	LDRB r0, [r4]
	CMP r0, #0x7c
	BEQ loop
	MOV r0, #0x4c
	STRB r0, [r4], #1
	ADD r6, r6, #1
	CMP r6, #6
	BLT log
	B loop

turtle:
	MOV r0, #0x54
	STRB r0, [r4], #1
	LDRB r0, [r4]
	CMP r0, #0x7c
	BEQ loop
	MOV r0, #0x54
	STRB r0, [r4], #1
	B loop

car:
	MOV r0, #0x43
	STRB r0, [r4], #1
	B loop

truck:
	LDRB r0, [r4]
	CMP r0, #0x7c
	BEQ loop
	MOV r0, #0x23
	STRB r0, [r4], #1
	ADD r6, r6, #1
	CMP r6, #4
	BLT truck
	B loop

end_generation:
	LDMFD sp!, {lr, r4}
	bx lr

random:						; Creates random number. Takes in r3 as an argument for max number
	STMFD sp!, {lr}

	LDR r0, [r7, #0x50]
	BL div_and_mod
	MOV r0, r3

	LDMFD sp!, {lr}
	BX lr

uart_init:
	STMFD SP!,{lr}

	;Provide clock to UART0
	MOV r7, #0xE618
	MOVT r7, #0x400F
	MOV r2, #1
	STR r2, [r7]

    ;Enable clock to all Ports
    MOV r7, #0xE608
	MOVT r7, #0x400F
	LDR r2, [r7]
	ORR r2, r2, #0x2b
	STR r2, [r7]

    ;Disable UART0 Control
    MOV r7, #0xC030
	MOVT r7, #0x4000
	MOV r2, #1
	STR r2, [r7]

	; Set baud rate
    MOV r7, #0xC024
	MOVT r7, #0x4000
	MOV r2, #8
	STR r2, [r7]
    MOV r7, #0xC028
	MOVT r7, #0x4000
	MOV r2, #44
	STR r2, [r7]

    ;Use System Clock
    MOV r7, #0xCFC8
	MOVT r7, #0x4000
	MOV r2, #0
	STR r2, [r7]

    ;Use 8-bit word length, 1 stop bit, no parity
    MOV r7, #0xC02C
	MOVT r7, #0x4000
	MOV r2, #0x60
	STR r2, [r7]

    ;Enable UART0 Control
    MOV r7, #0xC030
	MOVT r7, #0x4000
	MOV r2, #0x301
	STR r2, [r7]

    ;Make PA0-1 as Digital Ports
    MOV r7, #0x451C
	MOVT r7, #0x4000
	LDR r2, [r7]
	ORR r2, r2, #0x3
	STR r2, [r7]

    ;Change PA0,PA1 to Use an Alternate Function
    MOV r7, #0x4420
	MOVT r7, #0x4000
	LDR r2, [r7]
	ORR r2, r2, #0x3
	STR r2, [r7]

    ;Configure PA0 and PA1 for UART
    MOV r7, #0x452C
	MOVT r7, #0x4000
	MOV r2, #0x11
	STR r2, [r7]

interrupt_init:
	; Set interrupt mask register to receive interrupts
	MOV r7, #0xC038
	MOVT r7, #0x4000
	LDRB r2, [r7]
	ORR r2, r2, #0x10
	STRB r2, [r7]
	; Connect clock to timer
	MOV r7, #0xe604
	MOVT r7, #0x400f
	LDRB r2, [r7]
	ORR r2, r2, #0x1
	STRB r2, [r7]
	; Disable Timer A
	MOV r7, #0x000c
	MOVT r7, #0x4003
	LDRB r2, [r7]
	AND r2, r2, #0xfe
	STRB r2, [r7]
	; Setup Timer for 32-bit mode
	SUB r7, r7, #0xc 	; Address = #0x40030000
	LDRB r2, [r7]
	AND r2, r2, #0xf8 	; b*****000
	STRB r2, [r7]
	; Put timer into periodic mode
	LDRB r2, [r7, #4]
	AND r2, r2, #0xf0
	ORR r2, r2, #2		; b******10
	STRB r2, [r7, #4]
	; Set interval to interrupt (16MHz clock = 4,000,000 cycles per 1/4 second = 0x3d0900)
	LDR r2, [r7, #0x28]
	MOV r2, #0x2400
	MOVT r2, #0xf4
	STR r2, [r7, #0x28]
	; Set timer to interrupt when top limit is reached
	LDRB r2, [r7, #0x18]
	ORR r2, r2, #0x1
	STRB r2, [r7, #0x18]

GPIO_init:

	; load port A address into r11
	MOV r11, #0x4000
	MOVT r11, #0x4000

	LDRB r2, [r11, #direc]	; Set direction and digital for port A
	AND r2, r2, #0xc3
	STRB r2, [r11, #direc]
	LDRB r2, [r11, #dig]
	ORR r2, r2, #0x3c
	STRB r2, [r11, #dig]

	LDRB r2, [r11, #0x404]	; Set to edge sensitive
	AND r2, r2, #0xc3
	STRB r2, [r11, #0x404]

	LDRB r2, [r11, #0x408]	; Allow GPIOEV register control pin
	AND r2, r2, #0xc3
	STRB r2, [r11, #0x408]

	LDRB r2, [r11, #0x40c]	; Set to react to rising edge
	ORR r2, r2, #0x3c
	STRB r2, [r11, #0x40c]

	LDRB r2, [r11, #0x410]	; Unmask (enable) interrupt
	ORR r2, r2, #0x3c
	STRB r2, [r11, #0x410]

	; load buttons port into r12
	MOV r12, #0x7000
	MOVT r12, #0x4000

	LDRB r2, [r12, #direc]
	ORR r2, r2, #0xf
	STRB r2, [r12, #direc]
	LDRB r2, [r12, #dig]
	ORR r2, r2, #0xf
	STRB r2, [r12, #dig]
	LDRB r2, [r12, #data]	; Set bit 0 to 1 to detect first row inputs
	ORR r2, r2, #0x1
	STRB r2, [r12, #data]

	BL lab7

	LDMFD sp!, {lr}
	BX lr

enable_interrupts:
	; Enable UART0 Interrupt (Bit 5 of EN0) and PortA Interrupt (Bit 0)
	MOV r1, #0xE100
	MOVT r1, #0xE000
	LDRB r2, [r1]
	ORR r2, r2, #0x21
	STRB r2, [r1]
	; Enable Timer Interrupt (Bit 19 of EN0, or Bit 3 of address E102)
	ADD r1, r1, #0x2
	LDRB r2, [r1]
	ORR r2, r2, #0x8
	STRB r2, [r1]

	BX lr


.end
