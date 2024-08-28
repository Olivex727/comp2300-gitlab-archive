.syntax unified
.global main

.type main, %function
main:
  ldr r1, =storage
  
  ldr r0, [r1, 12]
  add r0, 1
  str r0, [r1, 12]

.data
storage:
  .word 2, 3, 0, 0 @ don't change this line

@ when it's all done, spin in an infinite loop
loop:
  nop
  b loop