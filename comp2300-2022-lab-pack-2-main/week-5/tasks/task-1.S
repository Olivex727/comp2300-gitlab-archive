.syntax unified
.global main

.type main, %function
main:
  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ change offset to DIR
  ldr r2, =0x514

  @ load r3 with pin number for column
  ldr r3, =#28

  bl set_bit

  @ load r3 with pin number for row
  ldr r3, =#21

  bl set_bit

  @ change offset to OUT
  ldr r2, =0x504

  bl set_bit

  b main

.size main, .-main

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

@ Set bit
@ r1 = Location
@ r2 = Offset
@ r3 = Bit position
clear_bit:
  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  mov r0, 0

  @ store the modified result back into P0 OUT
  str r0, [r1, r2]

  bx lr