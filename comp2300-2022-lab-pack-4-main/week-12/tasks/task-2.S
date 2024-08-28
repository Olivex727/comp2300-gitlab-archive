.syntax unified
.global main

.type main, %function
main:
  bl init_leds
  
  bl create_process
  b switch_context
  b main
.size main, .-main

.type ledblink, %function
ledblink:
  bl on
  bl delay
  bl off
  bl delay
  b ledblink
.size ledblink, .-ledblink

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

create_process:
  push {r0-r3}
  ldr r0, =0x20008000

  @ PSR
  mov r1, 0x01000000
  str r1, [r0], -4

  @ PC
  ldr r2, =ledblink
  str r2, [r0], -4

  @ LR
  str lr, [r0], -4

  pop {r0-r3}
  ldr sp, =0x20008000
  sub sp, 12

  @ Registers
  push {r0-r3, r12}

  bx lr

switch_context:
  @ Restore LR/XPSR
  ldr r0, =0x20008000

  ldr r1, [r0], -8
  msr apsr_nzcvq, r1

  ldr lr, [r0]
  
  @ Resore Registers
  pop {r0-r3, r12}

  @ Move Stack Pointer
  add sp, 8
  ldr pc, [sp], 4
  

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