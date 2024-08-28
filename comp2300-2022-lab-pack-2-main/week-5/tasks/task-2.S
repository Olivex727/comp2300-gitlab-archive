.syntax unified
.global main

.type main, %function
main:
  ldr r11, =0

.size main, .-main

@ FizzBuzz Loop
fizzbuzz:
  add r11, 1

  mov r1, r11
  mov r2, 3
  bl mod
  cmp r0, 0

  it eq
  bleq left_blink

  mov r1, r11
  mov r2, 5
  bl mod
  cmp r0, 0

  it eq
  bleq right_blink

  bl delay
  bl clear_out

  cmp r11, #100
  beq loop
  b fizzbuzz

@ Modulo Operator
@ Out to r0
@ r0 = r1 % r2
mod:
  subs r1, r2
  bgt mod

  beq no_add
  add r1, r1, r2
no_add:
  mov r0, r1
  bx lr


@ Left Blink
left_blink:
  push {lr}

  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ change offset to DIR
  ldr r2, =0x514

  @ load r3 with pin number for column
  ldr r3, =#28

  bl set_bit

  @ load r3 with pin number for row
  ldr r3, =#21

  bl set_bit

  @ change offset to OUT
  ldr r3, =#21
  ldr r2, =0x504

  bl set_bit

  pop {lr}
  bx lr

@ Right Blink
right_blink:
  push {lr}

  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ change offset to DIR
  ldr r2, =0x514

  @ load r3 with pin number for column
  ldr r3, =#30

  bl set_bit

  @ load r3 with pin number for row
  ldr r3, =#21

  bl set_bit

  @ change offset to OUT
  ldr r2, =0x504

  bl set_bit

  pop {lr}
  bx lr


@ Set bit
@ r0 = Output
@ r1 = Location
@ r2 = Offset
@ r3 = Bit position
set_bit:
  @ Load Memory information
  ldr r0, [r1, r2]

  @ set bit 21 of this register by doing a logical or with 0b1 left-shifted by 21
  mov r4, 0b1
  lsl r4, r4, r3
  orr r0, r0, r4

  @ store the modified result back into P0 OUT
  str r0, [r1, r2]

  bx lr

@ Clear OUT
clear_out:
  @ load r1 with the base address of P0
  ldr r1, =0x50000000

  @ change offset to OUT
  ldr r2, =0x514@=0x504

  b clear

@ Clear bit
@ r1 = Location
@ r2 = Offset
clear:
  mov r0, 0

  @ store the modified result back into pin
  str r0, [r1, r2]

  bx lr

delay:
  ldr r12, =0x00200000 @ ~0.5 seconds
delay_loop:
  subs r12, 1
  it eq
  bxeq lr
  b delay_loop

loop:
  nop
  b loop