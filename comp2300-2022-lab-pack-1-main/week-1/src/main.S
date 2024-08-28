.syntax unified
.global main
.type main, %function

lol:
  .ascii "Hello World!"

main:
  mov r1, 0
  mov r2, 0x69
  ldr r3, lol

loop:
  add r1, 1
  b loop