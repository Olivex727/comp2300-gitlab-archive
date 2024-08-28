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

  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ load r2 with the value of P0 OUT
  ldr r2, [r1, 0x504]

  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  mov r3, 0b1
  lsl r3, r3, #21
  orr r2, r2, r3

  @ store the modified result back into P0 OUT
  str r2, [r1, 0x504]

  b delay

exit:
  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ load r2 with the value of P0 OUT
  mov r2, 0

  @ store the modified result back into P0 OUT
  str r2, [r1, 0x504]

  b loop


delay:
  ldr r12, =0x00800000 @About 1 second
delay_loop:
  subs r12, 1
  beq exit
  b delay_loop


@ when it's all done, spin in an infinite loop
loop:
  nop
  b loop
