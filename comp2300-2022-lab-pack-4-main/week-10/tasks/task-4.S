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

@ SysTick vars
.set RVR_1MS,      64000
.set RVR_0_5MS,    32000
@ Timer vars
.set TIMER0_1MS,   1000
.set TIMER0_0_5MS, 500

.set MESSAGE_SIZE, 8

.type main, %function
main:
  ldr r0, =64000
  bl enable_timer
  bl configure_rings
  bl init_leds
  bl init_TIMER0
  mov r0, 1
  bl set_signal

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
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 2 (HiToLo)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 4 << 8 | 0 << 13 | 2 << 16)
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

@ Takes param r0 as to what signal it needs to send
set_signal:
  push {lr, r4}
  mov r3, r0
  ldr r0, =ADR_P0
  ldr r1, =OFS_GPIO_OUT
  ldr r2, [r0, r1]

  ldr r4, =0b100
  cmp r3, 0
  ite eq
  biceq r2, r4
  orrne r2, r4

  str r2, [r0, r1]

  pop {lr, r4}
  bx lr

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}
  
  ldr r0, =signal
  ldr r1, [r0], 4
  ldr r2, [r0]
  mov r3, 0b1

  @ Exract focused bit
  lsl r3, r2
  and r3, r1
  lsr r3, r2

  @ Increment the counter
  add r2, 1
  cmp r2, 11
  bge turn_off_timer
  str r2, [r0]

  @ Set output signal
  mov r0, r3
  bl set_signal

  b exit_systick_handler

turn_off_timer:
  ldr r0, =0
  bl enable_timer
  mov r0, 1
  bl set_signal

exit_systick_handler:
  pop {lr}
  bx lr


.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {lr}
  @ setup a breakpoint here to check when the interrupt occurs.
  @ interrupt code goes here

  mov r0, 1000
  bl set_TIMER0

  bl start_TIMER0

  @ Set GPIOTE Polarity to zero
  bl disable_GPIOTE

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

.global TIMER0_IRQHandler
.type TIMER0_IRQHandler, %function
TIMER0_IRQHandler:
  push {lr}
  @ Write your timer receive code here \/\/\/
  @ Get data
  bl poll_ring
  mov r3, r0

  ldr r0, = received_data
  ldr r1, [r0]
  ldr r2, [r0, 4]

  bl stop_TIMER0
  nop
  bl start_TIMER0

  @ Check r2 for a valid signal
  cmp r2, 8
  beq check_iszero
  cmp r2, 9
  beq check_isone
  b valid

check_iszero:
  cmp r3, 0
  beq receive_done
  b terminate_reception

check_isone:
  cmp r3, 1
  beq use_signal
  b terminate_reception

valid:
  @ Alter r2 so it's loaded in correct order
  push {r4}
  mov r4, 8
  sub r4, r4, r2
  
  @ Store back in memory
  lsl r3, r4
  orr r1, r3
  str r1, [r0]
  pop {r4}

  add r2, 1
  str r2, [r0, 4]

  b receive_done

use_signal:
  ldr r0, =received_data
  ldr r1, [r0]
  ldr r2, =0xF0

  @ Get row and columns
  and r3, r1, r2
  mov r0, r3

  ldr r2, =0xF
  and r3, r1, r2
  mov r1, r3

  mov r2, 1
  bl write_led

terminate_reception:
  bl stop_TIMER0
  bl clear_TIMER0

  bl configure_rings

receive_done:
  @ Clear this event
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_EVENTS_COMPARE0
  mov r2, 0
  bl clear_bit
  bl sync
  pop {lr}
  bx lr
.size TIMER0_IRQHandler, .-TIMER0_IRQHandler


.data
signal:
  .word 0b0110001000, 0 @ Signal to send, Position of current signal

  @ Packet (non-reversed but sent over): 0 0010 0011 0

received_data:
  .word 0, 0 @ recived signal, counter


@ TIMER0 Template stuff
.text
.type start_TIMER0, %function
@ Starts the timer.
@ --parameters--
@ none
start_TIMER0:
  @ Start TIMER0
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_TASKS_START
  mov r2, 1
  str r2, [r0, r1]
  bx lr
.size start_TIMER0, .-start_TIMER0


.type stop_TIMER0, %function
@ Stops the timer.
@ --parameters--
@ none
stop_TIMER0:
  @ Stop TIMER0
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_TASKS_STOP
  mov r2, 1
  str r2, [r0, r1]
  bx lr
