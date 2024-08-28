---
title: "Design Proposal"
author: Olivia Walters
email: u7280249@anu.edu.au
---

<!-- write your design proposal here -->

Light Show - Conway's Game of Life

What do I want to build?

Conway's Game of Life (GOL) is a set of rules that dictate the behaviours of cells on a screen. It involves veiwing the LED light cells as 'alive' or 'dead'.

Essentially, what the goal of the Assignment, for me personally, is to develop and display GOL simulations on the Microbit's 5x5 light board. I would begin with seed values and iterate through GOL instructions to create an intresting light display.

GOL is classically unlimited in it's dimensions, however the 5x5 limitation is an opportunity to create a different version of the game. I may also use the speakers to indicate steps through each iteration.

How will I build it?

Cells in the game are either on or off, so an entire seed can be stored in 25 bits (less than single register). Adding additional instructions (e.g. speed of iteration, max iterations, borders are considered dead or alive) can be used with the extra room.

A series of seeds will be stored in memory, and would be pulled progressively to be iterated on, the state of the game being stored in a single register. The use of nested looping (in abstracted terms) would be used to iterate on individual cells, this would be done via bitwise manipulation.