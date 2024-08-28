---
title: "Design Proposal"
author: "Olivia Walters"
email: "u7280249@anu.edu.au"
---

# The GOL: Pet Edition

## What will I build?

In Assignment 1, I wrote a light show that generated patterns from Conway's Game of Life (GOL). This provides as an interesting base for what I can write my Assignment 2 pet to be - making the light show the pet itself.

The microbit will display a constantly iterating GOL program that iterates every second or so. When the GOL board ends in a blank state, the pet is considered 'dead', and it will make some sort of sound.

Inputs can be used to affect the pet, here are some of the suggestions:
Button A = Reset/New pet
Button B = Turn on border cells (to 'revive' a pet)

## How will I accomplish it?

My assignment will incorporates a lot of used code, building up on it to create an interesting pet. This code will be manipulated: the display will take advantage of the SysTick interrupt, and the reader will manipulate how the program reads new states from memory/registers.

Incorporating old code does not make things simpler, the main focus of the assignment is using interrupts, and I will need to differentiate between GPIO interrupts in ways that don't break the memory operations.