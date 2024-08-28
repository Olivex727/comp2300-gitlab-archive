.syntax unified
.global main

.type main, %function
main:
  @ In Memory, this code looks like:
  .hword 0xdead @ AD DE
  mov r1, 2     @ 4F F0 02 01
  .hword 0xbeef @ EF BE

  b main
.size main, .-main

.data
hello:
.word 0x424242