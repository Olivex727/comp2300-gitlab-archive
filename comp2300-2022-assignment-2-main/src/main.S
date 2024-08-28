.syntax unified
.global main

.type main, %function
main:
  @b death
  ldr r0, =1000 @ Each LED column stays on for 1000 cycles
  bl enable_timer
  bl enable_GPIOTE

  b main_loop
.size main, .-main

@ --------------------- Main Program Loops and Checking -------------------- @

.global main_loop
@ The main loop is the alive state
main_loop:
  mov r0, 0
  bl audio_play_sample
  b check_death


.global death
@ The dead state will erase lr
death:
  bl audio_init
  mov r5, #0
death_loop:
  add r5, #1
  lsr r0, r5, #9
  and r0, #162
  mul r0, r0, r5
  push {r5}
  bl audio_play_sample
  pop {r5}
  b check_death
.size main, .-main

@ Check death will either put the program into the alive or dead state
check_death:
  ldr r0, =current
  ldr r1, [r0]

  @ Extract the board state
  ldr r2, =0x1FFFFFF
  and r1, r2

  cmp r1, 0
  beq death_init
  bne alive_init

@ Initialise the program into the dead state
death_init:
  ldr r0, =program_state
  ldr r1, [r0]

  @ If the program is in the dead state, go to back to the loop
  @ If previously alive, initialise death
  cmp r1, 0
  it eq
  addeq r1, 1
  bne death_loop

  str r1, [r0]

  @ Disengage the timer
  bl disable_timer

  @ Disengage the display
  bl clear_dir

  b death

@ Initialise the program into the alive state
alive_init:
  ldr r0, =program_state
  ldr r1, [r0]

  @ If the program is in the alive state, go to back to the loop
  @ If previously alive, initialise revival before heading to main
  cmp r1, 1
  it eq
  subeq r1, 1
  bne main_loop

  str r1, [r0]

  @ Reset timer and some memory
  bl reset_all

  b main_loop

shut_up_speaker:
  push {lr}

  mov r5, 200
shut_up_loop:
  mov r0, 0
  bl audio_play_sample
  subs r5, 0
  bne shut_up_loop

  pop {lr}
  bx lr

@ --------------------- Event Handlers -------------------- @

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.set SHPR3, 0xE000ED20

@ SYSTICK HANDLER - OPERATES DISPLAY
.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {lr, r12}
  
  @ Load the current display counter and push to stack to backup
  ldr r0, =timer_counter
  ldr r1, [r0]
  ldr r2, [r0, 4]
  push {r0-r2}

  @ If the display counter is zero, activate the game_of_life module instead of the display
  cmp r1, 0
  it le
  blle game_of_life
  it gt
  blgt display_entry
  
  @ Reduce the display counter, flipping it to the static counter value if zero
  pop {r0-r2}
  cmp r1, 0
  ite gt
  subgt r1, 1
  movle r1, r2
  
  @ Store the dynamic counter back and exit
  @ Safe Store, don't decrement if GPIOTE has been reset
  bl GPIOTE_flag_store

  @ Flag SysTick interrupt - will be shut off when requested
  ldr r0, =interrupt_flag
  mov r1, 1
  str r1, [r0, 4]

  @ Clear GPIOTE flag, as memory is now safe
  bl reset_GPIOTE_flag

  pop {lr, r12}
  bx lr
.size SysTick_Handler, .-SysTick_Handler

@ GPIOTE HANDLER - AFFECTS STATE
.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {lr}

  @ Inputs/Interrupts Used:
  @ Button A - Reset the Pet by updating to the next seed state
  @ Button B - Turn on/off the border state

  @ The buttons must prevent GOL/Display operations immediately,
  @ as to prevent the Systick handler from overwriting memory.

  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, [r0]
  ldr r2, =GPIOTE_EVENTS_IN1
  ldr r3, [r2]

  cmp r1, 1
  beq button_A
  b no_button_A

  @ Button A [Channel 0] - Reset pet (reader module)
button_A:
  bl load_seed

no_button_A:
  cmp r3, 1
  beq button_B
  b no_button_B

  @ Button B [Channel 1] - Toggle Speed (reader module)
