.syntax unified
.global main

.type main, %function
main:
  ldr r0, =1600000
  push {r0}
  bl init_leds
  pop {r0}
  bl enable_timer

  b timer
.size main, .-main

timer:
  nop
  b timer

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}
  ldr r0, =timer_count
  ldr r1, [r0]


  subs r1, 1
  bne skip_toggle

  bl toggle_led
  ldr r0, =timer_count
  mov r1, 2

skip_toggle:
  str r1, [r0]

  pop {lr}
  bx lr


toggle_led:
  push {lr}

  @ Read the pin (0,0)
  mov r0, 0
  mov r1, 0
  bl read_led
  cmp r0, 0
  ite eq
  addeq r0, 1
  subne r0, 1

  @ Write the pin (0,0)
  mov r2, r0
  mov r0, 0
  mov r1, 0
  bl write_led

  pop {lr}
  bx lr

@ Enables timer and sets to tick length determined by r0
@ Params: r0
enable_timer:
  push {lr, r0}

  ldr r0, =ADR_SYST_CSR
  ldr r1, [r0]

  mov r2, 0b111
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

.data
timer_count:
  .word 2