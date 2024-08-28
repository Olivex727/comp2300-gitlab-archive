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
  ldr r0, =32000000
  bl enable_timer
  bl configure_rings
  bl init_leds

  b loop
.size main, .-main

loop:
  nop
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

  @ 1: Configure GPIOTE_CONFIG[0]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[0]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 3 (Toggle)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 4 << 8 | 0 << 13 | 3 << 16)
  str r1, [r0]

  @ 2: Enable Interrupt for GPIOTE[0] (id = 6)
  @ S6.9.4.6 in nRF52833 reference manual
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b11
  str r1, [r0]

  @ 3: enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
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


.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {lr}
  @ setup a breakpoint here to check when the interrupt occurs.
  @ interrupt code goes here

  bl poll_ring
  bl led_from_poll

  @ clear event
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]
  ldr r0, =GPIOTE_EVENTS_IN1
  str r1, [r0]
  nop
  pop {lr}
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler