    .include "header.asm"

; STAR DROP - original NROM falling block puzzle for NESASM.
; Game states: TITLE / PLAY / PAUSE / LINE CLEAR / GAME OVER.

STATE_TITLE=$00
STATE_PLAY=$01
STATE_PAUSE=$02
STATE_LINE_CLEAR=$03
STATE_GAME_OVER=$04
FIELD_W=$0A
FIELD_H=$14
FIELD_SIZE=$C8
BTN_A=%10000000
BTN_B=%01000000
BTN_SELECT=%00100000
BTN_START=%00010000
BTN_UP=%00001000
BTN_DOWN=%00000100
BTN_LEFT=%00000010
BTN_RIGHT=%00000001
TILE_EMPTY=$00
TILE_WALL=$2F
TILE_BLOCK_BASE=$30

pad=$00
pad_old=$01
pad_new=$02
state=$03
nmi_ready=$04
frame=$05
ppu_dirty=$06
oam_dirty=$07
piece_x=$08
piece_y=$09
piece_id=$0A
piece_rot=$0B
next_id=$0C
gravity=$0D
gravity_timer=$0E
lock_timer=$0F
rng=$10
bag_mask=$11
score0=$12
score1=$13
score2=$14
lines_lo=$15
level=$16
das_l=$17
das_r=$18
clear_count=$19
clear_timer=$1A
tmp=$1B
tmp2=$1C
tmp3=$1D
tmp4=$1E
ptr=$20
ptr_hi=$21
field=$0300
oam=$0200

    .bank 0
    .org $C000
RESET:
    sei
    cld
    ldx #$40
    stx $4017
    ldx #$ff
    txs
    inx
    stx $2000
    stx $2001
    stx $4010
    bit $2002
v1: bit $2002
    bpl v1
v2: bit $2002
    bpl v2
    jsr ClearRam
    jsr LoadChr
    jsr LoadPal
    lda #STATE_TITLE
    sta state
    jsr DrawTitle
    lda #$80
    sta $2000
    lda #%00011110
    sta $2001
Main:
    lda nmi_ready
    beq Main
    lda #0
    sta nmi_ready
    jsr ReadPad
    lda state
    cmp #STATE_TITLE
    beq DoTitle
    cmp #STATE_PLAY
    beq DoPlay
    cmp #STATE_PAUSE
    beq DoPause
    cmp #STATE_LINE_CLEAR
    beq DoClear
    jmp DoGameOver
DoTitle:
    lda pad_new
    and #BTN_START
    beq Main
    jsr NewGame
    jmp Main
DoPause:
    lda pad_new
    and #BTN_START
    beq Main
    lda #STATE_PLAY
    sta state
    jsr DrawGame
    lda #1
    sta ppu_dirty
    jmp Main
DoGameOver:
    lda pad_new
    and #BTN_START
    beq Main
    lda #STATE_TITLE
    sta state
    jsr DrawTitle
    jmp Main
DoPlay:
    lda pad_new
    and #BTN_START
    beq DoPlayNoPause
    lda #STATE_PAUSE
    sta state
    jsr DrawPause
    jmp Main
DoPlayNoPause:
    jsr HandleMove
    jsr HandleRotate
    jsr HandleGravity
    jsr BuildSprites
    jmp Main
DoClear:
    dec clear_timer
    bne Main
    jsr CompactLines
    jsr SpawnPiece
    lda #STATE_PLAY
    sta state
    jsr DrawGame
    lda #1
    sta ppu_dirty
    jmp Main

NMI:
    pha
    txa
    pha
    tya
    pha
    lda #0
    sta $2003
    lda #2
    sta $4014
    lda ppu_dirty
    beq NoBg
    lda #0
    sta ppu_dirty
NoBg:
    lda #0
    sta $2005
    sta $2005
    inc frame
    lda #1
    sta nmi_ready
    pla
    tay
    pla
    tax
    pla
    rti
IRQ:
    rti

ClearRam:
    lda #0
    tax
CRLoop:
    sta $0000,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne CRLoop
    lda #$5d
    sta rng
    rts

ReadPad:
    lda pad
    sta pad_old
    lda #1
    sta $4016
    lda #0
    sta $4016
    sta pad
    ldx #8
RP:
    lda $4016
    lsr a
    rol pad
    dex
    bne RP
    lda pad
    eor #$ff
    and pad
    sta pad_new
    rts

NewGame:
    jsr ClearField
    lda #0
    sta score0
    sta score1
    sta score2
    sta lines_lo
    sta bag_mask
    lda #1
    sta level
    lda #38
    sta gravity
    jsr NextBagPiece
    sta next_id
    jsr SpawnPiece
    lda #STATE_PLAY
    sta state
    jsr DrawGame
    lda #1
    sta ppu_dirty
    rts
ClearField:
    lda #0
    ldx #0
CF: sta field,x
    inx
    cpx #FIELD_SIZE
    bne CF
    rts

NextBagPiece:
    lda bag_mask
    cmp #%01111111
    bne NBKeep
    lda #0
    sta bag_mask
NBKeep:
    jsr Random
    and #7
    cmp #7
    bne NBChk
    lda #3
NBChk:
    tay
    lda BitTable,y
    and bag_mask
    beq NBUse
    iny
    cpy #7
    bne NBWrapDone
    ldy #0
NBWrapDone:
    lda BitTable,y
    and bag_mask
    bne NBChk
NBUse:
    lda BitTable,y
    ora bag_mask
    sta bag_mask
    tya
    rts
Random:
    lda rng
    asl a
    bcc RandNoXor
    eor #$1d
RandNoXor:
    eor frame
    sta rng
    rts

SpawnPiece:
    lda next_id
    sta piece_id
    jsr NextBagPiece
    sta next_id
    lda #4
    sta piece_x
    lda #0
    sta piece_y
    sta piece_rot
    lda gravity
    sta gravity_timer
    lda #12
    sta lock_timer
    jsr CheckCollision
    beq SpawnOk
    lda #STATE_GAME_OVER
    sta state
    jsr DrawGameOver
    jsr SfxGameOver
SpawnOk:
    jsr DrawGame
    lda #1
    sta ppu_dirty
    rts

HandleMove:
    lda pad_new
    and #BTN_LEFT
    bne MoveLeft
    lda pad
    and #BTN_LEFT
    beq NoLeft
    inc das_l
    lda das_l
    cmp #10
    bcc NoLeft
    lda #6
    sta das_l
MoveLeft:
    dec piece_x
    jsr CheckCollision
    beq MLok
    inc piece_x
    jmp NoLeft
MLok: jsr SfxMove
NoLeft:
    lda pad
    and #BTN_LEFT
    bne LeftHeld
    lda #0
    sta das_l
LeftHeld:
    lda pad_new
    and #BTN_RIGHT
    bne MoveRight
    lda pad
    and #BTN_RIGHT
    beq NoRight
    inc das_r
    lda das_r
    cmp #10
    bcc NoRight
    lda #6
    sta das_r
MoveRight:
    inc piece_x
    jsr CheckCollision
    beq MRok
    dec piece_x
    jmp NoRight
MRok: jsr SfxMove
NoRight:
    lda pad
    and #BTN_RIGHT
    bne RightHeld
    lda #0
    sta das_r
RightHeld:
    lda pad
    and #BTN_DOWN
    beq NoSoftDrop
    jsr TryDrop
    lda #1
    jsr AddScoreA
NoSoftDrop:
    rts

HandleRotate:
    lda pad_new
    and #BTN_A
    beq NoA
    inc piece_rot
    lda piece_rot
    and #3
    sta piece_rot
    jsr WallKick
    jsr SfxRotate
NoA:
    lda pad_new
    and #BTN_B
    beq NoB
    dec piece_rot
    lda piece_rot
    and #3
    sta piece_rot
    jsr WallKick
    jsr SfxRotate
NoB: rts
WallKick:
    jsr CheckCollision
    beq WKOk
    inc piece_x
    jsr CheckCollision
    beq WKOk
    dec piece_x
    dec piece_x
    jsr CheckCollision
    beq WKOk
    inc piece_x
    ; revert rotation if both small wall kicks fail
    lda pad_new
    and #BTN_A
    beq WKWasB
    dec piece_rot
    jmp WKFix
WKWasB:
    inc piece_rot
WKFix:
    lda piece_rot
    and #3
    sta piece_rot
WKOk: rts

HandleGravity:
    dec gravity_timer
    bne HGDone
    lda gravity
    sta gravity_timer
    jsr TryDrop
HGDone: rts
TryDrop:
    inc piece_y
    jsr CheckCollision
    bne TDHit
    lda #12
    sta lock_timer
    rts
TDHit:
    dec piece_y
    dec lock_timer
    bne TDWait
    jsr LockPiece
TDWait:
    rts

LockPiece:
    jsr PlacePiece
    jsr SfxLock
    jsr FindLines
    lda clear_count
    beq NoLines
    lda #STATE_LINE_CLEAR
    sta state
    lda #18
    sta clear_timer
    jsr SfxLine
    jsr AddLineScore
    jsr DrawGame
    lda #1
    sta ppu_dirty
    rts
NoLines:
    jsr SpawnPiece
    rts

; Collision uses tmp4=block index, returns Z set when clear, A=0 clear/A=1 hit.
CheckCollision:
    ldx #0
CCLoop:
    stx tmp4
    jsr GetCellXY
    lda tmp2
    bmi CCHit
    cmp #FIELD_W
    bcs CCHit
    lda tmp3
    cmp #FIELD_H
    bcs CCHit
    jsr FieldIndex
    tay
    lda field,y
    bne CCHit
    ldx tmp4
    inx
    cpx #4
    bne CCLoop
    lda #0
    rts
CCHit:
    lda #1
    rts
PlacePiece:
    ldx #0
PPLoop:
    stx tmp4
    jsr GetCellXY
    jsr FieldIndex
    tay
    lda piece_id
    clc
    adc #1
    sta field,y
    ldx tmp4
    inx
    cpx #4
    bne PPLoop
    rts
FieldIndex:
    lda tmp3
    asl a
    sta tmp
    asl a
    asl a
    clc
    adc tmp
    clc
    adc tmp2
    rts

FindLines:
    lda #0
    sta clear_count
    ldy #0
FLRow:
    sty tmp3
    ldx #0
FLCol:
    stx tmp2
    jsr FieldIndex
    tax
    lda field,x
    beq FLNext
    ldx tmp2
    inx
    cpx #FIELD_W
    bne FLCol
    ; full row: mark with $80 and count
    inc clear_count
    ldx #0
Mark:
    stx tmp2
    jsr FieldIndex
    tax
    lda #$80
    sta field,x
    ldx tmp2
    inx
    cpx #FIELD_W
    bne Mark
FLNext:
    ldy tmp3
    iny
    cpy #FIELD_H
    bne FLRow
    rts

CompactLines:
    ldy #19
CLScan:
    sty tmp3
    ldx #0
    jsr FieldIndex
    tax
    lda field,x
    cmp #$80
    bne CLPrev
    jsr PullDown
    jmp CLScan
CLPrev:
    ldy tmp3
    dey
    cpy #$ff
    bne CLScan
    rts
PullDown:
    ldy tmp3
PDRow:
    cpy #0
    beq PDClearTop
    sty tmp3
    dey
    sty tmp4
    ldx #0
PDCopy:
    stx tmp2
    ldy tmp4
    sty tmp3
    jsr FieldIndex
    tax
    lda field,x
    pha
    ldy tmp3
    iny
    sty tmp3
    jsr FieldIndex
    tax
    pla
    sta field,x
    ldx tmp2
    inx
    cpx #FIELD_W
    bne PDCopy
    ldy tmp4
    bne PDRow
PDClearTop:
    lda #0
    ldx #0
Top:
    sta field,x
    inx
    cpx #FIELD_W
    bne Top
    rts

AddLineScore:
    lda clear_count
    clc
    adc lines_lo
    sta lines_lo
    lda clear_count
    asl a
    asl a
    asl a
    asl a
    jsr AddScoreA
    lda lines_lo
    lsr a
    lsr a
    lsr a
    lsr a
    cmp level
    bcc LevelDone
    inc level
    lda gravity
    cmp #8
    bcc LevelDone
    sec
    sbc #4
    sta gravity
    jsr SfxLevel
LevelDone:
    rts
AddScoreA:
    clc
    adc score0
    sta score0
    bcc ScoreDone
    inc score1
    bne ScoreDone
    inc score2
ScoreDone:
    rts

DrawTitle:
    jsr ClearNt
    lda #$21
    sta $2006
    lda #$28
    sta $2006
    ldx #0
DT1: lda TitleText,x
    beq DT2
    sta $2007
    inx
    bne DT1
