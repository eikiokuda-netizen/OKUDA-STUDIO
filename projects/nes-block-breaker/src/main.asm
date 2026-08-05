    .include "header.asm"

STATE_TITLE = $00
STATE_PLAY  = $01
STATE_CLEAR = $02
STATE_OVER  = $03

BUTTON_START = %00010000
BUTTON_LEFT  = %00000010
BUTTON_RIGHT = %00000001

TILE_BLANK  = $00
TILE_A      = $01
TILE_B      = $02
TILE_C      = $03
TILE_D      = $04
TILE_E      = $05
TILE_F      = $06
TILE_G      = $07
TILE_H      = $08
TILE_I      = $09
TILE_K      = $0A
TILE_L      = $0B
TILE_M      = $0C
TILE_N      = $0D
TILE_O      = $0E
TILE_P      = $0F
TILE_R      = $10
TILE_S      = $11
TILE_T      = $12
TILE_U      = $13
TILE_V      = $14
TILE_0      = $15
TILE_1      = $16
TILE_2      = $17
TILE_3      = $18
TILE_4      = $19
TILE_5      = $1A
TILE_6      = $1B
TILE_7      = $1C
TILE_8      = $1D
TILE_9      = $1E
TILE_PADDLE = $1F
TILE_BALL   = $20
TILE_BLOCK  = $21

PADDLE_MIN = $08
PADDLE_MAX = $C0
PADDLE_Y   = $D8
BALL_MIN_X = $08
BALL_MAX_X = $F0
BALL_MIN_Y = $18
BALL_LOST_Y = $E8
BLOCK_COUNT = $18

GameState       = $00
ControllerState = $01
ControllerPrev  = $02
ControllerPress = $03
FrameCounter    = $04
PaddleX         = $05
BallX           = $06
BallY           = $07
BallDX          = $08
BallDY          = $09
PrevBallHigh    = $0A
PrevBallTile    = $0B
PrevPaddleTile  = $0C
Temp            = $0D
Temp2           = $0E
ScoreOnes       = $0F
ScoreTens       = $10
BlocksLeft      = $11
BlockHitIndex   = $12

Blocks          = $0200

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
    jsr WaitVBlank
    jsr WaitVBlank
    jsr LoadFont
    jsr LoadPalette
    jsr ClearNameTable
    jsr DrawTitleScreen
    lda #STATE_TITLE
    sta GameState
    jsr EnableScreen

MainLoop:
    jsr WaitVBlank
    jsr ReadController
    lda GameState
    cmp #STATE_TITLE
    beq StateTitle
    cmp #STATE_PLAY
    beq StatePlay
    cmp #STATE_CLEAR
    beq StateResult
    jmp StateResult

StateTitle:
    jsr UpdateTitleBlink
    lda ControllerPress
    and #BUTTON_START
    beq MainLoop
    jsr StartGame
    jmp MainLoop

StateResult:
    lda ControllerPress
    and #BUTTON_START
    beq MainLoop
    jsr ShowTitleScreen
    jmp MainLoop

StatePlay:
    jsr UpdatePaddle
    jsr UpdateBall
    lda GameState
    cmp #STATE_PLAY
    bne MainLoop
    jsr DrawPlayFrame
    jmp MainLoop

WaitVBlank:
    bit $2002
WaitVBlankLoop:
    bit $2002
    bpl WaitVBlankLoop
    rts

EnableScreen:
    lda #%00000000
    sta $2000
    lda #%00001000
    sta $2001
    rts

DisableScreen:
    lda #%00000000
    sta $2001
    rts

ReadController:
    lda ControllerState
    sta ControllerPrev
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
    lda ControllerPrev
    eor #$FF
    and ControllerState
    sta ControllerPress
    rts

ShowTitleScreen:
    jsr DisableScreen
    jsr WaitVBlank
    jsr ClearNameTable
    jsr DrawTitleScreen
    lda #STATE_TITLE
    sta GameState
    lda #$00
    sta FrameCounter
    jsr EnableScreen
    rts

StartGame:
    jsr DisableScreen
    jsr WaitVBlank
    jsr InitGameData
    jsr ClearNameTable
    jsr DrawPlayScreen
    jsr SfxStart
    lda #STATE_PLAY
    sta GameState
    jsr EnableScreen
    rts

