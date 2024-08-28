.syntax unified
.global main

.type main, %function
main:
  bl init_leds

  ldr r0, =ledblink
  ldr r1, =0x20008000
  bl create_process

  ldr r0, =ledblink_2
  ldr r1, =0x20007000
  bl create_process

  ldr r0, =640000000
  bl enable_timer

  b loop
.size main, .-main

loop:
  nop
  b loop

.type ledblink, %function
ledblink:
  bl on
  bl delay
  bl off
  bl delay
  b ledblink
.size ledblink, .-ledblink

.type ledblink_2, %function
ledblink_2:
  bl on
  bl delay
  bl delay
  bl off
  bl delay
  bl delay
  b ledblink_2
.size ledblink_2, .-ledblink_2

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

@ Takes r0, r1 as a parameter (Location of adress)
create_process:
  push {r2-r3}
  
  @ PSR
  mov r2, 0x01000000
  str r2, [r1, 0x1c]

  @ PC
  str r0, [r1, 0x18]

  @ LR
  str lr, [r1, 0x14]

  pop {r2-r3}

  @ Registers
  str r12, [r1, 0x12]
  str r3, [r1, 0x10]
  str r2, [r1, 0xc]
  str r1, [r1, 0x4]
  str r0, [r1, 0x0]

  bx lr

@ UNEEDED
@ Takes r0 as parameter (Stack location of process)
switch_context:
  @ Restore LR/XPSR
  ldr r1, [r0], -8
  msr apsr_nzcvq, r1

  ldr lr, [r0]
  
  @ Resore Registers
  pop {r1-r3, r12}
  mov sp, r0

  @ Move Stack Pointer
  add sp, 8
  ldr pc, [sp], 4
  

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  ldr r0, =process_table
  ldr r1, [r0]

  cmp r1, 0
  ite eq
  addeq r1, 1
  subne r1, 1

  mov r2, 4
  mla r2, r1, r2, r2

  ldr sp, [r0, r2]

  str r1, [r0]
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

.data
process_table:
.word 0 @ index of currently-operating process
.word 0x20008000 @ stack pointer 1
.word 0x20007000 @ stack pointer 2