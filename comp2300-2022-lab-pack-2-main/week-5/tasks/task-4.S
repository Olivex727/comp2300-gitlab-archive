.syntax unified
.global main

.type main, %function
main:
  bl audio_init
  mov r5, #0
loop:
  add r5, #1 @ increment r5
  lsr r0, r5, #10
  and r0, #100
  mul r0, r0, r5
  push {r5}
  bl audio_play_sample
  pop {r5}
  b loop
.size main, .-main