    .include "header.asm"

    .bank 0
    .org $C000

RESET:
    sei
    cld

    ldx #$40
    stx $4017

    ldx #$FF
    txs
    inx

    stx $2000
    stx $2001
    stx $4010

WaitVBlank1:
    bit $2002
    bpl WaitVBlank1

WaitVBlank2:
    bit $2002
    bpl WaitVBlank2

    ; 背景色を黒に設定
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    lda #$0F
    sta $2007

    ; PPUアドレスをパレット領域外へ戻す
    lda #$00
    sta $2006
    sta $2006

Forever:
    jmp Forever

NMI:
    rti

IRQ:
    rti

    .bank 1
    .org $FFFA

    .dw NMI
    .dw RESET
    .dw IRQ