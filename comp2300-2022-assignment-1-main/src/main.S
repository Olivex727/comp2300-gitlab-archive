.syntax unified
.global main

.type main, %function
main:
  @ Total input array size and store at base of stack
  ldr r0, =states
  ldr r1, =end_states
  sub r2, r1, r0
  mov r1, 0

  @ r0 = Size of Array, r1 = Index of Array
  push {r0, r1, r2}


  b light_show
  
  b loop
.size main, .-main

@ Loops forever, controlled by the reader
light_show:
  pop {r0, r1, r2}
  bl reader
  push {r0, r1, r2}
  bl display_main
  bl game_of_life
  b light_show

loop:
  nop
  b loop

.data
states:
  @       IIIISSB|....|....|....|....|.... @ Metadata
  @              ABCDEFGHIJKLMNOBQRSTUVWXY @ 25-LED Board
  .word 0b00000101111111111111111111111111 @ #0 - 0.5 s, 01 count 
  .word 0b10100100100011100110100100000000 @ #1 - 5.0 s, 10 counts, 0.5  s/count
  .word 0b10010100000000111010000011100000 @ #2 - 4.5 s, 09 counts, 0.5  s/count
  @ 10 Second Mark
  .word 0b01101011000010000100001000010000 @ #3 - 4.5 s, 06 counts, 0.75 s/count
  .word 0b01100010000011111000001111100000 @ #4 - 1.5 s, 06 counts, 0.25 s/count
  .word 0b01000001010110001010101100110001 @ #5A- 1.0 s, 04 counts, 0.25 s/count
  .word 0b01000001010110001010101100110001 @ #5B- 3.0 s, 12 counts, 0.25 s/count
  @ 20 Second Mark
  .word 0b01001000000001100011100100000000 @ #6 - 3.0 s, 04 counts, 0.75 s/count
  .word 0b10000000000001100011100110000000 @ #7 - 2.0 s, 08 counts, 0.25 s/count
  .word 0b00101110000001110011100110000000 @ #8 - 2.0 s, 02 counts, 1.0  s/count
  .word 0b01000011000001000001000001000001 @ #9A- 1.0 s, 04 counts, 0.25 s/count
  .word 0b00100000010000100110110101011011 @ #10- 0.5 s, 02 counts, 0.25 s/count
  .word 0b00110001000001000001000001000001 @ #9B- 1.5 s, 05 counts, 0.5  s/count
  @ 30 Second Mark - Restart from beginning
end_states:
  nop