button_B:
  @ Do nothing if the program is in the dead state
  ldr r0, =program_state
  ldr r1, [r0]
  cmp r1, 1
  beq no_button_B

  bl toggle_speed

no_button_B:
  @ clear event
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]
  ldr r0, =GPIOTE_EVENTS_IN1
  str r1, [r0]
  nop

  @ Flag GPIOTE interrupt - will be shut off when requested
  ldr r0, =interrupt_flag
  mov r1, 1
  str r1, [r0]
  
  pop {lr}
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

@ --------------------- Interrupt Management -------------------- @

.global enable_timer
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

@ Clears all timer data
.global disable_timer
disable_timer:
  push {lr}
  ldr r0, =ADR_SYST_CSR
  ldr r1, [r0]

  mov r2, 0b111
  bic r1, r2

  str r1, [r0]

  ldr r0, =ADR_SYST_RVR
  mov r1, 0
  str r1, [r0]
  pop {lr}
  bx lr

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

@ --------------------- Central Program Memory -------------------- @

.data
.global current
.global states
.global end_states
@ Current Game State - removes use of r12
current:
  @       IIIISSB|....|....|....|....|....
  .word 0b00000000000000000000000000000000, 0 @ Current state; Array index of next state; Speed of State

@ Array of Possible GOL States
states:
  @ Old Seed States pulled from Assignment 1
  @       B|....|....|....|....|.... @ Metadata
  @        ABCDEFGHIJKLMNOBQRSTUVWXY @ 25-LED Board
  .word 0b01111111111111111111111111
  .word 0b00100011100110100100000000
  .word 0b00000000111010000011100000
  .word 0b11000010000100001000010000
  .word 0b10000011111000001111100000
  .word 0b01010110001010101100110001
  .word 0b01010110001010101100110001
  .word 0b00000001100011100100000000
  .word 0b00000001100011100110000000
  .word 0b10000001110011100110000000
  .word 0b11000001000001000001000001
  .word 0b00010000100110110101011011
  .word 0b01000001000001000001000001

  @ New Seed States I randomly came up with
  .word 0x2F67BB2
  .word 0x1C12E11
  .word 0x0F45E44
  .word 0x00101F1
  .word 0x3ECECC6
  .word 0x182781F
  .word 0x28DEAB7
  .word 0x3234567
  .word 0x1EDCBA9
  .word 0x3876543
  .word 0x1242420
  .word 0x300E0E1
end_states:
  nop

@ The interrupt handlers have to exit back to their last location. However,
@ this may cause memory issues if the the interrupt was called directly before
@ the GOL or display modules were going to alter the memory states. So
@ everytime an interrupt is called, a flag will be set until it's been cleared
@ manually.
interrupt_flag:
  .word 0, 0 @ GPIOTE Flag, SysTick Flag

@ Stored the current pet's state - dead or alive?
program_state:
  .word 0 @ 0 = Alive, 1 = Dead

@ --------------------- Interrupt Flag Manipulation -------------------- @

.text
@ Flag check functions are to be polled manually

.global GPIOTE_flag_store
@ Check that the GPIOTE interrupt has been called, stop memory storage
@ GPIOTE is high-prioirty but DO NOT CALL IF IN READER
@ Safely stores values into memory if the GPIOTE has not been called
@ Parameters: r0 - Adress of storage, r1 - Value of storage
GPIOTE_flag_store:
  push {lr}
  ldr r2, =interrupt_flag
  ldr r3, [r2]

  push {r4}
  @ Clear the flag regardless
  mov r4, 0
  str r4, [r2]
  pop {r4}

  @ Check if the flag (before clearing) was set
  cmp r3, 0
  beq store
  b exit_safe_store

store:
  str r1, [r0]

exit_safe_store:
  pop {lr}
  bx lr

.global reset_GPIOTE_flag
@ Resets the GPIOTE flag prematurely
reset_GPIOTE_flag:
  push {lr}
  ldr r0, =interrupt_flag

  @ Clear the flag regardless
  mov r1, 0
  str r1, [r0]

  pop {lr}
  bx lr