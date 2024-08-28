.syntax unified
.global main

.type main, %function
main:
  b task_3

  @ TASK 1 - Pokemon HP stored in r0
  mov r0, 1000

  @ TASK 2 - Use healing potion
  b healing_potion

healing_potion:
  adds r0, 0xF000000
  b healing_potion


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