.size stop_TIMER0, .-stop_TIMER0


.type set_TIMER0, %function
@ Sets the new compare value for TIMER0.
@ Requires TIMER0 to be stopped.
@ --parameters--
@ r0: time in microseconds for interrupt rate
set_TIMER0:
  push {r0}
  @ Set prescaler to 4 to get a 1 microsecond interrupt granularity
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_PRESCALER
  mov r2, 4
  str r2, [r0, r1]

  @ Set Compare value
  pop {r0}
  mov r2, r0
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_CC0
  str r2, [r0, r1]
  bx lr
.size set_TIMER0, .-set_TIMER0


.type clear_TIMER0, %function
@ Clears the current count value of the timer.
@ --parameters--
@ none
clear_TIMER0:
  @ Clear the internal timer count register
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_TASKS_CLEAR
  mov r2, 1
  str r2, [r0, r1]
  bx lr
.size clear_TIMER0, .-clear_TIMER0


.type init_TIMER0, %function
@ Inits the timer.
@ --parameters--
@ none
init_TIMER0:
@@@@ Set Timer Defaults
  @ Timers operate slightly differently to SysTick:
  @ - SysTick counts down from a reload value to 0
  @ - Timers count up from 0 and can have multiple trigger points
  @ - Timers do not necessarily reset when they hit trigger points, this is something that can be configured
  @ - To read ther current value of a timer we need to trigger a "value capture" event
  @ - SysTick counts at a rate of 64MHz when attached to the CPU clock
  @ - Timers count at a rate of 16MHz by default, and have further configuration with a prescaler (explained below)
  @ TIMERX counts at a rate of 16MHz (1/4 of the cpu speed, so it counts by 1 every 4 cpu clock cycles)
  @ TIMERX also has a prescaler which changes the *actual* count rate (how much it will count up in 1 second) by the formula:
  @ fTIMER = 16 MHz / (2^PRESCALER)
  @ A nice default for the PRESCALER is 4, this gives us a 1000000Hz count rate, or simply each counter increment = 1 microsecond
  push {lr}
  @@ Set to timer mode
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_MODE
  mov r2, 0
  str r2, [r0, r1]

  @ Set TIMER count value to 32bit mode
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_BITMODE
  mov r2, 3
  str r2, [r0, r1]

  @ Set prescaler to 4 to get a 1 microsecond interrupt granularity
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_PRESCALER
  mov r2, 4
  str r2, [r0, r1]

  @ Clear the internal timer count register
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_TASKS_CLEAR
  mov r2, 1
  str r2, [r0, r1]

  @ Set compare event0 to trigger a clear of the timer value 
  @ (this basically means when the timer counts up to the value in CC0 it resets the count to 0 automatically)
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_SHORTS
  mov r2, 0
  bl set_bit

  @ Enable Interrupt on timer compare(0)
  ldr r0, =ADR_TIMER0
  ldr r1, =OFS_TIMER_ITENSET
  mov r2, (0b1 << 16)
  str r2, [r0, r1]

  @ Enable TIMER0 Interrupt (interrupt #8 = TIMER0_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_ISER0
  mov r2, 8
  bl set_bit
  pop {lr}
  bx lr
.size init_TIMER0, .-init_TIMER0

configure_priorities:
  push {lr}
  @@@@ Configure interrupt priorities
  @ GPIO > Systick > Timer
  @@ GPIOTE to priority 0
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_IPR1
  add r0, r1
  mov r1, 0
  mov r2, 21
  mov r3, 3
  bl copy_bits

  @@ Systick to priority 1
  ldr r0, =ADR_SCB_SHPR3
  mov r1, 1
  mov r2, 29
  mov r3, 3
  bl copy_bits

  @ TIMER0 to priority 2
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_IPR2
  add r0, r1
  mov r1, 2
  mov r2, 5
  mov r3, 3
  bl copy_bits
  pop {lr}
  bx lr

.type sync, %function
@ Sometimes we just wanna wait a bit to make sure memory triggered operations 
@ run to completion before we continue.
sync:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  bx lr
.size sync, .-sync

.type disable_GPIOTE, %function
@ Disables the GPIOTE interrupt.
@ --parameters--
@ none
disable_GPIOTE:
  @ Disable this interrupt
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_INTENCLR
  mov r2, 0b1
  str r2, [r0, r1] @ write to disable
  bx lr
.size disable_GPIOTE, .-disable_GPIOTE