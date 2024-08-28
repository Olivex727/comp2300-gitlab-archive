.syntax unified
.global game_of_life

.type game_of_life, %function
game_of_life:
  push {lr}

  bl next_state
  bl return_state

  pop {lr}
  bx lr
.size game_of_life, .-game_of_life

@ Takes the new state value in r0 and combines it back with the metadata in r12
@ Parameter is r0, output is r12
return_state:
  @ Extract Metadata to r7
  mov r7, 0b1111111
  lsl r7, 25
  bic r0, r7 @ Clear heading of r0
  and r7, r12

  @ Add Metadata to r0
  add r0, r7

  mov r12, r0

  bx lr

@ Function finds the next state
@ r0 is the new state (output), it does not decrement the iteration counter
@ r11 is the current bit
@ r10 is the pattern matching string
@ r9 is the neighbour counter
@ r8 stored border on/off
@ r7 is scratch/parameter/leaf function output
@ r6 is the updated state, assuming dead cells (after neighbours counted)
@ r5 is the updated state, assuming live cells (after neighbours counted)
@ r4 - r1 is more scratch
next_state:
  push {lr}

  @ Take the state and replace all the metadata bits with border bits
  mov r0, r12
  mov r11, 0
  mov r6, 0
  mov r5, 0

  bl border
  
neigbour_loop:
  bl ring

  bl next_gen_if_alive
  bl next_gen_if_dead

  add r11, 1
  cmp r11, #25
  bmi neigbour_loop

  bl combine

  pop {lr}
  bx lr

@ C/R  1  2  3  4  5
@   .---------------
@ 1 | 00 05 10 15 20
@ 2 | 01 06 11 16 21
@ 3 | 02 07 12 17 22
@ 4 | 03 08 13 18 23
@ 5 | 04 09 14 19 24

@ Combines the 'if dead' and 'if alive' cells into one new state string.
@ Reads r12, r5, r6. Outputs to r0
combine:
  @ Formula: r0 = (r0 and r5) or (~r0 and r6)

  and r5, r0
  bic r6, r0

  orr r0, r5, r6
  bx lr

@ Takes neighbours in r9 and current bit in r11, and then determines if cell
@ should be alive or dead in the next generation, assumes that the cell was
@ dead. It will set a specific bit in r6.
next_gen_if_dead:
  @ A cell with 3 neighbours becomes alive
  cmp r9, 3
  bne dead_exit

  @ If cell needs to be alive
  mov r7, 0b1
  lsl r7, r11
  orr r6, r7
dead_exit:
  bx lr

@ Takes neighbours in r9 and current bit in r11, and then determines if cell
@ should be alive or dead in the next generation, assumes that the cell was
@ alive. It will set a specific bit in r5.
next_gen_if_alive:
  @ A cell with 2 or 3 neighbours stays alive, otherwise it dies
  cmp r9, 3
  beq alive
  cmp r9, 2
  beq alive
  b alive_exit

alive:
  mov r7, 0b1
  lsl r7, r11
  orr r5, r7
alive_exit:
  bx lr

@ Scans the ring around the location and adds to the neigbour counter in r9
ring:
  push {lr}
  mov r9, 0
  mov r1, 0

  @ (x, y) Co-ords in (r3, r4)
  bl decompose
  
  @ Check left bit
  cmp r3, 1
  bmi skip_left
  sub r3, 1

  bl recompose
  bl extract

  add r3, 1
  
  b n_left
skip_left:
  add r9, r8
n_left:

  @ Check top bit
  cmp r4, 1
  bmi skip_top
  sub r4, 1

  bl recompose
  bl extract

  add r4, 1
  b n_top
skip_top:
  add r9, r8
n_top:

  @ Check right bit
  cmp r3, 4
  beq skip_right
  add r3, 1

  bl recompose
  bl extract

  sub r3, 1
  b n_right
skip_right:
  add r9, r8
n_right:

  @ Check bottom bit
  cmp r4, 4
  beq skip_bot
  add r4, 1

  bl recompose
  bl extract

  sub r4, 1
  b n_bot
skip_bot:
  add r9, r8
n_bot:

  @ Check TL corner
  cmp r3, 1
  bmi skip_tl
  cmp r4, 1
  bmi skip_tl
  sub r3, 1
  sub r4, 1

  bl recompose
  bl extract

  add r3, 1
  add r4, 1
  
  b n_tl
skip_tl:
  add r9, r8
n_tl:

  @ Check TR corner
  cmp r3, 4
  beq skip_tr
  cmp r4, 1
  bmi skip_tr
  add r3, 1
  sub r4, 1

  bl recompose
  bl extract

  sub r3, 1
  add r4, 1
  
  b n_tr
skip_tr:
  add r9, r8
n_tr:

  @ Check BL corner
  cmp r3, 1
  bmi skip_bl
  cmp r4, 4
  beq skip_bl
  sub r3, 1
  add r4, 1

  bl recompose
  bl extract

  add r3, 1
  sub r4, 1
  
  b n_bl
skip_bl:
  add r9, r8
n_bl:

  @ Check BR corner
  cmp r3, 4
  beq skip_br
  cmp r4, 4
  beq skip_br
  add r3, 1
  add r4, 1

  bl recompose
  bl extract

  sub r3, 1
  sub r4, 1
  
  b n_br
skip_br:
  add r9, r8
n_br:

  add r9, r1

  pop {lr}
  bx lr

@ Find out if border is D or A and store in r8
border:
  push {lr}
  mov r1, #0
  mov r2, #25
  bl extract
  mov r8, r1
  pop {lr}
  bx lr

@ Decompose the value in r11 into an (x,y) coordinate
@ inputs r11, outputs r3, r4
@ Keeps parameter
decompose:
  push {lr}

  mov r3, r11
  mov r4, 5
  bl mod
  
  mov r3, r11
  udiv r3, r3, r4

  @mov r3, r2
  mov r4, r2

  pop {lr}
  bx lr

@ Recomposes the (x,y) value in r3, r4 into r2
@ inputs r3, r4, outputs r2
@ Keeps parameters
recompose:
  push {lr}
  
  mov r2, 5
  mla r2, r2, r3, r4

  pop {lr}
  bx lr

@ Modulo Operator
@ Out to r2
@ r2 = r3 % r4
mod:
  subs r3, r4
  bgt mod

  beq no_add
  add r3, r3, r4
no_add:
  mov r2, r3
  bx lr

@ Extracts single bit value from r0, reads from r2 and ADDS to r1
@ Uses r7
extract:
  mov r7, 0b1
  lsl r7, r2
  and r7, r0, r7
  lsr r7, r2
  add r1, r7
  bx lr