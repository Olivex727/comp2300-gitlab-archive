.syntax unified
.global main

.type main, %function
main:
  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ load r2 with the value of P0 DIR
  @ (note the 0x514 offset from the P0 base address)
  ldr r2, [r1, 0x514]

  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  @ do again for bit 28
  mov r3, 0b1
  lsl r3, r3, #21
  orr r2, r2, r3
  lsl r3, r3, #7
  orr r2, r2, r3

  @ store the modified result back into P0 DIR
  str r2, [r1, 0x514]

op:
  # SOS = ...---...

  bl dot
  bl dot
  bl dot
  bl dash
  bl dash
  bl dash
  bl dot
  bl dot
  bl dot

  bl delay_long
  bl delay_long

  b op

dot:
  mov r11, lr
  
  bl on
  bl delay_short
  bl off
  bl delay_short

  bx r11

dash:
  mov r11, lr

  bl on
  bl delay_long
  bl off
  bl delay_short

  bx r11


delay_long:
  ldr r12, =0x00500000 @ A bit more than 0.5 seconds
  b delay_loop


delay_short:
  ldr r12, =0x00200000 @ About 0.25 seconds
  b delay_loop


delay_loop:
  subs r12, 1
  it eq
  bxeq lr
  b delay_loop

on:
  @ load r2 with the value of P0 OUT
  ldr r2, [r1, 0x504]

  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  mov r3, 0b1
  lsl r3, r3, #21
  orr r2, r2, r3

  @ store the modified result back into P0 OUT
  str r2, [r1, 0x504]

  bx lr

off:
  @ load r2 with the value of P0 OUT
  mov r2, 0

  @ store the modified result back into P0 OUT
  str r2, [r1, 0x504]

  bx lr

loop:
  b loop
