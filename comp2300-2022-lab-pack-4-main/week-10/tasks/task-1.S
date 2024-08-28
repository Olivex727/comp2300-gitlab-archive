.syntax unified
.global main

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.set SHPR3, 0xE000ED20

.type main, %function
main:
  ldr r0, =10000000
  bl enable_timer
  bl configure_rings
  bl init_leds

  b loop
.size main, .-main

loop:
  nop
  bl poll_ring
  bl led_from_poll
  b loop

poll_ring:
  push {lr}
  ldr r0, =ADR_P0
  ldr r1, =OFS_GPIO_IN
  ldr r2, [r0, r1]

  ldr r3, =0b10000
  and r3, r2
  lsr r3, #4

  mov r0, r3
  pop {lr}
  bx lr

led_from_poll:
  push {lr}

  mov r2, r0
  mov r0, 0
  mov r1, 0
  bl write_led

  pop {lr}
  bx lr

configure_rings:
  push {lr}
  ldr r0, =ADR_P0
  ldr r1, =OFS_GPIO_DIR
  ldr r2, [r0, r1]

  ldr r3, =0b100
  orr r2, r3
  str r2, [r0, r1]

  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 4 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

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

toggle_signal:
  push {lr, r4}
  ldr r0, =ADR_P0
  ldr r1, =OFS_GPIO_OUT
  ldr r2, [r0, r1]

  ldr r3, =0b100
  ldr r4, =0b100
  and r3, r2
  cmp r3, 0
  ite eq
  orreq r2, r4
  bicne r2, r4

  str r2, [r0, r1]

  pop {lr, r4}
  bx lr

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}
  
  bl toggle_signal

  pop {lr}
  bx lr