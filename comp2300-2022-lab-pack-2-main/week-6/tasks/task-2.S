.syntax unified
.global main

.type main, %function
main:
  mov r0, 15
  bl grade_from_mark

  mov r0, 99
  bl grade_from_mark

  mov r0, 70
  bl grade_from_mark

  mov r0, 5
  bl grade_from_mark

  @ go to the end loop
  b end

end:
  b end

@ Parameters: r0, r1, r2
@ Returns:    r0
@ Overwrites: r0, r1, r2
calculate_total_mark:
  @ Calculate Mark
  asr r2, r2, 1 @ Divide by 2
  asr r1, r1, 2 @ Divide by 4 = 2^2
  asr r0, r0, 2 @ Divide by 4 = 2^2

  @ Sum results in r0
  add r0, r1
  add r0, r2

  @ go back to where the function was called from
  bx lr

@ Parameters: r0
@ Returns:    r0
@ Overwrites: r0
grade_from_mark:
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
  bx lr