InitGameData:
    lda #$68
    sta PaddleX
    sta PrevPaddleTile
    lda #$23
    sta PrevBallHigh
    lda #$00
    sta PrevBallTile
    lda #$78
    sta BallX
    lda #$C8
    sta BallY
    lda #$02
    sta BallDX
    lda #$FE
    sta BallDY
    lda #$00
    sta ScoreOnes
    sta ScoreTens
    sta FrameCounter
    lda #BLOCK_COUNT
    sta BlocksLeft
    ldx #$00
InitBlocksLoop:
    lda #$01
    sta Blocks, x
    inx
    cpx #BLOCK_COUNT
    bne InitBlocksLoop
    rts

UpdateTitleBlink:
    inc FrameCounter
    lda FrameCounter
    and #%00100000
    beq DrawPressVisible
    lda #$22
    sta $2006
    lda #$0A
    sta $2006
    ldx #$0B
HidePressLoop:
    lda #TILE_BLANK
    sta $2007
    dex
    bne HidePressLoop
    jsr ResetPpuAddr
    rts
DrawPressVisible:
    lda #$22
    sta $2006
    lda #$0A
    sta $2006
    ldx #$00
DrawPressBlinkLoop:
    lda PressStartText, x
    sta $2007
    inx
    cpx #PressStartTextEnd - PressStartText
    bne DrawPressBlinkLoop
    jsr ResetPpuAddr
    rts

UpdatePaddle:
    lda ControllerState
    and #BUTTON_LEFT
    beq CheckRight
    lda PaddleX
    cmp #PADDLE_MIN
    beq CheckRight
    sec
    sbc #$03
    cmp #PADDLE_MIN
    bcs StorePaddleLeft
    lda #PADDLE_MIN
StorePaddleLeft:
    sta PaddleX
CheckRight:
    lda ControllerState
    and #BUTTON_RIGHT
    beq UpdatePaddleDone
    lda PaddleX
    cmp #PADDLE_MAX
    beq UpdatePaddleDone
    clc
    adc #$03
    cmp #PADDLE_MAX
    bcc StorePaddleRight
    lda #PADDLE_MAX
StorePaddleRight:
    sta PaddleX
UpdatePaddleDone:
    rts

UpdateBall:
    lda BallX
    clc
    adc BallDX
    sta BallX
    lda BallY
    clc
    adc BallDY
    sta BallY
    lda BallX
    cmp #BALL_MIN_X
    bcs CheckRightWall
    lda #BALL_MIN_X
    sta BallX
    lda #$02
    sta BallDX
    jsr SfxPaddle
CheckRightWall:
    lda BallX
    cmp #BALL_MAX_X
    bcc CheckTopWall
    lda #BALL_MAX_X
    sta BallX
    lda #$FE
    sta BallDX
    jsr SfxPaddle
CheckTopWall:
    lda BallY
    cmp #BALL_MIN_Y
    bcs CheckPaddleHit
    lda #BALL_MIN_Y
    sta BallY
    lda #$02
    sta BallDY
    jsr SfxPaddle
CheckPaddleHit:
    lda BallDY
    bmi CheckBlocks
    lda BallY
    cmp #PADDLE_Y - $08
    bcc CheckLost
    cmp #PADDLE_Y + $08
    bcs CheckLost
    lda BallX
    sec
    sbc PaddleX
    cmp #$31
    bcs CheckLost
    lda #$FE
    sta BallDY
    lda BallX
    sec
    sbc PaddleX
    cmp #$10
    bcc PaddleLeftBounce
    cmp #$20
    bcc PaddleCenterBounce
    lda #$02
    sta BallDX
    jmp PaddleBounceDone
PaddleLeftBounce:
    lda #$FE
    sta BallDX
    jmp PaddleBounceDone
PaddleCenterBounce:
    lda BallDX
    bne PaddleBounceDone
    lda #$02
    sta BallDX
PaddleBounceDone:
    jsr SfxPaddle
CheckLost:
    lda BallY
    cmp #BALL_LOST_Y
    bcc CheckBlocks
    jsr ShowGameOverScreen
    rts
CheckBlocks:
    jsr CheckBlockCollision
    rts

