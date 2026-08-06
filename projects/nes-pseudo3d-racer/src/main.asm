    .include "header.asm"

PPUCTRL=$2000
PPUMASK=$2001
PPUSTATUS=$2002
OAMADDR=$2003
OAMDATA=$2004
PPUSCROLL=$2005
PPUADDR=$2006
PPUDATA=$2007
OAMDMA=$4014
JOY1=$4016
APU_PULSE1=$4000
APU_PULSE1_LO=$4002
APU_PULSE1_HI=$4003
APU_NOISE=$400C
APU_NOISE_LO=$400E
APU_NOISE_HI=$400F

STATE_TITLE=$00
STATE_PLAY=$01
STATE_PAUSE=$02
STATE_CLEAR=$03
STATE_OVER=$04
BUTTON_A=%10000000
BUTTON_B=%01000000
BUTTON_SELECT=%00100000
BUTTON_START=%00010000
BUTTON_UP=%00001000
BUTTON_DOWN=%00000100
BUTTON_LEFT=%00000010
BUTTON_RIGHT=%00000001
ROAD_LEFT_LIMIT=$38
ROAD_RIGHT_LIMIT=$B8
PLAYER_Y=$C8
MAX_SPEED=$28
GOAL_HI=$03
START_TIME=$90

GameState=$00
Controller=$01
ControllerPrev=$02
ControllerNew=$03
NmiReady=$04
FrameCounter=$05
Speed=$06
PlayerX=$07
RoadCenter=$08
RoadCurve=$09
DistanceLo=$0A
DistanceHi=$0B
TimeLeft=$0C
TimeTick=$0D
SpinTimer=$0E
CrashSfx=$0F
Temp=$10
Temp2=$11
RowIndex=$12
RoadLeft=$13
RoadWidth=$14
Obj0Z=$15
Obj0Lane=$16
Obj1Z=$17
Obj1Lane=$18
Obj0X=$19
Obj1X=$1A
ScreenDirty=$1B
OAM=$0200

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
    stx PPUCTRL
    stx PPUMASK
    stx $4010
Wait1:
    bit PPUSTATUS
    bpl Wait1
Wait2:
    bit PPUSTATUS
    bpl Wait2
    jsr LoadChr
    jsr InitGame
    lda #%10000000
    sta PPUCTRL
    lda #%00011110
    sta PPUMASK
MainLoop:
    lda NmiReady
    beq MainLoop
    lda #$00
    sta NmiReady
    jsr ReadPad
    jsr UpdateGame
    jmp MainLoop

NMI:
    pha
    txa
    pha
    tya
    pha
    lda #$00
    sta OAMADDR
    lda #$02
    sta OAMDMA
    jsr VBlankDraw
    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL
    inc NmiReady
    pla
    tay
    pla
    tax
    pla
    rti

IRQ:
    rti

InitGame:
    lda #STATE_TITLE
    sta GameState
    lda #$78
    sta PlayerX
    sta RoadCenter
    lda #$00
    sta Speed
    sta DistanceLo
    sta DistanceHi
    sta SpinTimer
    lda #START_TIME
    sta TimeLeft
    lda #$20
    sta Obj0Z
    lda #$00
    sta Obj0Lane
    lda #$70
    sta Obj1Z
    lda #$01
    sta Obj1Lane
    lda #$01
    sta ScreenDirty
    jsr ClearOam
    rts

StartRun:
    lda #STATE_PLAY
    sta GameState
    lda #$78
    sta PlayerX
    sta RoadCenter
    lda #$00
    sta Speed
    sta DistanceLo
    sta DistanceHi
    sta SpinTimer
    lda #START_TIME
    sta TimeLeft
    lda #$20
    sta Obj0Z
    lda #$00
    sta Obj0Lane
    lda #$70
    sta Obj1Z
    lda #$01
    sta Obj1Lane
    rts

ReadPad:
    lda Controller
    sta ControllerPrev
    lda #$01
    sta JOY1
    lda #$00
    sta JOY1
    sta Controller
    ldx #$08
PadLoop:
    lda JOY1
    lsr a
    rol Controller
    dex
    bne PadLoop
    lda Controller
    eor ControllerPrev
    and Controller
    sta ControllerNew
    rts

UpdateGame:
    lda GameState
    beq UpdateTitle
    cmp #STATE_PLAY
    beq UpdatePlay
    cmp #STATE_PAUSE
    beq UpdatePause
    jmp UpdateEndScreen
UpdateTitle:
    lda ControllerNew
    and #BUTTON_START
    beq UGDone
    jsr StartRun
    rts
UpdatePause:
    lda ControllerNew
    and #BUTTON_START
    beq UGDone
    lda #STATE_PLAY
    sta GameState
    rts
UpdateEndScreen:
    lda ControllerNew
    and #BUTTON_START
    beq UGDone
    jsr InitGame
UGDone:
    rts

UpdatePlay:
    inc FrameCounter
    lda ControllerNew
    and #BUTTON_START
    beq NotPause
    lda #STATE_PAUSE
    sta GameState
    rts
NotPause:
    lda Controller
    and #BUTTON_A
    beq NoAccel
    lda Speed
    cmp #MAX_SPEED
    bcs NoAccel
    inc Speed
NoAccel:
    lda Controller
    and #BUTTON_B
    beq NoBrake
    lda Speed
    beq NoBrake
    dec Speed
    dec Speed
NoBrake:
    lda Controller
    and #BUTTON_LEFT
    beq NoLeft
    lda PlayerX
    sec
    sbc #$02
    sta PlayerX
NoLeft:
    lda Controller
    and #BUTTON_RIGHT
    beq NoRight
    lda PlayerX
    clc
    adc #$02
    sta PlayerX
NoRight:
    lda PlayerX
    cmp #$18
    bcs PXok1
    lda #$18
    sta PlayerX
PXok1:
    cmp #$e0
    bcc PXok2
    lda #$e0
    sta PlayerX
PXok2:
    jsr UpdateRoadCurve
    jsr RoadEdgePenalty
    jsr AdvanceDistance
    jsr UpdateObjects
    jsr UpdateTimer
    jsr UpdateAudio
    rts

UpdateRoadCurve:
    lda DistanceHi
    and #$03
    tax
    lda CourseCurve,x
    sta RoadCurve
    clc
    adc #$78
    sta RoadCenter
    rts
CourseCurve:
    .db $00,$10,$f0,$20

RoadEdgePenalty:
    lda PlayerX
    cmp #ROAD_LEFT_LIMIT
    bcc SlowOffRoad
    cmp #ROAD_RIGHT_LIMIT
    bcs SlowOffRoad
    rts
SlowOffRoad:
    lda Speed
    beq REPDone
    lsr a
    sta Speed
REPDone:
    rts

AdvanceDistance:
    lda Speed
    lsr a
    lsr a
    clc
    adc DistanceLo
    sta DistanceLo
    bcc NoDistHi
    inc DistanceHi
NoDistHi:
    lda DistanceHi
    cmp #GOAL_HI
    bcc DistDone
    lda #STATE_CLEAR
    sta GameState
    lda #$20
    sta APU_PULSE1_LO
    lda #$08
    sta APU_PULSE1_HI
DistDone:
    rts

UpdateTimer:
    inc TimeTick
    lda TimeTick
    cmp #$3c
    bcc TimerDone
    lda #$00
    sta TimeTick
    lda TimeLeft
    beq TimeOver
    dec TimeLeft
    rts
TimeOver:
    lda #STATE_OVER
    sta GameState
    lda #$0f
    sta APU_NOISE_LO
    sta APU_NOISE_HI
TimerDone:
    rts

UpdateObjects:
    lda Obj0Z
    sec
    sbc Speed
    sta Obj0Z
    bcs Obj0Ok
    lda #$d0
    sta Obj0Z
    lda Obj0Lane
    eor #$01
    sta Obj0Lane
Obj0Ok:
    lda Obj1Z
    sec
    sbc Speed
    sta Obj1Z
    bcs Obj1Ok
    lda #$f0
    sta Obj1Z
    lda Obj1Lane
    eor #$01
    sta Obj1Lane
Obj1Ok:
    jsr CheckCrash
    rts
CheckCrash:
    lda Obj0Z
    cmp #$18
    bcs CheckObj1
    lda Obj0Lane
    beq C0L
    lda #$9c
    jmp C0X
C0L: lda #$58
C0X: sta Temp
    jsr CrashIfNear
CheckObj1:
    lda Obj1Z
    cmp #$18
    bcs NoCrash
    lda Obj1Lane
    beq C1L
    lda #$a8
    jmp C1X
C1L: lda #$50
C1X: sta Temp
    jsr CrashIfNear
NoCrash:
    rts
CrashIfNear:
    lda PlayerX
    sec
    sbc Temp
    clc
    adc #$10
    cmp #$20
    bcs CINo
    lda Speed
    lsr a
    sta Speed
    lda #$14
    sta SpinTimer
    sta CrashSfx
CINo:
    rts

UpdateAudio:
    lda #$30
    sta APU_PULSE1
    lda Speed
    eor #$ff
    sta APU_PULSE1_LO
    lda #$08
    sta APU_PULSE1_HI
    lda CrashSfx
    beq UANo
    dec CrashSfx
    lda #$1f
    sta APU_NOISE
    lda #$04
    sta APU_NOISE_LO
    lda #$08
    sta APU_NOISE_HI
UANo:
    rts

VBlankDraw:
    lda GameState
    cmp #STATE_TITLE
    beq DrawTitle
    cmp #STATE_PLAY
    beq DrawPlay
    cmp #STATE_PAUSE
    beq DrawPause
    cmp #STATE_CLEAR
    beq DrawClear
    jmp DrawOver

ClearName:
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #$00
    ldx #$04
CNPage:
    ldy #$00
CNLoop:
    sta PPUDATA
    iny
    bne CNLoop
    dex
    bne CNPage
    rts
DrawTitle:
    jsr ClearName
    lda #$21
    ldy #$0a
    jsr DrawTextAt218A
    jsr HideSprites
    rts
DrawTextAt218A:
    lda #$21
    sta PPUADDR
    lda #$8a
    sta PPUADDR
    ldx #$00
DTL:
    lda TitleText,x
    beq DTE
    sta PPUDATA
    inx
    bne DTL
DTE: rts
DrawPlay:
    jsr DrawRoad
    jsr DrawHud
    jsr DrawSprites
    rts
DrawPause:
    jsr DrawPlay
    lda #$22
    sta PPUADDR
    lda #$2d
    sta PPUADDR
    ldx #$00
DPL: lda PauseText,x
    beq DPE
    sta PPUDATA
    inx
    bne DPL
DPE: rts
DrawClear:
    jsr ClearName
    jsr HideSprites
    lda #$21
    sta PPUADDR
    lda #$ad
    sta PPUADDR
    ldx #$00
DCL: lda ClearText,x
    beq DCE
    sta PPUDATA
    inx
    bne DCL
DCE: rts
DrawOver:
    jsr ClearName
    jsr HideSprites
    lda #$21
    sta PPUADDR
    lda #$ab
    sta PPUADDR
    ldx #$00
DOL: lda OverText,x
    beq DOE
    sta PPUDATA
    inx
    bne DOL
DOE: rts

DrawRoad:
    jsr ClearName
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldx #$00
SkyLoop:
    lda #$01
    sta PPUDATA
    inx
    cpx #$c0
    bne SkyLoop
    ldx #$00
RoadLoop:
    txa
    and #$03
    tay
    lda RoadWidths,y
    sta RoadWidth
    lda RoadCenter
    sec
    sbc RoadOffsets,y
    lsr a
    lsr a
    lsr a
    sta RoadLeft
    ldy #$00
TileRow:
    tya
    cmp RoadLeft
    bcc GrassTile
    sec
    sbc RoadLeft
    cmp RoadWidth
    bcs GrassTile
    cmp #$01
    beq ShoulderTile
    lda RoadWidth
    sec
    sbc #$02
    sta Temp
    tya
    sec
    sbc RoadLeft
    cmp Temp
    beq ShoulderTile
    lda FrameCounter
    and #$08
    beq Asphalt
    tya
    cmp #$0f
    beq StripeTile
Asphalt:
    lda #$03
    jmp PutTile
StripeTile:
    lda #$05
    jmp PutTile
ShoulderTile:
    lda #$04
    jmp PutTile
GrassTile:
    lda #$02
PutTile:
    sta PPUDATA
    iny
    cpy #$20
    bne TileRow
    inx
    cpx #$17
    bne RoadLoop
    rts
RoadWidths:
    .db $08,$0c,$12,$18
RoadOffsets:
    .db $20,$28,$30,$38

DrawHud:
    lda #$20
    sta PPUADDR
    lda #$01
    sta PPUADDR
    ldx #$00
DHL: lda HudText,x
    beq DHE
    sta PPUDATA
    inx
    bne DHL
DHE:
    lda #$20
    sta PPUADDR
    lda #$07
    sta PPUADDR
    lda Speed
    lsr a
    jsr DrawHex
    lda #$20
    sta PPUADDR
    lda #$10
    sta PPUADDR
    lda TimeLeft
    jsr DrawHex
    lda #$20
    sta PPUADDR
    lda #$1c
    sta PPUADDR
    lda DistanceHi
    jsr DrawHex
    rts
DrawHex:
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr Nibble
    sta PPUDATA
    pla
    and #$0f
Nibble:
    clc
    adc #$10
    rts

DrawSprites:
    jsr HideSprites
    lda #PLAYER_Y
    sta OAM
    lda #$06
    sta OAM+1
    lda #$00
    sta OAM+2
    lda PlayerX
    sta OAM+3
    lda Obj0Z
    lsr a
    sta Temp
    lda #$b8
    sec
    sbc Temp
    sta OAM+4
    lda #$07
    sta OAM+5
    lda #$01
    sta OAM+6
    lda Obj0Lane
    beq O0L
    lda #$a0
    jmp O0S
