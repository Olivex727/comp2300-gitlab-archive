.syntax unified
.global main

.type main, %function
main:
  ldr r1, =thing
  ldr r2, =thing2

  sub r0, r2, r1

@ when it's all done, spin in an infinite loop
loop:
  nop
  b loop

thing:
  movs r3, 1
thing2:
  nop