.syntax unified
.global main

.type main, %function
main:
  ldr r0, =4000000
  bl enable_timer
  b timer

  b main
.size main, .-main

timer:
  nop
  bl check_timer
  cmp r0, 0
  beq finished
  b timer

finished:
  nop
  b finished

@ Enables timer and sets to tick length determined by r0
@ Params: r0
enable_timer:
  push {lr, r0}

  ldr r0, =ADR_SYST_CSR
  ldr r1, [r0]

  mov r2, 0b101
  orr r1, r2

  str r1, [r0]

  pop {r1}
  ldr r0, =ADR_SYST_RVR

  str r1, [r0]

  pop {lr}
  bx lr

@ Determines the current timer value, and outputs if it reaches zero
@ Outputs: r0
check_timer:
  ldr r0, =ADR_SYST_CVR
  ldr r0, [r0]
  bx lr