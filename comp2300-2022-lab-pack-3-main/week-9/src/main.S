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
  bl enable_GPIOTE
  bl init_leds
  ldr r0, =1000000
  bl enable_timer

  b blink_loop
.size main, .-main

blink_loop:
  b blink_loop


.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}
  ldr r0, =timer_count
  ldr r1, [r0]

  subs r1, 1
  bne skip_toggle

  bl toggle_led
  bl read_led_lab
  cmp r0, 0
  bne blink_short
  ldr r0, =timer_count
  ldr r1, [r0, 4]
  b skip_toggle

blink_short:
  bl get_tick_length_score
  ldr r0, =timer_count

skip_toggle:
  str r1, [r0]

  pop {lr}
  bx lr

toggle_led:
  push {lr, r4-r5}

  @ Get the bit position of the rows/columns
  @ r4 stores col, r5 stores row
  ldr r0, =score
  add r0, 4
  ldr r1, [r0]
  mov r4, r1
  mov r5, 5
  bl mod
  udiv r5, r1, r5

  @ Read the pin (r5,r4)
  mov r0, r5
  mov r1, r4
  bl read_led
  cmp r0, 0
  ite eq
  addeq r0, 1
  subne r0, 1

  @ Write the pin (r5,r4)
  mov r2, r0
  mov r0, r5
  mov r1, r4
  bl write_led

  pop {lr, r4-r5}
  bx lr

@ Reads the LED and stores result in r0
read_led_lab:
  push {lr, r4-r5}

  @ Get the bit position of the rows/columns
  @ r4 stores col, r5 stores row
  ldr r0, =score
  add r0, 4
  ldr r1, [r0]
  mov r4, r1
  mov r5, 5
  bl mod
  udiv r5, r1, r5

  @ Read the pin (r5,r4)
  mov r0, r5
  mov r1, r4
  bl read_led

  pop {lr, r4-r5}
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

@ Modulo Operator
@ Out to r4
@ r4 = r4 % r5
mod:
  subs r4, r5
  bgt mod

  beq no_add
  add r4, r4, r5
no_add:
  bx lr

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {lr}
  @ setup a breakpoint here to check when the interrupt occurs.
  @ interrupt code goes here

  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, [r0]
  ldr r2, =GPIOTE_EVENTS_IN1
  ldr r3, [r2]

  push {r12}
  @ P2 can backtrack P1's progress
  sub r12, r1, r3
  

  bl read_led_lab
  cmp r0, 0
  beq lost

@ The button was pressed when the LED was on
won:
  push {r4-r5}
  ldr r0, =score
  ldr r1, [r0]
  cmp r1, 32
  it lt
  addlt r1, r12
  cmp r1, 0
  it lt
  addlt r1, 1

  mov r4, r1
  mov r5, 25
  bl mod

  str r1, [r0], 4
  str r4, [r0]
  
  pop {r4-r5}
  pop {r12}

  bl clear_all_nuclear

lost:
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

@ Enables the GPIOTE Ports
enable_GPIOTE:
  push {lr}

  @ Set SHPR3 to Minimum Priority
  ldr r0, =0x8
  lsl r0, 28
  ldr r1, =SHPR3
  ldr r2, [r1]
  orr r2, r0
  str r2, [r1]

  @ 1: Configure GPIOTE_CONFIG[0]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[0]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  ldr r0, =GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
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

@ Carelessly implemented nuclear option - turns off all pins' OUT
clear_all_nuclear:
  push {lr}
  mov r0, 0b11111
  bl write_column_pins
  mov r0, 0b00000
  bl write_row_pins
  pop {lr}
  bx lr

@ Gets the LED light-on value, into r1
get_tick_length_score:
  ldr r0, =score
  ldr r1, [r0]
  ldr r0, =timer_count
  ldr r2, [r0, 4]

  mov r3, 10
  mul r1, r1, r3

  sub r1, r2, r1
  bx lr

.data
score:
.word 0, 0 @ Score, Score mod 25 (LED Pos)
timer_count:
.word 320, 320 @ Counter, Max Counter