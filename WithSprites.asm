; 10 SYS (2304)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28, $32, $33, $30, $34, $29, $00, $00, $00

*=$0900

SPRITE0_POS_Y = 60

Init
        sei
        jsr ClearScreen
        jsr InitIRQs
        jsr SetupSprites
        cli

        ; nem használhatunk regisztereket,
        ; mert nincs stack-kezelés az IRQ handlerekben
        jmp *
        rts

InitIRQs
        ; disable KERNAL ROM
        lda #$35
        sta $01

        ; disable CIA IRQs
        lda #$7F
        sta $DC0D
        lda $DC0D ; reset flags

        ; setup VIC
        lda #%00011011
        sta $D011 ; Control register 1
        lda #%00001000
        sta $D016 ; Control register 2
        lda #$00
        sta $D012 ; RASTER
        lda #%00000001 ; IRQ on raster line
        sta $D01A ; IRQ enable register
        lda #$00 ; black
        sta $D020 ; border color
        sta $D021 ; background color

        ; setup IRQ handler routine
        lda #<VicIrqHandler
        sta $FFFE
        lda #>VicIrqHandler
        sta $FFFF

        rts

ClearScreen
        lda #' '
        ldx #$FF
@Loop   sta $03FF,X
        sta $04FE,X
        sta $05FD,X
        sta $06E8,X ; a sprite pointerek békén hagyása miatt

        dex
        bne @Loop ; nullánál vége

        rts




VicIrqHandler
        ; change 0th sprite's Y position
        lda $D001
        cmp #SPRITE0_POS_Y
        beq @Down ; carry will be always set after this operation

@Up     sbc #42
        jmp @End

@Down   clc
        adc #42

@End    sta $D001

        inc $D000 ; sprite 0 X

        ; alja-teteje váltás
        lda #$01
        eor $07F8
        sta $07F8

        asl $D019
        rti




SetupSprites
        lda #$01 ; white
        sta $D027 ; color of sprite 0
        lda #%00000000
        sta $D01C ; multicolor mode off
        lda #%00000001
        sta $D015 ; turn only sprite 0 on
        lda #252
        sta $07F8 ; set sprite 0's pointer to $3F00-$3F39
        lda #$01
        sta $D01D ; sprite nagyítás X irányban
        sta $D017 ; sprite nagyítás Y irányban

        ; position sprite 0
        lda #$0
        sta $D010 ; sprites' X coordinates' 8th bits
        lda #200
        sta $D000 ; 0th sprite's X coordinate
        lda #SPRITE0_POS_Y
        sta $D001 ; 0th sprite's Y coordinate

        ; copy sprite data in memory to $3F00 and $3FC0
        ldx #63
@Loop   lda Sprite1,X
        sta $3F00,X
        lda Sprite2,X
        sta $3F40,X
        dex
        bpl @Loop ; end at X=255

        rts



Sprite0
        BYTE $00,$18,$00
        BYTE $00,$14,$00
        BYTE $00,$37,$00
        BYTE $00,$61,$C0
        BYTE $00,$C0,$70
        BYTE $00,$80,$18
        BYTE $03,$80,$0C
        BYTE $0E,$00,$06
        BYTE $1F,$C1,$FE
        BYTE $01,$C0,$C0
        BYTE $03,$00,$70
        BYTE $0E,$00,$1C
        BYTE $38,$00,$06
        BYTE $7F,$C0,$03
        BYTE $01,$C0,$FF
        BYTE $07,$00,$70
        BYTE $1C,$00,$1C
        BYTE $F0,$00,$06
        BYTE $FF,$CF,$FF
        BYTE $00,$48,$00
        BYTE $00,$48,$00

Sprite1
        BYTE $00,$18,$00
        BYTE $00,$38,$00
        BYTE $00,$24,$00
        BYTE $00,$66,$00
        BYTE $00,$42,$00
        BYTE $00,$C3,$00
        BYTE $00,$81,$80
        BYTE $01,$80,$C0
        BYTE $01,$00,$40
        BYTE $03,$00,$60
        BYTE $02,$00,$30
        BYTE $04,$00,$10
        BYTE $0C,$00,$18
        BYTE $08,$00,$0C
        BYTE $18,$00,$04
        BYTE $30,$00,$06
        BYTE $20,$00,$06
        BYTE $60,$00,$03
        BYTE $40,$00,$03
        BYTE $C0,$00,$01
        BYTE $80,$00,$01

Sprite2
        BYTE $C0,$00,$03
        BYTE $40,$00,$02
        BYTE $60,$00,$06
        BYTE $30,$00,$0C
        BYTE $18,$00,$08
        BYTE $0C,$00,$18
        BYTE $04,$00,$10
        BYTE $02,$00,$20
        BYTE $03,$00,$20
        BYTE $01,$00,$60
        BYTE $01,$00,$40
        BYTE $01,$80,$C0
        BYTE $00,$80,$80
        BYTE $00,$C1,$80
        BYTE $00,$41,$00
        BYTE $00,$63,$00
        BYTE $00,$22,$00
        BYTE $00,$32,$00
        BYTE $00,$16,$00
        BYTE $00,$1C,$00
        BYTE $00,$08,$00