CheckBlockCollision:
    lda #$FF
    sta BlockHitIndex
    lda BallY
    cmp #$38
    bcc NoBlockHit
    cmp #$68
    bcs NoBlockHit
    sec
    sbc #$38
    lsr a
    lsr a
    lsr a
    lsr a
    sta Temp
    asl a
    asl a
    asl a
    sta Temp2
    lda Temp
    asl a
    clc
    adc Temp2
    sta Temp2
    lda BallX
    cmp #$30
    bcc NoBlockHit
    cmp #$D0
    bcs NoBlockHit
    sec
    sbc #$30
    lsr a
    lsr a
    lsr a
    lsr a
    clc
    adc Temp2
    tay
    lda Blocks, y
    beq NoBlockHit
    lda #$00
    sta Blocks, y
    sty BlockHitIndex
    dec BlocksLeft
    inc ScoreOnes
    lda ScoreOnes
    cmp #$0A
    bne ScoreOk
    lda #$00
    sta ScoreOnes
    inc ScoreTens
ScoreOk:
    lda BallDY
    eor #$FF
    clc
    adc #$01
    sta BallDY
    jsr SfxBlock
    lda BlocksLeft
    bne NoBlockHit
    jsr ShowClearScreen
NoBlockHit:
    rts

DrawPlayFrame:
    jsr ErasePreviousBall
    jsr ErasePreviousPaddle
    jsr DrawScore
    lda BlockHitIndex
    cmp #$FF
    beq SkipEraseBlock
    jsr EraseHitBlock
    lda #$FF
    sta BlockHitIndex
SkipEraseBlock:
    jsr DrawBall
    jsr DrawPaddle
    jsr ResetPpuAddr
    rts

DrawPlayScreen:
    jsr DrawScoreLabel
    jsr DrawScore
    jsr DrawBlocks
    jsr DrawBall
    jsr DrawPaddle
    jsr ResetPpuAddr
    rts

DrawScoreLabel:
    lda #$20
    sta $2006
    lda #$43
    sta $2006
    ldx #$00
DrawScoreLabelLoop:
    lda ScoreText, x
    sta $2007
    inx
    cpx #ScoreTextEnd - ScoreText
    bne DrawScoreLabelLoop
    rts

DrawScore:
    lda #$20
    sta $2006
    lda #$4A
    sta $2006
    lda ScoreTens
    clc
    adc #TILE_0
    sta $2007
    lda ScoreOnes
    clc
    adc #TILE_0
    sta $2007
    rts

DrawBlocks:
    ldy #$00
    lda #$20
    sta $2006
    lda #$C6
    sta $2006
    jsr DrawOneBlockRow
    lda #$21
    sta $2006
    lda #$06
    sta $2006
    jsr DrawOneBlockRow
    lda #$21
    sta $2006
    lda #$46
    sta $2006
    jsr DrawOneBlockRow
    rts

DrawOneBlockRow:
    ldx #$08
DrawOneBlockRowLoop:
    lda Blocks, y
    beq DrawEmptyBlock
    lda #TILE_BLOCK
    jmp StoreBlockTile
DrawEmptyBlock:
    lda #TILE_BLANK
StoreBlockTile:
    sta $2007
    sta $2007
    lda #TILE_BLANK
    sta $2007
    iny
    dex
    bne DrawOneBlockRowLoop
    rts

EraseHitBlock:
    lda BlockHitIndex
    cmp #$08
    bcc HitRow0
    cmp #$10
    bcc HitRow1
    sec
    sbc #$10
    ldx #$21
    ldy #$46
    jmp EraseBlockAt
HitRow1:
    sec
    sbc #$08
    ldx #$21
    ldy #$06
    jmp EraseBlockAt
HitRow0:
    ldx #$20
    ldy #$C6
EraseBlockAt:
    sta Temp
    txa
    sta $2006
    tya
    sta Temp2
    lda Temp
    asl a
    clc
    adc Temp
    clc
    adc Temp2
    sta $2006
    lda #TILE_BLANK
    sta $2007
    sta $2007
    rts

TileAddressFromXY:
    ; A=x pixel, Y=y pixel. Returns high in Temp, low in Temp2.
    pha
    lda #$00
    sta Temp
    pla
    lsr a
    lsr a
    lsr a
    sta Temp2
    tya
    and #$F8
    asl a
    rol Temp
    asl a
    rol Temp
    clc
    adc Temp2
    sta Temp2
    lda Temp
    and #$03
    clc
    adc #$20
    sta Temp
    rts

ErasePreviousBall:
    lda PrevBallHigh
    sta $2006
    lda PrevBallTile
    sta $2006
    lda #TILE_BLANK
    sta $2007
    rts

DrawBall:
    lda BallX
    ldy BallY
    jsr TileAddressFromXY
    lda Temp
    sta $2006
    lda Temp2
    sta $2006
    lda #TILE_BALL
    sta $2007
    lda Temp
    sta PrevBallHigh
    lda Temp2
    sta PrevBallTile
    rts

ErasePreviousPaddle:
    lda #$23
    sta $2006
    lda PrevPaddleTile
    sta $2006
    ldx #$07
ErasePaddleLoop:
    lda #TILE_BLANK
    sta $2007
    dex
    bne ErasePaddleLoop
    rts

DrawPaddle:
    lda PaddleX
    lsr a
    lsr a
    lsr a
    clc
    adc #$60
    sta PrevPaddleTile
    lda #$23
    sta $2006
    lda PrevPaddleTile
    sta $2006
    ldx #$06
DrawPaddleLoop:
    lda #TILE_PADDLE
    sta $2007
    dex
    bne DrawPaddleLoop
    rts

ShowClearScreen:
    jsr SfxClear
    jsr DisableScreen
    jsr WaitVBlank
    jsr ClearNameTable
    lda #$21
    sta $2006
    lda #$CB
    sta $2006
    ldx #$00
DrawClearLoop:
    lda ClearText, x
    sta $2007
    inx
    cpx #ClearTextEnd - ClearText
    bne DrawClearLoop
    jsr DrawFinalScore
    lda #STATE_CLEAR
    sta GameState
    jsr EnableScreen
    rts

ShowGameOverScreen:
    jsr SfxMiss
    jsr DisableScreen
    jsr WaitVBlank
    jsr ClearNameTable
    lda #$21
    sta $2006
    lda #$C8
    sta $2006
    ldx #$00
DrawOverLoop:
    lda GameOverText, x
    sta $2007
    inx
    cpx #GameOverTextEnd - GameOverText
    bne DrawOverLoop
    jsr DrawFinalScore
    lda #STATE_OVER
    sta GameState
    jsr EnableScreen
    rts

DrawFinalScore:
    lda #$22
    sta $2006
    lda #$49
    sta $2006
    ldx #$00
DrawFinalScoreLoop:
    lda ScoreText, x
    sta $2007
    inx
    cpx #ScoreTextEnd - ScoreText
    bne DrawFinalScoreLoop
    lda #$22
    sta $2006
    lda #$50
    sta $2006
    lda ScoreTens
    clc
    adc #TILE_0
    sta $2007
    lda ScoreOnes
    clc
    adc #TILE_0
    sta $2007
    lda #$22
    sta $2006
    lda #$CA
    sta $2006
    ldx #$00
DrawAgainLoop:
    lda PressStartText, x
    sta $2007
    inx
    cpx #PressStartTextEnd - PressStartText
    bne DrawAgainLoop
    jsr ResetPpuAddr
    rts

DrawTitleScreen:
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
    jsr ResetPpuAddr
    rts

ClearNameTable:
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #$00
    ldx #$04
ClearPage:
    ldy #$00
ClearLoop:
    sta $2007
    iny
    bne ClearLoop
    dex
    bne ClearPage
    rts

LoadPalette:
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    ldx #$00
LoadPaletteLoop:
    lda Palette, x
    sta $2007
    inx
    cpx #$08
    bne LoadPaletteLoop
    rts

LoadFont:
    lda #$00
    sta $2006
    sta $2006
    ldx #$00
LoadFontLoop:
    lda Font, x
    sta $2007
    inx
    bne LoadFontLoop
    ldx #$00
LoadFontLoop2:
    lda Font + $100, x
    sta $2007
    inx
    bne LoadFontLoop2
    ldx #$00
LoadFontLoop3:
    lda Font + $200, x
    sta $2007
    inx
    cpx #$20
    bne LoadFontLoop3
    rts

ResetPpuAddr:
    lda #$00
    sta $2006
    sta $2006
    rts

SfxStart:
    lda #$01
    sta $4015
    lda #$84
    sta $4000
    lda #$28
    sta $4002
    lda #$08
    sta $4003
    rts
SfxPaddle:
    lda #$01
    sta $4015
    lda #$82
    sta $4000
    lda #$60
    sta $4002
    lda #$07
    sta $4003
    rts
SfxBlock:
    lda #$01
    sta $4015
    lda #$86
    sta $4000
    lda #$20
    sta $4002
    lda #$06
    sta $4003
    rts
SfxMiss:
    lda #$01
    sta $4015
    lda #$8F
    sta $4000
    lda #$F0
    sta $4002
    lda #$0F
    sta $4003
    rts
