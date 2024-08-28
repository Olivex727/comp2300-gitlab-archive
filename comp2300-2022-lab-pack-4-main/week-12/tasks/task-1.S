.syntax unified
.global main

.type main, %function
main:
  bl init_leds
  ldr r0, =64000000
  bl enable_timer
  b blink_loop
  b main
.size main, .-main

blink_loop:
  bl on
  bl delay
  bl off
  bl delay
  b blink_loop

on:
  push {lr}
  mov r0, 0
  mov r1, 0
  mov r2, 1
  bl write_led
  pop {lr}
  bx lr

off:
  push {lr}
  mov r0, 0
  mov r1, 0
  mov r2, 0
  bl write_led
  pop {lr}
  bx lr

delay:
  push {r12}
  ldr r12, =12800000
delay_loop:
  subs r12, 1
  bgt delay_loop
  pop {r12}
  bx lr

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}
  

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