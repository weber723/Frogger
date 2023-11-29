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
board14: .string "|......................Q......................|", 0xD, 0xA
board15: .string "|---------------------------------------------|", 0xD, 0xA, 0

	.text
	.global lab7
	.global enable_interrupts
	.global Uart0Handler
	.global Timer0Handler
	.global PortAHandler
	.global output_string
	.global output_character
	.global output_board
	.global int_string
	.global read_character
	.global read_from_keypad
	.global div_and_mod
	.global generate_obst
	.global mod

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

cur_char: .equ 0x4		; Offset to store which character the frog is sitting on
mov_dir: .equ 0x5		; The last direction the frog took
in_water: .equ 0x6		; 1 if frog is on water part of board
rand_const: .equ 0x7 	;7-A, contains the timer value when the user last moved the frog
seed_arr_pos: .equ 0xB	; Position of the seed array
seed_array: .equ 0xC	; Contains different seeds for the rand function

lab7:
	STMFD sp!, {lr}

	MOV r10, #0x0450		; Base address = frog's current position
	MOVT r10, #0x2000
	MOV r0, #0x2e
	STRB r0, [r10, #cur_char]
	MOV r0, #0
	STRB r0, [r10, #in_water]
	BL output_board

	LDR r4, pointer_b14
	ADD r4, r4, #23
	STR r4, [r10]

	; Enable Timer
	LDRB r2, [r7, #0xc]
	ORR r2, r2, #0x1
	STRB r2, [r7, #0xc]

wait_to_start:
	BL read_character
	CMP r0, #0
	BEQ wait_to_start

	BL set_seed
	BL generate_obstacles
	BL output_board

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

new_line:
	STMFD sp!, {lr}
	MOV r0, #0xA
	BL output_character
	MOV r0, #0xD
	BL output_character
	LDMFD sp!, {lr}
	bx lr

Uart0Handler:
	STMFD sp!, {lr}
	BL set_seed

	LDR r4, [r10]
	MOVT r4, #0x0000
	CMP r4, #0x158				; Check current frog address
	BLT on_water				; If it is low enough, the frog is in the water
	MOV r0, #0
	STRB r0, [r10, #in_water]	; Change in_water constant to 0
cont_uart:
	MOVT r4, #0x2000
	MOV r1, #0xc000
	MOVT r1, #0x4000
	LDRB r0, [r1]
	CMP r0, #0x77
	BEQ up
	CMP r0, #0x73
	BEQ down
	CMP r0, #0x61
	BEQ left
	CMP r0, #0x64
	BEQ right
	B return

on_water:
	MOV r0, #1
	STRB r0, [r10, #in_water]	; Change in_water constant to 1
	B cont_uart

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

	LDRB r1, [r10, #cur_char]		; Store previous character in spot
	STRB r1, [r4]

	STRB r0, [r10, #cur_char]		; Store current character that the frog is sitting on into cur_char

store_new_frog:
	MOV r4, r5			; Move frog to new position
	MOV r0, #0x51
	STRB r0, [r4]
	STR r4, [r10]

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

	LDRB r0, [r10, #in_water]	; Check if frog is in the water
	CMP r0, #1
	BLNE pull_frog				; If he isn't then temporarily remove the frog

	LDR r5, pointer_b14			; Go through all proper addresses to move the lines to the right or left
	SUB r5, r5, #4
	BL mov_right

	SUB r5, r5, #5
	BL mov_right

	SUB r5, r5, #5
	BL mov_right

	SUB r5, r5, #5
	BL mov_right

	SUB r5, r5, #5
	BL mov_right

	SUB r5, r5, #5
	BL mov_right

	LDRB r0, [r10, #in_water]		; If frog was not in the water, put the frog back where it was
	CMP r0, #1
	BLNE replace_frog

	LDR r5, pointer_b3				; Moving lines again, except this time in water
	ADD r5, r5, #1
	BL mov_left

	LDR r5, pointer_b5
	SUB r5, r5, #4
	BL mov_right

	LDR r5, pointer_b5
	ADD r5, r5, #1
	BL mov_left

	LDR r5, pointer_b7
	SUB r5, r5, #4
	BL mov_right

	LDRB r6, [r10, #seed_arr_pos]		; Increase seed array position by 1
	ADD r6, r6, #1
	STRB r6, [r10, #seed_arr_pos]

	BL output_board
	LDMFD sp!, {lr, r4}
	bx lr

pull_frog:
	LDRB r0, [r10, #cur_char]	; Load in char that frog is 'sitting on'
	LDR r1, [r10]				; Load in address frog is at
	STRB r0, [r1]				; Temporarily remove frog from game board by replacing with other character
	bx lr

replace_frog:
	LDR r1, [r10]				; Load in frog's current position
	LDRB r0, [r1]				; Load in character in frog's position
	STRB r0, [r10, #cur_char]	; Move to 'current char' that the frog is sitting on
	MOV r0, #0x51
	STRB r0, [r1]				; Store frog back into spot
	bx lr

mov_left:
	ADD r6, r5, #1				; Grab character to the right
	LDRB r3, [r6]				; Load in value from next position
	CMP r3, #0x7c				; If we hit wall, stop
	BEQ stop_mov_left
	CMP r3, #0x51				; If we hit the frog, change the current frog position accordingly
	BNE str_right_value
	LDR r2, [r10]
	SUB r2, r2, #1
	STR r2, [r10]
str_right_value:
	STRB r3, [r5], #1			; Store value from next position into current position, then increment
	B mov_left				; Loop until all characters are moved to the left
stop_mov_left:
	STMFD sp!, {lr, r5}
	MOV r4, r5
	MOV r6, #0
	MOV r2, #-1					; Create constant r2, set to -1 since we are moving left
	ADD r5, r5, r2
	LDRB r3, [r5]
	CMP r3, #0x41
	BEQ cont_allig
	CMP r3, #0x61
	BEQ cont_allig
	CMP r3, #0x54
	BEQ cont_turtle
	CMP r3, #0x4c
	BEQ cont_log
	SUB r5, r5, r2
	MOV r3, #0x20
	STRB r3, [r5]
	BL random
	CMP r0, #10
	BLT new_object
	LDMFD sp!, {lr, r5}
	bx lr

mov_right:
	SUB r6, r5, #1				; Grab character to the left
	LDRB r3, [r6]				; Load in value from next position
	CMP r3, #0x7c				; If we hit a wall, stop
	BEQ stop_mov_right
	CMP r3, #0x51				; If we hit the frog, change the current frog position accordingly
	BNE str_left_value
	LDR r2, [r10]
	ADD r2, r2, #1
	STR r2, [r10]
str_left_value:
	STRB r3, [r5], #-1			; Store value from next position into current position, then decrement
	B mov_right					; Loop until all dcharacters are moved to the right
stop_mov_right:
	STMFD sp!, {lr, r5}
	MOV r4, r5					; Set r4 to be the last position in the line
	MOV r6, #0					; Set counter to 0
	MOV r2, #1					; Create constant r2, set to 1 since we are moving right
	ADD r5, r5, r2				; Go back one position to check if there is object to fill
	LDRB r3, [r5]
	CMP r3, #0x41				; Check every object option
	BEQ cont_allig
	CMP r3, #0x61
	BEQ cont_allig
	CMP r3, #0x54
	BEQ cont_turtle
	CMP r3, #0x4c
	BEQ cont_log
	CMP r3, #0x23
	BEQ cont_truck
	SUB r5, r5, r2
	BL random					; If there is no object to finish, randomly decide if new object should be placed
	CMP r0, #10
	BLT new_object
end_move:
	MOV r3, #0x20
	STRB r3, [r4]
	LDMFD sp!, {lr, r5}
	bx lr

cont_allig:
	ADD r6, r6, #1
	CMP r6, #5
	BGE end_move
	ADD r5, r5, r2
	LDRB r3, [r5]
	CMP r3, #0x61
	BEQ cont_allig

	MOV r3, #0x61
	STRB r3, [r4]

	LDMFD sp!, {lr, r5}
	bx lr				; Return from the move

cont_turtle:
	ADD r5, r5, r2
	LDRB r3, [r5]
	CMP r3, #0x54
	BEQ end_move

	MOV r3, #0x54
	STRB r3, [r4]

	LDMFD sp!, {lr, r5}
	bx lr

cont_log:
	ADD r6, r6, #1
	CMP r6, #5
	BGE end_move
	ADD r5, r5, r2
	LDRB r3, [r5]
	CMP r3, #0x4c
	BEQ cont_log

	MOV r3, #0x4c
	STRB r3, [r4]

	LDMFD sp!, {lr, r5}
	bx lr				; Return from the move

cont_truck:
	ADD r6, r6, #1
	CMP r6, #4
	BGE end_move
	ADD r5, r5, r2
	LDRB r3, [r5]
	CMP r3, #0x23
	BEQ cont_truck

	MOV r3, #0x23
	STRB r3, [r4]

	LDMFD sp!, {lr, r5}
	bx lr				; Return from the move

new_object:
	BL random
	LDR r1, pointer_b7
	CMP r5, r1
	BGT gen_land
gen_water:
	CMP r0, #20
	BLT gen_allig
	CMP r0, #40
	BLT gen_turtle
	CMP r0, #70
	BLT gen_log
	B gen_lilly

gen_land:
	CMP r0, #50
	BLT gen_car
	B gen_truck

gen_allig:
	MOV r0, #0x41
	STRB r0, [r5]
	B end_obj

gen_turtle:
	MOV r0, #0x54
	STRB r0, [r5]
	B end_obj

gen_log:
	MOV r0, #0x4c
	STRB r0, [r5]
	B end_obj

gen_lilly:
	MOV r0, #0x4f
	STRB r0, [r5]
	B end_obj

gen_car:
	MOV r0, #0x43
	STRb r0, [r5]
	B end_obj

gen_truck:
	MOV r0, #0x23
	STRB r0, [r5]

end_obj:
	LDMFD sp!, {lr, r5}
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
	MOV r8, #0
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
	BL random
	CMP r0, #15
	BGT loop

generate_object:
	MOV r6, #0				; Initialize counter
	CMP r8, #1
	BEQ land
water:
	BL random

	CMP r0, #20
	BLT alligator
	CMP r0, #45
	BLT log
	CMP r0, #70
	BLT turtle
	B lillypad

land:
	BL random
	CMP r0, #45
	BLT car
	B truck

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

set_seed:
	STMFD sp!, {r4-r6}
	MOV r6, #0x1050
	LDR r4, [r7, r6]
	STR r4, [r10, #rand_const]		; Get Timer 1 value and store into rand_const
	LDR r4, [r7, #0x50]				; Get Timer 0 value
	MOV r6, #seed_array
	STRB r6, [r10, #seed_arr_pos]
seed_arr:
	MOV r5, r4
	AND r5, r5, #0xf
	STRB r5, [r10, r6]
	LSR r4, #4
	ADD r6, r6, #1
	CMP r4, #0
	BNE seed_arr

	LDMFD sp!, {r4-r6}
	bx lr

random:							; Returns a pseudo random number in r0
	STMFD sp!, {lr, r1-r6}

	LDR r0, [r10, #rand_const]
	LDRB r6, [r10, #seed_arr_pos]
	LDRB r5, [r10, r6]

	MUL r0, r0, r5
	ADD r0, r0, r6

	MOV r5, r0
	MOV r1, #0x0000
	MOVT r1, #0x0100
	BL mod
	STR r0, [r10, #rand_const]

	MOV r0, r5
	MOV r1, #100
	BL mod

	LDMFD sp!, {lr, r1-r6}
	bx lr

.end