SfxClear:
    lda #$01
    sta $4015
    lda #$87
    sta $4000
    lda #$10
    sta $4002
    lda #$04
    sta $4003
    rts

Palette:
    .db $0F, $30, $10, $00, $0F, $30, $10, $00

MainTitle:
    .db TILE_B,TILE_L,TILE_O,TILE_C,TILE_K,TILE_BLANK,TILE_B,TILE_R,TILE_E,TILE_A,TILE_K,TILE_E,TILE_R
MainTitleEnd:
PressStartText:
    .db TILE_P,TILE_R,TILE_E,TILE_S,TILE_S,TILE_BLANK,TILE_S,TILE_T,TILE_A,TILE_R,TILE_T
PressStartTextEnd:
ScoreText:
    .db TILE_S,TILE_C,TILE_O,TILE_R,TILE_E,TILE_BLANK
ScoreTextEnd:
ClearText:
    .db TILE_C,TILE_L,TILE_E,TILE_A,TILE_R
ClearTextEnd:
GameOverText:
    .db TILE_G,TILE_A,TILE_M,TILE_E,TILE_BLANK,TILE_O,TILE_V,TILE_E,TILE_R
GameOverTextEnd:

Font:
    ; blank
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; A
    .db %00111100, %01100110, %01100110, %01111110, %01100110, %01100110, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; B
    .db %01111100, %01100110, %01100110, %01111100, %01100110, %01100110, %01111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; C
    .db %00111100, %01100110, %01100000, %01100000, %01100000, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; D
    .db %01111000, %01101100, %01100110, %01100110, %01100110, %01101100, %01111000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; E
    .db %01111110, %01100000, %01100000, %01111100, %01100000, %01100000, %01111110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; F
    .db %01111110, %01100000, %01100000, %01111100, %01100000, %01100000, %01100000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; G
    .db %00111100, %01100110, %01100000, %01101110, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; H
    .db %01100110, %01100110, %01100110, %01111110, %01100110, %01100110, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; I
    .db %00111100, %00011000, %00011000, %00011000, %00011000, %00011000, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; K
    .db %01100110, %01101100, %01111000, %01110000, %01111000, %01101100, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; L
    .db %01100000, %01100000, %01100000, %01100000, %01100000, %01100000, %01111110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; M
    .db %01100011, %01110111, %01111111, %01101011, %01100011, %01100011, %01100011, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; N
    .db %01100110, %01110110, %01111110, %01111110, %01101110, %01100110, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; O
    .db %00111100, %01100110, %01100110, %01100110, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; P
    .db %01111100, %01100110, %01100110, %01111100, %01100000, %01100000, %01100000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; R
    .db %01111100, %01100110, %01100110, %01111100, %01111000, %01101100, %01100110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; S
    .db %00111100, %01100110, %01100000, %00111100, %00000110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; T
    .db %01111110, %00011000, %00011000, %00011000, %00011000, %00011000, %00011000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; U
    .db %01100110, %01100110, %01100110, %01100110, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; V
    .db %01100110, %01100110, %01100110, %01100110, %01100110, %00111100, %00011000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 0
    .db %00111100, %01100110, %01101110, %01110110, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 1
    .db %00011000, %00111000, %00011000, %00011000, %00011000, %00011000, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 2
    .db %00111100, %01100110, %00000110, %00001100, %00110000, %01100000, %01111110, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 3
    .db %00111100, %01100110, %00000110, %00011100, %00000110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 4
    .db %00001100, %00011100, %00101100, %01001100, %01111110, %00001100, %00001100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 5
    .db %01111110, %01100000, %01111100, %00000110, %00000110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 6
    .db %00111100, %01100110, %01100000, %01111100, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 7
    .db %01111110, %00000110, %00001100, %00011000, %00110000, %00110000, %00110000, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 8
    .db %00111100, %01100110, %01100110, %00111100, %01100110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; 9
    .db %00111100, %01100110, %01100110, %00111110, %00000110, %01100110, %00111100, %00000000
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; paddle
    .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; ball
    .db %00111100, %01111110, %11111111, %11111111, %11111111, %11111111, %01111110, %00111100
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    ; block
    .db %11111111, %10000001, %10111101, %10111101, %10111101, %10111101, %10000001, %11111111
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
FontEnd:

NMI:
    rti
IRQ:
    rti

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw IRQ
