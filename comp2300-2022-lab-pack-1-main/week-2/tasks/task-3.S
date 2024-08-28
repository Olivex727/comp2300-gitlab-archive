.syntax unified
.global main

.type main, %function
main:
  .hword 0xf04f @ Opcode (mov) r1, 3
  .hword 0x0103 @ Params mov (r1, 3)
  .hword 0xf1a1 @ Opcode (sub r1), r1, 1
  .hword 0x0101 @ Params sub r1, (r1, 1)

  b main
.size main, .-main

.data
hello:
.word 0x424242