.syntax unified
.global main

.type main, %function
main:
  @ b task_3

  @ Pokemon HP stored in r0
  mov r0, 1000

@ a simple infinite loop
end_loop:
  nop
  b end_loop
.size main, .-main

@ a place for your to complete task 3. uncomment line 6 when you're ready to start working on it!
task_3:
