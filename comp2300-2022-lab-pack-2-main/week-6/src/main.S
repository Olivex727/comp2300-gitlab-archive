.syntax unified
.global main

.type main, %function
main:
  ldr r0, =results
  bl calculate_lab_grades
  nop
  b end

end:
  nop
  b end

@ input:
@ r0: address of start of mark array with format,
@ .word size of array
@ .word a1, a2, final, 0
@ output:
@ .word a1, a2, final, grade
calculate_lab_grades:
  push {lr}
  @ Setup
  mov r5, r0
  ldr r3, [r5], #4
  mov r4, 0
  
calculate_grade_loop:
  @ Condition
  cmp r4, r3
  bge exit_loop

  ldm r5, {r0, r1, r2}

  push {r0, r1, r2}
  
  bl calculate_grade
  mov r6, r0

  pop {r0, r1, r2}

  stm r5!, {r0, r1, r2, r6}

  @ Next
  add r4, 1
  b calculate_grade_loop

exit_loop:
  pop {lr}
  bx lr

.data
results:
  @ Length of array: 6
  .word 6
  @S1
  .word 50, 50, 40, 0
  @S2
  .word 77, 80, 63, 0
  @S3
  .word 40, 50, 60, 0
  @S4
  .word 80, 82, 89, 0
  @S5
  .word 80, 85, 77, 0
  @S6
  .word 91, 90, 95, 0

.text
@ Parameters: r0, r1, r2
@ Returns:    r0
@ Overwrites: r0, r1, r2
calculate_grade:
  push {lr}
  bl calculate_total_mark
  bl grade_from_mark
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