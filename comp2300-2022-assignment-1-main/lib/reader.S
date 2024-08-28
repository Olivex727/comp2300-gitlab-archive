.syntax unified
.global reader

@ Reader reads from r0 and r1 (array counter) and r12 (state)
.type reader, %function
reader:
  push {lr}

  @ Get the counter
  bl get_counter

  @ Decrement the counter value
  bl decrement

  pop {lr}
  bx lr
.size reader, .-reader


@ Bit(s) | # |  Purpose
@ -------------------------
@ 1-4    | 4 |  Iterations
@ 5-6    | 2 |  Speed
@ 7      | 1 |  Border
@ 8-32   | 25|  Board State

@ Gets the counter, storing in r3
get_counter:
  @ Extract the front 4 bits from r12
  mov r3, 0b1111
  lsl r3, 28
  and r3, r12
  lsr r3, 28
  bx lr

@ Decrements front value, if value is at zero, then move to next seed
decrement:
  subs r3, 1
  ble new_seed
  b old_seed

@ Old Seed will move the decremented value back into r12
@ r3 is used
old_seed:
  @ Clear iteration data
  mov r4, 0b1111
  lsl r4, 28
  bic r12, r4
  lsr r4, 28

  @ Add new iteration data
  lsl r3, 28
  orr r12, r3
  bx lr

@ New Seed will replace the value in r12 with a new seed
new_seed:
  ldr r12, [r0, r1]
  add r1, 4
  cmp r1, r2
  it eq
  moveq r1, 0
  bx lr

