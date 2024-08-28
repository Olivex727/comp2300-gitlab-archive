.syntax unified
.global main

.type main, %function
main:
  @ Student 1 - F
  mov r0, 58
  mov r1, 51
  mov r2, 41
  bl calculate_grade

  @ Student 2 - C
  mov r0, 68
  mov r1, 81
  mov r2, 71
  bl calculate_grade

  @ Student 3 - B
  mov r0, 88
  mov r1, 91
  mov r2, 91
  bl calculate_grade

  @ go to the end loop
  b end

end:
  b end

@ Parameters: r0, r1, r2
@ Returns:    r0
@ Overwrites: r0, r1, r2
calculate_grade:
  push {lr}
  bl calculate_total_mark
  bl grade_from_mark_recursive
  pop {lr}
  bx lr

@ Parameters: r0, r1, r2
@ Returns:    r0
@ Overwrites: r0, r1, r2
calculate_total_mark:
  push {lr}

  @ Calculate Mark
  asr r2, r2, 1 @ Divide by 2
  asr r1, r1, 2 @ Divide by 4 = 2^2
  asr r0, r0, 2 @ Divide by 4 = 2^2

  @ Sum results in r0
  add r0, r1
  add r0, r2

  @ go back to where the function was called from
  pop {lr}
  bx lr

@ Parameters: r0
@ Returns:    r0
@ Overwrites: r0, r1
grade_from_mark:
  push {lr}

  mov r1, 10
  udiv r0, r0, r1

  @ If mark is 100%
  cmp r0, 10
  it eq
  moveq r0, 0xA
  beq skip_calc

  @ If mark is less than 50%
  cmp r0, 5
  it mi
  movmi r0, 0xF
  bmi skip_calc
  
  @ If mark is between 50 - 99
  @ Grade = 15 - (Mark/10 - 4) = 19 - Mark/10
  mov r1, 19
  sub r0, r1, r0

skip_calc:
  pop {lr}
  bx lr

@ Parameters: r0
@ Returns:    r0
@ Overwrites: r0
grade_from_mark_recursive:
  push {lr}

  cmp r0, 50
  bmi base

  sub r0, 10

  bl grade_from_mark_recursive  @ recursive call

  sub r0, 1

  b exit

base:
  mov r0, 0xF
exit:
  pop {lr}
  bx lr