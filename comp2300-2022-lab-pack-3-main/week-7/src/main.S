.syntax unified
.global main

.type main, %function
main:
  b next

thing:
  .word 0x12345678

next:
  ldr r1, =thing
  ldr r2, thing
  b loop

loop:
  nop
  b loop

