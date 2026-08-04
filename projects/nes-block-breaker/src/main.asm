.include "header.asm"

.bank 0
.org $8000

RESET:
Forever:
    JMP Forever

.bank 1
.org $FFFA

.dw 0
.dw RESET
.dw 0
