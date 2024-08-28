@ ASSIGNMENT 1 CODE - HAS BEEN MODIFIED
.syntax unified
.global reader

@ --------------------- Unused reader code -------------------- @

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

@ --------------------- Modified reader code -------------------- @

.global load_seed
@ Loads a new seed state into memory
load_seed:
  push {lr}
  @ Get the index of the next state
  ldr r0, =current
  ldr r1, [r0, 4]

  @ Get the next seed state
  ldr r0, =states
  ldr r2, [r0, r1]

  @ Store the seed state into the current handler
  ldr r0, =current
  str r2, [r0]

  @ Get the array size
  ldr r0, =states
  ldr r2, =end_states
  sub r2, r0

  @ Increment the array index
  add r1, 4
  cmp r1, r2
  it ge
  movge r1, 0 @ If the next state is at the end of the array, reset

  @ Store the array index back
  ldr r0, =current
  str r1, [r0, 4]
  
  pop {lr}
  bx lr

@ Junk code - simply because the user can't tell if the border is on/off
.global toggle_border
toggle_border:
  push {lr, r8}

  ldr r0, =current
  ldr r1, [r0]

  @ Read Border Bit
  mov r2, 0b1
  lsl r2, #25
  and r2, r1, r2
  lsr r2, #25

  @ Alter Border Bit
  cmp r2, 0
  ite eq
  addeq r2, 1
  subne r2, 1

  @ Write Border Bit
  lsl r2, #25
  orr r1, r1, r2
  str r1, [r0]

  pop {lr, r8}
  bx lr

@ Set speed to fast or slow
.global toggle_speed
toggle_speed:
  push {lr}
  ldr r0, =timer_counter
  ldr r1, [r0, 4]

  cmp r1, 32000
  beq default_display_speed
  bne actived_display_speed

default_display_speed:
  ldr r1, =128000
  str r1, [r0, 4]
  b exit_toggle_speed

actived_display_speed:
  ldr r1, =32000
  str r1, [r0, 4]
  b exit_toggle_speed

exit_toggle_speed:
  pop {lr}
  bx lr

.global reset_all
@ Nuclear Option - Reset the entire operation (Resets timer); prevents GOL/SysTick from overwriting the new seed
reset_all:
  push {lr}
  @ Restart display/iteration counter
  ldr r0, =timer_counter
  ldr r1, [r0, 4]
  str r1, [r0]

  @ Reset speed counter
  ldr r0, =current
  mov r1, 0
  str r1, [r0, 8]

  @ Clear Display
  bl clear_dir

  @ Re-Enable Timer
  ldr r0, =1000 @ Each LED column stays on for 1000 cycles
  bl enable_timer

  pop {lr}
  bx lr