O0L: lda #$58
O0S: sta OAM+7
    lda Obj1Z
    lsr a
    sta Temp
    lda #$b8
    sec
    sbc Temp
    sta OAM+8
    lda #$08
    sta OAM+9
    lda #$02
    sta OAM+10
    lda Obj1Lane
    beq O1L
    lda #$a8
    jmp O1S
O1L: lda #$50
O1S: sta OAM+11
    rts
HideSprites:
ClearOam:
    ldx #$00
    lda #$f8
HOLoop:
    sta OAM,x
    inx
    bne HOLoop
    rts

LoadChr:
    lda #$00
    sta PPUADDR
    sta PPUADDR
    ldx #$00
LCL: lda ChrData,x
    sta PPUDATA
    inx
    bne LCL
LCL2: lda ChrData+$100,x
    sta PPUDATA
    inx
    bne LCL2
    jsr LoadPalette
    rts
LoadPalette:
    lda #$3f
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldx #$00
LPL: lda Palette,x
    sta PPUDATA
    inx
    cpx #$20
    bne LPL
    rts

TitleText: .db $18,$1b,$0d,$1d,$0c,$19,$00,$1a,$09,$0b,$0d,$1a,$00
PauseText: .db $18,$09,$1d,$1b,$0d,$00
ClearText: .db $0b,$14,$0d,$09,$1a,$00,$00,$1b,$1c,$09,$1a,$1c,$00
OverText: .db $0f,$09,$15,$0d,$00,$17,$1e,$0d,$1a,$00
HudText: .db $1b,$18,$0c,$00,$00,$00,$00,$00,$1c,$15,$00,$00,$00,$00,$00,$00,$0c,$11,$1b,$1c,$00
Palette: .db $0f,$11,$21,$30,$0f,$06,$16,$27,$0f,$00,$10,$20,$0f,$05,$15,$25,$0f,$30,$16,$06,$0f,$27,$17,$07,$0f,$20,$10,$00,$0f,$15,$25,$30

ChrData:
    .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; blank
    .db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00 ; sky
    .db $55,$aa,$55,$aa,$55,$aa,$55,$aa,$00,$00,$00,$00,$00,$00,$00,$00 ; grass
    .db $18,$00,$18,$00,$18,$00,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; road
    .db $ff,$81,$ff,$81,$ff,$81,$ff,$81,$00,$00,$00,$00,$00,$00,$00,$00 ; shoulder
    .db $18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$00,$00,$00,$00 ; line
    .db $18,$3c,$7e,$db,$ff,$7e,$24,$66,$00,$00,$00,$00,$00,$00,$00,$00 ; player
    .db $3c,$7e,$db,$ff,$ff,$7e,$24,$42,$00,$00,$00,$00,$00,$00,$00,$00 ; car small
    .db $18,$3c,$7e,$ff,$db,$ff,$66,$42,$00,$00,$00,$00,$00,$00,$00,$00 ; car near
    ; A-Z as block glyphs, 0-9 also reuse readable-ish patterns
    .db $3c,$66,$66,$7e,$66,$66,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7c,$66,$66,$7c,$66,$66,$7c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$66,$60,$60,$60,$66,$3c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $78,$6c,$66,$66,$66,$6c,$78,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$60,$60,$7c,$60,$60,$7e,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$60,$60,$7c,$60,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$66,$60,$6e,$66,$66,$3c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$66,$66,$7e,$66,$66,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$18,$18,$18,$18,$18,$3c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $1e,$0c,$0c,$0c,$0c,$6c,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$6c,$78,$70,$78,$6c,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $60,$60,$60,$60,$60,$60,$7e,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $63,$77,$7f,$6b,$63,$63,$63,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$76,$7e,$7e,$6e,$66,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$66,$66,$66,$66,$66,$3c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7c,$66,$66,$7c,$60,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$66,$66,$66,$6a,$6c,$36,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7c,$66,$66,$7c,$78,$6c,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $3c,$60,$60,$3c,$06,$06,$7c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$66,$66,$66,$66,$66,$3c,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$66,$66,$66,$66,$3c,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $63,$63,$63,$6b,$7f,$77,$63,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$66,$3c,$18,$3c,$66,$66,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $66,$66,$66,$3c,$18,$18,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .db $7e,$06,$0c,$18,$30,$60,$7e,$00,$00,$00,$00,$00,$00,$00,$00,$00
ChrEnd:

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw IRQ
