.syntax unified
.global main

@ r0  Player HP
@ r1  Enemy HP
@ r2  Player Str
@ r3  Enemy Str
@ r4  Move Calulator
@ r5  Multiplication/Division Store
@ r6  Equality check

.type main, %function
main:
  @b task 3

  @ TASK 1 - Pokemon HP stored in r0
  mov r0, 1000
  mov r1, 1000

  mov r2, 100
  mov r3, 50

turn_p:
  @ Fireball
  add r4, 30
  subs r1, r4

  bmi pokemon_wins
  beq pokemon_wins
  mov r4, 0

  @ Strength from Weariness
  add r4, r0
  sub r4, r2

  mov r5, 20
  udiv r4, r5
  mov r5, r4
  mul r4, r5
  mov r5, 0

  add r0, r4
  mov r4, 0

  mov r6, 1000
  subs r6, r0
  bmi recap
main_2:
  b turn_e

recap:
  mov r0, 1000
  mov r6, 0
  b main_2

turn_e:
  @ Mega Punch - Deals three times the strength of the user to the opponent
  add r4, r3
  mov r5, 3
  mul r4, r5
  mov r5, 0
  subs r0, r4

  bmi enemy_wins
  beq enemy_wins
  b turn_p


pokemon_wins:
  b pokemon_wins

enemy_wins:
  b enemy_wins

@ a simple infinite loop
end_loop:
  nop
  b end_loop
.size main, .-main

@ a place for your to complete task 3. uncomment line 6 when you're ready to start working on it!
task_3:
  @ set the negative flag

  mov r1, 0
  subs r1, 1

  @ set the zero flag

  movs r2, 0

  @ set the carry flag

  adds r1, 1

  @ set the overflow flag

  b overflow

  b end_loop

overflow:
  adds r2, 0xF000000
  bvc overflow
  bvs end_loop