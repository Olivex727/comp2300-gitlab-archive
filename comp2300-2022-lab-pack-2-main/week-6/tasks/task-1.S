.syntax unified
.global main

.type main, %function
main:
  @ set up the arguments
  mov r0, 66 @ ass1 mark
  mov r1, 73 @ ass2 mark
  mov r2, 71 @ final exam mark

  @ call the function
  bl calculate_total_mark

  @ go to the end loop
  b end

end:
  b end

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