# NES Block Breaker

`projects/nes-block-breaker` is a minimal but complete NES block breaking game built with the real ClusterM/nesasm assembler.

## Build

```sh
make -C projects/nes-block-breaker
```

The build produces `projects/nes-block-breaker/build/main.nes`.

For a clean rebuild:

```sh
make -C projects/nes-block-breaker clean
make -C projects/nes-block-breaker
```

## Controls

- **START**: Start the game from the title screen.
- **Left / Right**: Move the paddle during play.
- **START**: Return from the CLEAR or GAME OVER screen to the title screen.

START is handled as a newly pressed input so holding it does not intentionally skip through multiple screens.

## Rules

- Break all 24 blocks with the ball to clear the game.
- Each destroyed block adds 1 point.
- Missing the ball at the bottom of the screen causes GAME OVER.
- Starting a new play resets the score, paddle, ball, and all blocks.

## Current specification

- Game states are separated into TITLE, PLAY, CLEAR, and GAME OVER.
- The title keeps the simple black background and white text presentation, with a blinking PRESS START prompt.
- The playfield uses a centered score display, three rows of blocks, a six-tile paddle, and a single ball.
- Ball movement reflects from the left, right, and top walls; paddle hits change the horizontal direction based on the hit position.
- Block, paddle, wall, miss, start, and clear events trigger short APU pulse sound effects.
- PPU nametable updates are performed after waiting for VBlank, and full screen transitions are done with rendering disabled to avoid half-drawn screens.

## Human verification checklist

The ROM builds successfully in this environment, but final feel and visual output should still be checked in an NES emulator or on hardware:

- Confirm title, play, clear, game over, and return-to-title flow visually.
- Confirm paddle movement latency and screen-edge clamping.
- Confirm ball speed feels fair for first-time players.
- Confirm block collisions and scoring match the visible block positions.
- Confirm sound effects are audible and distinct on the target emulator or hardware.
