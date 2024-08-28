@ ASSIGNMENT 1 CODE - HAS BEEN MODIFIED
.syntax unified
.global display_main

@ --------------------- Display Entry Code (display_main is unused) -------------------- @

.type display_main, %function
display_main:
  push {lr}

  bl set_timer
  
  bl image
  
display_exit:
  bl clear_dir

  pop {lr}
  bx lr
.size display_main, .-display_main

@ New entry point into the display
.global display_entry
.type display_entry, %function
display_entry:
  push {lr, r4-r12}

  @ Pull the current state
  ldr r0, =current
  ldr r12, [r0]

  @ Clear current display
  bl clear_dir

  @ Get column number and store in r10
  ldr r0, =timer_counter
  ldr r10, [r0, 8]

  @ Run display on column number
  bl image

  @ Store an updated column number
  cmp r10, 4
  ite eq
  moveq r10, 0
  addne r10, 1

  ldr r0, =timer_counter
  str r10, [r0, 8]

  pop {lr, r4-r12}
  bx lr
.size display_entry, .-display_entry

@ display_main takes r12 as a parameter and will manipulate all registers for
@ output except for r12. Store all important program data onto the stack/SRAM
@ before activating the display module. Nothing from the display needs to be
@ stored in stack after it's execution.

@ Board Encoding (First 25 bits):
@ C/R  1  2  3  4  5
@   .---------------
@ 1 | 01 06 11 16 21
@ 2 | 02 07 12 17 22
@ 3 | 03 08 13 18 23
@ 4 | 04 09 14 19 24
@ 5 | 05 10 15 20 25

@ --------------------- Old Display Timer Code -------------------- @

@ Set the display time length
@ Uses r0, outputs to r11
set_timer:
  @ Grab timer bits from state
  ldr r0, =0b11
  lsl r0, 26
  and r0, r12
  lsr r0, 26

  @ Time values should be: 0.25, 0.5, 0.75, 1.00
  @ 0xa000 ~ 1 second
  @ 0x5000 ~ 0.5 seconds
  @ 0x2500 ~ 0.25 seconds
  add r0, 1
  ldr r11, =0x2500
  mul r11, r0

  bx lr

@ --------------------- Imaging -------------------- @

@ The image function is the main display function
@ Uses r12 as board state
@ r11 is counter register
@ r10 is current column
@ r9 in the specific row arrangement on each column
@ r8 is the current row
@ r7 is a spare register
image:
  push {lr}
  @mov r10, 0

image_loop:
  bl clear_dir

  @ Pull column out
  ldr r9, =0b11111
  mov r8, #5
  mul r8, r10, r8
  lsl r9, r8
  and r9, r12, r9
  lsr r9, r8

  @ Determine if specific row is on/off
  mov r8, 0
row_loop:
  mov r7, 0b1
  lsl r7, r8
  tst r9, r7
  beq row_loop_2

  @ Turn on the row current
  ldr r1, =0x50000000 @ Pin 0
  ldr r2, =0x504 @ OUT Offset
  ldr r3, =row_map
  ldr r3, [r3, r8]
  and r3, r3, 0xFF
  bl set_bit

row_loop_2:
  add r8, 1
  cmp r8, 5
  beq row_exit
  b row_loop

row_exit:
  @ ONLY loop through rows, as SysTick handles column looping
  add r10, 1
  mov r5, r10
  sub r10, 1
  bl setup @ Turn on column to let the LED turn on
  @cmp r10, 5
  @beq image_exit
  @b image_loop

image_exit:
  @subs r11, 1
  @beq display_exit
  @b image
  pop {lr}
  bx lr


@ Set the light board up for inputs (Turn on all row DIRs, a specificed column DIR)
@ r5 is the column
setup:
  push {lr}

  ldr r1, =0x50000000 @ Pin 0
  ldr r2, =0x514 @ DIR Offset

  @ ROW 1
  ldr r3, =#21
  bl set_bit

  @ ROW 2
  ldr r3, =#22
  bl set_bit
  
  @ ROW 3
  ldr r3, =#15
  bl set_bit

  @ ROW 4
  ldr r3, =#24
  bl set_bit

  @ ROW 5
  ldr r3, =#19
  bl set_bit

  @ COL 1
  cmp r5, 1
  bne n1
  ldr r3, =#28
  bl set_bit

n1:
  @ COL 2
  cmp r5, 2
  bne n2
  ldr r3, =#11
  bl set_bit

n2:
  @ COL 3
  cmp r5, 3
  bne n3
  ldr r3, =#31
  bl set_bit

n3:
  @ COL 5
  cmp r5, 5
  bne n5
  ldr r3, =#30
  bl set_bit
  
n5:
  @ COL 4
  cmp r5, 4
  bne n4
  ldr r1, =0x50000300 @ Pin 1
  ldr r3, =#5
  bl set_bit

n4:
  pop {lr}
  bx lr


@ Set bit
@ r0 = Output
@ r1 = Location
@ r2 = Offset
@ r3 = Bit position
set_bit:
  @ Load Memory information
  ldr r0, [r1, r2]

  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  mov r4, 0b1
  lsl r4, r4, r3
  orr r0, r0, r4

  @ store the modified result back into P0 OUT
  str r0, [r1, r2]

  bx lr

.global clear_dir
@ Clear (Turn off all lights)
clear_dir:
  push {lr}

  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ change offset to DIR
  ldr r2, =0x514
  bl clear_section
  @ change offset to OUT
  ldr r2, =0x504
  bl clear_section

  @ load r1 with the base address of P1
  ldr r1, =0x50000300

  @ change offset to DIR
  ldr r2, =0x514
  bl clear_section
  @ change offset to OUT
  ldr r2, =0x504
  bl clear_section

  pop {lr}
  bx lr

@ Clear bit
@ r1 = Location
@ r2 = Offset
clear_section:
  mov r0, 0

  @ store the modified result back into pin
  str r0, [r1, r2]

  bx lr

@ --------------------- Display Memory and Mapping -------------------- @

.data
row_map:
  .byte 21
  .byte 22
  .byte 15
  .byte 24
  .byte 19

.global timer_counter
timer_counter:
  @ Each light is displayed at 12.8 kHz (5000 cycles before turning back on)
  @ There are 64000 ticks in 1 second if the tick length is 1000
  @ Dynamic Counter, Static Counter, Column Counter
  .word 128000, 128000, 0
  @ UPDATE: Perhaps the maths was wrong, but the default tick count is now doubled