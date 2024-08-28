.syntax unified
.global main

cope:
  .ascii "COPE"

.type main, %function
main:
  @ load "COPE" into r1
  ldr r1, cope
  add r2, r1, 0x00000005
  add r3, r2, 0x0e000000

loop:
  nop
  b loop
.size main, .-main