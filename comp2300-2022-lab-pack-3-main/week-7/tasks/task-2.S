.syntax unified
.global main

.type main, %function
main:
  ldr r12, =0x400000

  bl init_leds

  bl blink_codepoint
  b loop

.size main, .-main

loop:
  nop
  b loop


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
  .word 4, 1, 0, 0, 1 @ The letter X