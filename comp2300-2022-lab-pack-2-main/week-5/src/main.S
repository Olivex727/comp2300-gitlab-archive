.syntax unified
.global main

.type main, %function
main:
  ldr r12, =0b0000100010001000100010001
  bl image
.size main, .-main

@ Board Encoding (First 25 bits):
@ C/R  1  2  3  4  5
@   .---------------
@ 1 | 01 06 11 16 21
@ 2 | 02 07 12 17 22
@ 3 | 03 08 13 18 23
@ 4 | 04 09 14 19 24
@ 5 | 05 10 15 20 25

@ Uses r12 as board state
@ r11 is counter register
@ r10 is current column
@ r9 in the specific row arrangement on each column
@ r8 is the current row
image:
  ldr r11, =0x00800000 @ < 2 seconds
  mov r10, 0

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
  add r10, 1
  mov r5, r10
  bl setup
  cmp r10, 5
  beq image_exit
  b image_loop

image_exit:
  subs r11, 1
  beq loop
  b image

@ Set the light board up for inputs (Turn on all row DIRs, a specificed column DIR)
@ r4 is the column
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

loop:
  nop
  b loop

.data
row_map:
  .byte 21
  .byte 22
  .byte 15
  .byte 24
  .byte 19

.data
col_map:
  .byte 28
  .byte 11
  .byte 31
  .byte 5 @ ON PIN 1
  .byte 30