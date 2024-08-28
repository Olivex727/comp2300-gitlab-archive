.syntax unified
.global main

.type main, %function
main:
  ldr r12, =0x400000

  bl init_leds

  bl text_to_morse
  b loop

.size main, .-main

loop:
  nop
  b loop

text_to_morse:
  push {lr}

  ldr r10, =input_string
  ldr r9, =input_end

  sub r9, r10
  sub r9, 1

text_reader_loop:
  ldrb r0, [r10]
  add r10, 1

  bl ascii_to_morse
  bl blink_codepoint

  subs r9, 1
  beq text_reader_exit
  b text_reader_loop

text_reader_exit:
  pop {lr}
  bx lr

@ Takes r0 as input, stores in memory
ascii_to_morse:
  push {lr, r1-r2, r8-r12}

  ldr r2, =morse_table

  sub r0, 65
  mov r1, 24
  mla r0, r0, r1, r2

  ldmia r0!, {r8-r12}

  ldr r1, =thing

  stmia r1!, {r8-r12}

  pop {lr, r1-r2, r8-r12}
  bx lr

blink_codepoint:
  push {lr}

  ldr r0, =thing
  ldr r1, [r0], 4
  mov r2, 0
  
blink_codepoint_loop:
  ldr r3, [r0], 4
  cmp r3, 1
  beq blink_codepoint_dash
  bne blink_codepoint_dot

blink_codepoint_dash:
  bl blink_dash
  b blink_codepoint_endif

blink_codepoint_dot:
  bl blink_dot
  b blink_codepoint_endif

blink_codepoint_endif:
  mov r11, 3
  bl delay

  add r2, 1
  cmp r1, r2
  beq blink_codepoint_exit

  b blink_codepoint_loop

blink_codepoint_exit:
  pop {lr}
  bx lr


dot:
  push {lr}

  bl blink_dot
  bl blink_space

  pop {lr}
  bx lr

dash:
  push {lr}

  bl blink_dash
  bl blink_space

  pop {lr}
  bx lr

blink_dot:
  push {lr}

  bl turn_on_led
  mov r11, 1
  bl delay
  bl turn_off_led

  pop {lr}
  bx lr

blink_dash:
  push {lr}

  bl turn_on_led
  mov r11, 3
  bl delay
  bl turn_off_led
  
  pop {lr}
  bx lr

blink_space:
  push {lr}

  mov r11, 7
  bl delay

  pop {lr}
  bx lr

turn_on_led:
  push {lr, r0-r3}

  mov r0, 0
  ldr r1, =OFS_GPIO_OUT
  mov r2, 1
  bl write_row_pin

  mov r0, 0
  ldr r1, =OFS_GPIO_OUT
  mov r2, 0
  bl write_column_pin
  
  pop {lr, r0-r3}
  bx lr

turn_off_led:
  push {lr, r0-r3}

  mov r0, 0
  ldr r1, =OFS_GPIO_OUT
  mov r2, 0
  bl write_row_pin

  mov r0, 0
  ldr r1, =OFS_GPIO_OUT
  mov r2, 0
  bl write_column_pin
  
  pop {lr, r0-r3}
  bx lr

@ r11: length of delay in standard delay units, becomes zero
delay:
  push {lr}
delay_main_loop:
  bl standard_delay
  subs r11, 1
  beq delay_main_exit
  b delay_main_loop
delay_main_exit:
  pop {lr}
  bx lr

standard_delay:
  push {lr, r12}
delay_loop:
  subs r12, 1
  beq delay_exit
  b delay_loop
delay_exit:
  pop {lr, r12}
  bx lr

.data
thing:
  .word 40, 0, 0, 0, 0 @ The letter X

.data
input_string:
  .asciz "OLIVIA"
input_end:
  .word 0

@ to make sure our table starts on a word boundary
.align 2

@ Each entry in the table is 6 words long
@ - The first word is the number of dots and dashes for this entry
@ - The next 5 words are 0 for a dot, 1 for a dash, or padding (value doesn't matter)
@
@ E.g., 'G' is dash-dash-dot. There are 2 extra words to pad the entry size to 6 words
morse_table:
  .word 2, 0, 1, 0, 0, 0 @ A
  .word 4, 1, 0, 0, 0, 0 @ B
  .word 4, 1, 0, 1, 0, 0 @ C
  .word 3, 1, 0, 0, 0, 0 @ D
  .word 1, 0, 0, 0, 0, 0 @ E
  .word 4, 0, 0, 1, 0, 0 @ F
  .word 3, 1, 1, 0, 0, 0 @ G
  .word 4, 0, 0, 0, 0, 0 @ H
  .word 2, 0, 0, 0, 0, 0 @ I
  .word 4, 0, 1, 1, 1, 0 @ J
  .word 3, 1, 0, 1, 0, 0 @ K
  .word 4, 0, 1, 0, 0, 0 @ L
  .word 2, 1, 1, 0, 0, 0 @ M
  .word 2, 1, 0, 0, 0, 0 @ N
  .word 3, 1, 1, 1, 0, 0 @ O
  .word 4, 0, 1, 1, 0, 0 @ P
  .word 4, 1, 1, 0, 1, 0 @ Q
  .word 3, 0, 1, 0, 0, 0 @ R
  .word 3, 0, 0, 0, 0, 0 @ S
  .word 1, 1, 0, 0, 0, 0 @ T
  .word 3, 0, 0, 1, 0, 0 @ U
  .word 4, 0, 0, 0, 1, 0 @ V
  .word 3, 0, 1, 1, 0, 0 @ W
  .word 4, 1, 0, 0, 1, 0 @ X
  .word 4, 1, 0, 1, 1, 0 @ Y
  .word 4, 1, 1, 0, 0, 0 @ Z