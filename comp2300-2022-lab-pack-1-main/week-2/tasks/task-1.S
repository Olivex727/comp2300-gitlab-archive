.syntax unified
.global main

.type main, %function
main:
  mov r1, 2
  mov r2, 2
  add r1, r2, r1

  b main
.size main, .-main