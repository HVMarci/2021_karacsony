; 10 SYS (2304)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28, $32, $33, $30, $34, $29, $00, $00, $00

*=$0900

START_LINE = 100
MID_LINE = 121

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
        lda #MID_LINE-1
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
        ; wait for border
        jmp *+3
repeat 25
        nop
endrepeat
        ; change 0th sprite's Y position
        lda $D001
        cmp #START_LINE
        beq @Down ; carry will be always set after this operation

@Up     sbc #21
        sta $D001
        lda $D003
        sbc #21
        ldx #MID_LINE-1
        jmp @End

@Down   clc
        adc #21
        sta $D001
        lda $D003
        adc #21
        ldx #MID_LINE+50

@End    sta $D003
        stx $D012

        ; alja-teteje váltás
        lda #$01
        eor $07F8
        sta $07F8
        lda #$01
        eor $07F9
        sta $07F9

        and #$01
        bne @Fin2 ; csak egyszer változtassuk az X-et

        lda #$00
@S0     ldx $D000
        bne @S1
        ora #1

@S1     ldx $D002
        bne @S2
        ora #2

@S2     ldx $D004
        bne @S3
        ora #4

@S3     ldx $D006
        bne @S4
        ora #8

@S4     ldx $D008
        bne @S5
        ora #16

@S5     ldx $D00A
        bne @S6
        ora #32

@S6     ldx $D00C
        bne @S7
        ora #64

@S7     ldx $D00E
        bne @SE
        ora #128

@SE     eor $D010 ; 8th bit of X positions
        sta $D010


@Fin1   dec $D000 ; 0th sprite's X
        dec $D002 ; 1st sprite's X
        dec $D004 ; 2nd sprite's X
        dec $D006 ; 3rd sprite's X
        dec $D008 ; 4th sprite's X
        dec $D00A ; 5st sprite's X
        dec $D00C ; 6th sprite's X
        dec $D00E ; 7st sprite's X
@Fin2   lda $D010
        sta $0451
        lda $D000
        sta $0452

        asl $D019
        rti




SetupSprites
        lda #$01 ; white
        sta $D027 ; color of sprite 0
        sta $D028 ; color of sprite 1
        lda #%00000000
        sta $D01C ; multicolor mode off
        lda #%00000011
        sta $D015 ; turn the sprites on
        lda #252
        sta $07F8 ; set sprite 0's pointer to $3F00-$3F39
        lda #254
        sta $07F9 ; set sprite 1's pointer to $3F80-$3FB9
        lda #$00
        sta $D01D ; sprite nagyítás X irányban
        sta $D017 ; sprite nagyítás Y irányban

        ; position sprite 0
        lda #$00
        sta $D010 ; sprites' X coordinates' 8th bits
        lda #200
        sta $D000 ; 0th sprite's X coordinate
        lda #START_LINE
        sta $D001 ; 0th sprite's Y coordinate
        lda #226
        sta $D002 ; 1th sprite's X coordinate
        lda #START_LINE+1
        sta $D003 ; 1th sprite's Y coordinate

        ; copy sprite data in memory to $3F00 and $3FC0
        ldx #63
@Loop   lda SpriteBTeteje,X
        sta $3F00,X
        lda SpriteBAlja,X
        sta $3F40,X
        lda Sprite1,X
        sta $3F80,X
        lda Sprite2,X
        sta $3FC0,X
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



SpriteBAlja
        BYTE $3F,$FF,$F0
        BYTE $3C,$03,$F8
        BYTE $3C,$00,$7C
        BYTE $3C,$00,$1E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$1E
        BYTE $3C,$00,$7E
        BYTE $3F,$FF,$F8
        BYTE $3F,$FF,$E0
        BYTE $00,$00,$00
        BYTE $00,$00,$00


SpriteBTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3F,$FF,$F0
        BYTE $3F,$FF,$F8
        BYTE $3C,$00,$7C
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$3C
        BYTE $3C,$00,$FC
        BYTE $3F,$FF,$F0