DT2:
    lda #$22
    sta $2006
    lda #$08
    sta $2006
    ldx #0
DT3: lda PressText,x
    beq DT4
    sta $2007
    inx
    bne DT3
DT4:
    lda #1
    sta ppu_dirty
    rts
DrawPause:
    lda #$22
    sta $2006
    lda #$4d
    sta $2006
    ldx #0
DP: lda PauseText,x
    beq DPEnd
    sta $2007
    inx
    bne DP
DPEnd:
    rts
DrawGameOver:
    jsr DrawGame
    lda #$22
    sta $2006
    lda #$4b
    sta $2006
    ldx #0
DGO: lda OverText,x
    beq DGOEnd
    sta $2007
    inx
    bne DGO
DGOEnd:
    lda #1
    sta ppu_dirty
    rts
DrawGame:
    jsr ClearNt
    jsr DrawFrame
    jsr DrawField
    jsr DrawHud
    jsr BuildSprites
    rts
DrawFrame:
    lda #$20
    sta $2006
    lda #$64
    sta $2006
    ldx #12
DFTop: lda #TILE_WALL
    sta $2007
    dex
    bne DFTop
    ldy #0
DFRows:
    tya
    pha
    lda RowHi,y
    sta $2006
    lda RowLo,y
    sta $2006
    lda #TILE_WALL
    sta $2007
    ldx #10
DFMid: lda #TILE_EMPTY
    sta $2007
    dex
    bne DFMid
    lda #TILE_WALL
    sta $2007
    pla
    tay
    iny
    cpy #20
    bne DFRows
    lda #$22
    sta $2006
    lda #$e4
    sta $2006
    ldx #12
DFBot: lda #TILE_WALL
    sta $2007
    dex
    bne DFBot
    rts
DrawField:
    ldy #0
DFRow:
    sty tmp3
    lda RowHi,y
    sta $2006
    lda RowLo,y
    clc
    adc #1
    sta $2006
    ldx #0
DFCol:
    stx tmp2
    jsr FieldIndex
    tax
    lda field,x
    cmp #$80
    bne NotMarkedLine
    lda frame
    and #2
    beq EmptyT
    lda #TILE_WALL
    jmp PutT
NotMarkedLine:
    beq EmptyT
    clc
    adc #TILE_BLOCK_BASE-1
    jmp PutT
EmptyT:
    lda #TILE_EMPTY
PutT:
    sta $2007
    ldx tmp2
    inx
    cpx #FIELD_W
    bne DFCol
    ldy tmp3
    iny
    cpy #FIELD_H
    bne DFRow
    rts
DrawHud:
    lda #$20
    sta $2006
    lda #$72
    sta $2006
    ldx #0
DH1: lda HudText,x
    beq DH2
    sta $2007
    inx
    bne DH1
DH2:
    lda #$20
    sta $2006
    lda #$d2
    sta $2006
    lda next_id
    clc
    adc #$41
    sta $2007
    lda #$21
    sta $2006
    lda #$92
    sta $2006
    lda score1
    jsr HexByte
    lda score0
    jsr HexByte
    lda #$21
    sta $2006
    lda #$f2
    sta $2006
    lda lines_lo
    jsr HexByte
    lda #$22
    sta $2006
    lda #$52
    sta $2006
    lda level
    jsr HexByte
    rts
HexByte:
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr HexNib
    pla
    and #$0f
HexNib:
    cmp #10
    bcc HexDecimal
    adc #6
HexDecimal:
    adc #$10
    sta $2007
    rts
FlushScreen:
    lda #1
    sta ppu_dirty
    rts
ClearNt:
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #0
    ldx #4
CNT1:
    ldy #0
CNT2: sta $2007
    iny
    bne CNT2
    dex
    bne CNT1
    rts

BuildSprites:
    lda #$f0
    ldx #0
BSClr: sta oam,x
    inx
    bne BSClr
    lda state
    cmp #STATE_PLAY
    beq SpritesActive
    rts
SpritesActive:
    ldx #0
BSPiece:
    stx tmp4
    jsr GetCellXY
    lda tmp3
    asl a
    asl a
    asl a
    clc
    adc #31
    sta oam,x
    lda piece_id
    clc
    adc #TILE_BLOCK_BASE
    sta oam+1,x
    lda #0
    sta oam+2,x
    lda tmp2
    asl a
    asl a
    asl a
    clc
    adc #39
    sta oam+3,x
    txa
    clc
    adc #4
    tax
    cpx #16
    bne BSPiece
    rts

