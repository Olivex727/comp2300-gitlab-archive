---
title: "COMP2300 Assignment 1 Design Document"
author: Olivia Walters
email: u7280249@anu.edu.au
---

# Program Files

Note that several files were created and used to help make a more modular and readable solution. The Assembly (`.S`) files that were created and/or modified by myself are listed below:
- `src/main.S`
- `lib/display.S`
- `lib/game_of_life.S`
- `lib/reader.S`

Elaboration on the purpose of each file is under the 'Program Structure' header.

# Project Description

## Conway's Game of Life

[Conway's Game of Life (GOL)](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) is a cellular automaton that involves a grid of 'cells' and instructions on how to evolve the grid. I chose such a design because it allowed for generative patterns.

The program is designed to automatically step through a pre-set series of seed states for GOL and display the current state of the game at each step.

## Microbit LED Display

The LEDs are lit up using a [rolling shutter] method, fast enough to make the image appear as static. This is the most efficient way to design - pixel-by-pixel is more complicated, all at once is impossible.

## Meeting Requirements

To meet the requirements, it is not enough to generate on a single seed state, which is why the program will read new seeds from memory after the previous seed state has run its course. This allows for unique pattern light patterns.

# Program Structure

## Overall Structure (Top-Down Modular Design)

The structure of the project forms a Control-Model-Viewer system. The central aspect of the project is the value in `r12`. This register stores the state of the current 'game' and is sectioned as below:

![Encoding String Diagram](./assets/COMP2300%20Encoding%20String.jpg)

The state is read independently by all three modules, with `game_of_life` and `reader` modifying the value of `r12`.

The `game_of_life` module is responsible for updating the state according to GOL. The `display` module uses the first 25 bits of the state in printing a pattern on the 25-LED microbit. The `reader` module manages the stored seed states in memory and handles the state's metadata.

All three modules are ran consecutively. A majority of the program's time is spent keeping the display on.

## Display Module

The `display` uses three nested loops. The first determines how long the display will be on for before iterating to the next GOL state. This requires reading `r12`. The time unit used is of arbitrary length ~0.25 seconds.

The second displays column by column. This is done by setting the DIR values to 'output' for only the current column. The inner loop goes through each row in the column and turns on the OUT pin if the row is supposed to be on. Several functions are used to simplify the process: setting specific bits in the GPIO; clearing the DIR/OUT; turning on column and row pins.

## Game of Life Module

`game_of_life` uses one loop to determine if each pixel is 'dead' or 'alive' in the next iteration of the game of life. The `ring` function checks a ring around the bit by converting the bit into an (x,y) co-ordinate and checking the values of all 8 surrounding bits.

The game state specifies whether the boundary cells are considered 'immortal' or 'perma-dead'. This means that cells on the border always have three live or dead neighbors.

## Special Data Structures

All seed states are stored in a int32 array, the program calls the next seed after the previous one has been executed. When the maximum value is reached, the array loops back.

The pin of each row is kept in a byte map i.e. Row 1 -> Pin 21.