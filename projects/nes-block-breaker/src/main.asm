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

    jsr LoadTitleFont
    jsr LoadTitlePalette
    jsr ClearNameTable
    jsr DrawTitleText

    ; 背景表示を有効化する。
    lda #%00000000
    sta $2000
    lda #%00001000
    sta $2001

TitleLoop:
    jsr ReadController
    lda ControllerState
    and #BUTTON_START
    beq TitleLoop

    jsr ShowGameScreen

GameLoop:
    jmp GameLoop

ShowGameScreen:
    ; 描画中のちらつきを避けるため、画面を一度OFFにする。
    lda #%00000000
    sta $2001

WaitGameVBlank:
    bit $2002
    bpl WaitGameVBlank

    jsr ClearNameTable
    jsr DrawGameObjects

    lda #%00000000
    sta $2000
    lda #%00001000
    sta $2001
    rts

ReadController:
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    sta ControllerState
    ldx #$08
ReadControllerLoop:
    lda $4016
    lsr a
    rol ControllerState
    dex
    bne ReadControllerLoop
    rts

LoadTitlePalette:
    ; 背景は黒、文字は白。将来用に青と灰色も定義する。
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    ldx #$00
LoadTitlePaletteLoop:
    lda TitlePalette, x
    sta $2007
    inx
    cpx #$04
    bne LoadTitlePaletteLoop
    rts

ClearNameTable:
    ; Nametable $2000-$23BF と Attribute $23C0-$23FF を0で埋め、黒背景にする。
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #$00
    ldx #$04
ClearNameTablePage:
    ldy #$00
ClearNameTableLoop:
    sta $2007
    iny
    bne ClearNameTableLoop
    dex
    bne ClearNameTablePage
    rts

LoadTitleFont:
    ; CHR RAMへタイトルに必要な最小限の8x8タイルだけを転送する。
    lda #$00
    sta $2006
    sta $2006
    ldx #$00
LoadTitleFontLoop:
    lda TitleFont, x
    sta $2007
    inx
    cpx #TitleFontEnd - TitleFont
    bne LoadTitleFontLoop
    rts

DrawGameObjects:
    ; 画面上部に3段x10個のブロックを仮配置する。
    lda #$20
    sta $2006
    lda #$86
    sta $2006
    jsr DrawBlockRow

    lda #$20
    sta $2006
    lda #$A6
    sta $2006
    jsr DrawBlockRow

    lda #$20
    sta $2006
    lda #$C6
    sta $2006
    jsr DrawBlockRow

    ; パドルの少し上、中央にボールを置く。
    lda #$23
    sta $2006
    lda #$0F
    sta $2006
    lda #TILE_BALL
    sta $2007

    ; 画面下部中央に6タイル幅のパドルを置く。
    lda #$23
    sta $2006
    lda #$4D
    sta $2006
    ldx #$06
DrawPaddleLoop:
    lda #TILE_PADDLE
    sta $2007
    dex
    bne DrawPaddleLoop

    lda #$00
    sta $2006
    sta $2006
    rts

DrawBlockRow:
    ldx #$0A
DrawBlockRowLoop:
    lda #TILE_BLOCK
    sta $2007
    inx
    lda #TILE_BLANK
    sta $2007
    dex
    dex
    bne DrawBlockRowLoop
    rts

DrawTitleText:
    ; BLOCK BREAKER: 13文字、32列画面の中央（開始列9）。
    lda #$21
    sta $2006
    lda #$89
    sta $2006
    ldx #$00
DrawMainTitleLoop:
    lda MainTitle, x
    sta $2007
    inx
    cpx #MainTitleEnd - MainTitle
    bne DrawMainTitleLoop

    ; PRESS START: 11文字、中央（開始列10）。
    lda #$22
    sta $2006
    lda #$0A
    sta $2006
    ldx #$00
DrawPressStartLoop:
    lda PressStartText, x
    sta $2007
    inx
    cpx #PressStartTextEnd - PressStartText
    bne DrawPressStartLoop

    ; PPUアドレスをパレット領域外へ戻す。
    lda #$00
    sta $2006
    sta $2006
    rts

TitlePalette:
    .db $0F, $30, $11, $00

TILE_BLANK = $00
TILE_A     = $01
TILE_B     = $02
TILE_C     = $03
TILE_E     = $04
TILE_K     = $05
TILE_L     = $06
TILE_O     = $07
TILE_P     = $08
TILE_R     = $09
TILE_S     = $0A
TILE_T     = $0B
TILE_PADDLE = $0C
TILE_BALL   = $0D
TILE_BLOCK  = $0E

BUTTON_START = %00010000
ControllerState = $00

MainTitle:
    .db TILE_B, TILE_L, TILE_O, TILE_C, TILE_K, TILE_BLANK
    .db TILE_B, TILE_R, TILE_E, TILE_A, TILE_K, TILE_E, TILE_R
MainTitleEnd:

PressStartText:
    .db TILE_P, TILE_R, TILE_E, TILE_S, TILE_S, TILE_BLANK
    .db TILE_S, TILE_T, TILE_A, TILE_R, TILE_T
PressStartTextEnd:

TitleFont:
    ; blank
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; A
    .db %00111100, %01100110, %01100110, %01111110
    .db %01100110, %01100110, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; B
    .db %01111100, %01100110, %01100110, %01111100
    .db %01100110, %01100110, %01111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; C
    .db %00111100, %01100110, %01100000, %01100000
    .db %01100000, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; E
    .db %01111110, %01100000, %01100000, %01111100
    .db %01100000, %01100000, %01111110, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; K
    .db %01100110, %01101100, %01111000, %01110000
    .db %01111000, %01101100, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; L
    .db %01100000, %01100000, %01100000, %01100000
    .db %01100000, %01100000, %01111110, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; O
    .db %00111100, %01100110, %01100110, %01100110
    .db %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; P
    .db %01111100, %01100110, %01100110, %01111100
    .db %01100000, %01100000, %01100000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; R
    .db %01111100, %01100110, %01100110, %01111100
    .db %01111000, %01101100, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; S
    .db %00111100, %01100110, %01100000, %00111100
    .db %00000110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; T
    .db %01111110, %00011000, %00011000, %00011000
    .db %00011000, %00011000, %00011000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; paddle
    .db %11111111, %11111111, %11111111, %11111111
    .db %11111111, %11111111, %11111111, %11111111
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; ball
    .db %00111100, %01111110, %11111111, %11111111
    .db %11111111, %11111111, %01111110, %00111100
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
    ; block
    .db %11111111, %10000001, %10111101, %10111101
    .db %10111101, %10111101, %10000001, %11111111
    .db %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000
TitleFontEnd:

NMI:
    rti

IRQ:
    rti

    .bank 1
    .org $FFFA

    .dw NMI
    .dw RESET
    .dw IRQ