GetCellXY:
    lda piece_id
    asl a
    asl a
    asl a
    asl a
    sta ptr
    lda piece_rot
    asl a
    asl a
    clc
    adc ptr
    clc
    adc tmp4
    asl a
    tay
    lda ShapeData,y
    clc
    adc piece_x
    sta tmp2
    iny
    lda ShapeData,y
    clc
    adc piece_y
    sta tmp3
    rts

LoadPal:
    lda #$3f
    sta $2006
    lda #0
    sta $2006
    ldx #0
LP: lda Palette,x
    sta $2007
    inx
    cpx #32
    bne LP
    rts
LoadChr:
    lda #0
    sta $2006
    sta $2006
    ldx #0
LC: lda ChrData,x
    sta $2007
    inx
    bne LC
    rts

SfxMove: lda #$1f
    sta $4000
    lda #$70
    sta $4002
    lda #$08
    sta $4003
    rts
SfxRotate: lda #$1f
    sta $4004
    lda #$50
    sta $4006
    lda #$08
    sta $4007
    rts
SfxLock: lda #$2f
    sta $400c
    lda #$20
    sta $400e
    lda #$08
    sta $400f
    rts
SfxLine: lda #$3f
    sta $4000
    lda #$20
    sta $4002
    lda #$10
    sta $4003
    rts
SfxLevel: jsr SfxRotate
    rts
SfxGameOver: lda #$3f
    sta $400c
    lda #$0f
    sta $400e
    lda #$20
    sta $400f
    rts

Palette:
    .db $0f,$30,$11,$27,$0f,$16,$27,$30,$0f,$19,$29,$30,$0f,$05,$15,$30
    .db $0f,$16,$27,$30,$0f,$19,$29,$30,$0f,$05,$15,$30,$0f,$12,$22,$30
BitTable: .db 1,2,4,8,16,32,64
TitleText: .db "STAR DROP",0
PressText: .db "PRESS START",0
PauseText: .db " PAUSE ",0
OverText: .db "GAME OVER",0
HudText: .db "NEXT",0
RowHi:
    .db $20,$20,$20,$20,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$22,$22,$22,$22,$22
RowLo:
    .db $84,$a4,$c4,$e4,$04,$24,$44,$64,$84,$a4,$c4,$e4,$04,$24,$44,$64,$84,$a4,$c4,$e4
; Seven tetromino-like original block sets, 4 rotations, 4 cells, x/y pairs.
ShapeData:
    .db 0,1,1,1,2,1,3,1, 2,0,2,1,2,2,2,3, 0,2,1,2,2,2,3,2, 1,0,1,1,1,2,1,3
    .db 1,0,2,0,1,1,2,1, 1,0,2,0,1,1,2,1, 1,0,2,0,1,1,2,1, 1,0,2,0,1,1,2,1
    .db 1,0,0,1,1,1,2,1, 1,0,1,1,2,1,1,2, 0,1,1,1,2,1,1,2, 1,0,0,1,1,1,1,2
    .db 0,0,1,0,1,1,2,1, 2,0,1,1,2,1,1,2, 0,1,1,1,1,2,2,2, 1,0,0,1,1,1,0,2
    .db 1,0,2,0,0,1,1,1, 1,0,1,1,2,1,2,2, 1,1,2,1,0,2,1,2, 0,0,0,1,1,1,1,2
    .db 0,0,0,1,1,1,2,1, 1,0,2,0,1,1,1,2, 0,1,1,1,2,1,2,2, 1,0,1,1,0,2,1,2
    .db 2,0,0,1,1,1,2,1, 1,0,1,1,1,2,2,2, 0,1,1,1,2,1,0,2, 0,0,1,0,1,1,1,2
ChrData:
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $ff,$81,$bd,$bd,$bd,$bd,$81,$ff
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $ff,$ff,$c3,$c3,$c3,$c3,$ff,$ff
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$81,$a5,$81,$a5,$99,$81,$7e
    .db $00,$00,$00,$00,$00,$00,$00,$00

    .bank 1
    .org $fffa
    .dw NMI
    .dw RESET
    .dw IRQ
