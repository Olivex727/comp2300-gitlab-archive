.syntax unified
.global main

.type main, %function
main:
  ldr r0, =0xcafe0000
  ldr r1, =0xffff

  add r3, r0, r1

  lsr r4, r0, #4

  add r5, r3, #1

  bic r6, r0, 0xa000000

  @ your code goes here

@ when it's all done, spin in an infinite loop
loop:
  nop
  b loop