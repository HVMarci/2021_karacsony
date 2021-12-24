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
        lda #MID_LINE-3
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
; csak a 11. ciklusban kapunk processzoridőt
; az első sorból elfogyasztjuk mind a 47 elérhető ciklust
; a másodikból pedig 4-et, ezért 43-at kell majd várni

; alja-teteje pozíció váltás
        lda $D001 ; 4 cycles
        cmp #START_LINE ; 2 cycles
        beq @Down ; carry will be always set after this operation ; 3 cycles

@Up     sbc #21
        ldx #MID_LINE-3
        jmp @End

@Down   clc ; 2 cycles
        adc #21 ; 2 cycles
        ldx #MID_LINE+50 ; 2 cycles
        ; ez a rész: 15 cycles

@End    sta $D001 ; 4 cycles
        sta $D003
        sta $D005
        sta $D007
        sta $D009
        sta $D00B
        sta $D00D
        sta $D00F
        stx $D012 ; 4 cycles
        ; ez a rész: 8 * 4 + 4 = 36 cycles
        ; total: 15 + 36 = 51 cycles
        
; várakozás, az 58. ciklust már lefoglalja a VIC => 43 ciklust kell várni
        jmp *+3 ; 3 cycles
repeat 30 ; 60 cycles (32-nek kéne lennie, de valamiért így működik :/ )
        nop
endrepeat
        ; előrehozott kód, a vége gyorsításának érdekében
        clc ; 2 cycles
        lda #$01 ; 2 cycles
        eor $07F8 ; 4 cycles

; a 11. ciklusban kapunk újra processzoridőt, az 58.-ig készen kell lennünk => 47 ciklusunk van
; alja-teteje kinézet váltás
; V1
;        lda #$01 ; 2 cycles
;        eor $07F8 ; 4 cycles
;        sta $07F8 ; 4 cycles
;        ; total: 10 * 8 = 80 cycles

; V2
        sta $07F8 ; 4 cycles

        adc #4 ; 2 cycles
        sta $07F9 ; 4 cycles

        adc #4
        sta $07FA
        adc #4
        sta $07FB
        adc #4
        sta $07FC
        adc #4
        sta $07FD
        adc #4
        sta $07FE
        adc #4
        sta $07FF
        ; total: 4 + 7 * 6 = 46 cycles => éppen belefér az egy sornyi 47-be
        ; egész total: 168 ciklus (TODO: rájönni hogy mi a francért kell ennyit várni)

        and #$01
        beq @Next ; csak egyszer változtassuk az X-et
        jmp @Finish


; az X pozíciók 8. bitjének megváltoztatása + betűváltás
@Next   lda #$00
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

        tay
        lda $D010
        and #128
        bne @EfN

        lda $07F8
        eor #%00000010
        sta $07F8
        adc #4
        sta $07F9
        adc #4
        sta $07FA
        adc #4
        sta $07FB
        adc #4
        sta $07FC
        adc #4
        sta $07FD
        adc #4
        sta $07FE
        adc #4

@EfN    tya

@SE     eor $D010 ; 8th bit of X positions
        sta $D010


        dec $D000 ; 0th sprite's X
        lda $D00E
        sta $0456
        dec $D002 ; 1st sprite's X
        dec $D004 ; 2nd sprite's X
        dec $D006 ; 3rd sprite's X
        dec $D008 ; 4th sprite's X
        dec $D00A ; 5st sprite's X
        dec $D00C ; 6th sprite's X
        dec $D00E ; 7st sprite's X
        lda $D00E
        sta $0457

@Finish ; Random debugging info
        lda $D010
        sta $0451
        lda $D000
        sta $0452

        asl $D019
        rti




SetupSprites
        lda #$08
        ldx #$08
        sec
@Loop1  sta $D026
        sbc #$01
        dex
        bne @Loop1

        lda #$00
        sta $D01C ; multicolor mode off
        lda #%11111111
        sta $D015 ; turn the sprites on

        ; set sprites' pointers
        lda #200
        sta $07F8
        lda #204
        sta $07F9
        lda #208
        sta $07FA
        lda #212
        sta $07FB
        lda #216
        sta $07FC
        lda #220
        sta $07FD
        lda #224
        sta $07FE
        lda #228
        sta $07FF

        lda #$00
        sta $D01D ; sprite nagyítás X irányban
        sta $D017 ; sprite nagyítás Y irányban

        ; position sprites
        lda #$00
        sta $D010 ; sprites' X coordinates' 8th bits

        lda #64
        sta $D000 ; 0th sprite's X coordinate
        lda #START_LINE
        sta $D001 ; 0th sprite's Y coordinate

        lda #90 
        sta $D002 ; 1st sprite's X coordinate
        lda #START_LINE
        sta $D003 ; 1st sprite's Y coordinate

        lda #116
        sta $D004 ; 2nd sprite's X coordinate
        lda #START_LINE
        sta $D005 ; 2nd sprite's Y coordinate

        lda #142
        sta $D006 ; 3rd sprite's X coordinate
        lda #START_LINE
        sta $D007 ; 3rd sprite's Y coordinate

        lda #168
        sta $D008 ; 4th sprite's X coordinate
        lda #START_LINE
        sta $D009 ; 4th sprite's Y coordinate

        lda #194
        sta $D00A ; 5th sprite's X coordinate
        lda #START_LINE
        sta $D00B ; 5th sprite's Y coordinate

        lda #220
        sta $D00C ; 6th sprite's X coordinate
        lda #START_LINE
        sta $D00D ; 6th sprite's Y coordinate

        lda #246
        sta $D00E ; 7th sprite's X coordinate
        lda #START_LINE
        sta $D00F ; 7th sprite's Y coordinate

        ; copy sprite datas into memory
        ldx #63
@Loop   lda SpriteBTeteje,X
        sta $3200,X
        lda SpriteBAlja,X
        sta $3240,X
        lda SpriteRTeteje,X
        sta $3280,X
        lda SpriteRAlja,X
        sta $32C0,X

        lda SpriteOTeteje,X
        sta $3300,X
        lda SpriteOAlja,X
        sta $3340,X
        lda SpriteAATeteje,X
        sta $3380,X
        lda SpriteAAAlja,X
        sta $33C0,X

        lda SpriteLTeteje,X
        sta $3400,X
        lda SpriteLAlja,X
        sta $3440,X
        lda SpriteCTeteje,X
        sta $3480,X
        lda SpriteCAlja,X
        sta $34C0,X

        lda SpriteDTeteje,X
        sta $3500,X
        lda SpriteDAlja,X
        sta $3540,X
        lda SpriteSTeteje,X
        sta $3580,X
        lda SpriteSAlja,X
        sta $35C0,X

        lda SpriteOTeteje,X
        sta $3600,X
        sta $3680,X
        lda SpriteOAlja,X
        sta $3640,X
        sta $36C0,X

        lda SpriteGTeteje,X
        sta $3700,X
        lda SpriteGAlja,X
        sta $3740,X
        lda SpriteNTeteje,X
        sta $3780,X
        lda SpriteNAlja,X
        sta $37C0,X

        lda SpriteKTeteje,X
        sta $3800,X
        lda SpriteKAlja,X
        sta $3840,X
        lda SpriteYTeteje,X
        sta $3880,X
        lda SpriteYAlja,X
        sta $38C0,X

        lda SpriteATeteje,X
        sta $3900,X
        lda SpriteAAlja,X
        sta $3940,X
        lda SpriteTTeteje,X
        sta $3980,X
        lda SpriteTAlja,X
        sta $39C0,X

        dex
        bmi @End ; end at X=255
        jmp @Loop

@End    rts



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

SpriteOTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$7F,$00
        BYTE $01,$FF,$C0
        BYTE $03,$E3,$E0
        BYTE $07,$01,$F0
        BYTE $0E,$00,$F8
        BYTE $1C,$00,$78
        BYTE $38,$00,$1C
        BYTE $30,$00,$0E
        BYTE $30,$00,$0E
        BYTE $60,$00,$07
        BYTE $60,$00,$03
        BYTE $60,$00,$03
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03

SpriteOAlja
        BYTE $C0,$00,$03
        BYTE $E0,$00,$03
        BYTE $60,$00,$03
        BYTE $60,$00,$03
        BYTE $60,$00,$03
        BYTE $60,$00,$07
        BYTE $60,$00,$07
        BYTE $20,$00,$07
        BYTE $30,$00,$07
        BYTE $30,$00,$07
        BYTE $30,$00,$06
        BYTE $30,$00,$06
        BYTE $38,$00,$06
        BYTE $18,$00,$0E
        BYTE $1C,$00,$0C
        BYTE $0E,$00,$1C
        BYTE $0F,$00,$1C
        BYTE $07,$80,$F8
        BYTE $03,$F3,$E0
        BYTE $00,$FF,$C0
        BYTE $00,$1E,$00

SpriteLTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00

SpriteLAlja
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3F,$FF,$F8
        BYTE $3F,$FF,$F8
        BYTE $3F,$FF,$F8
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteDTeteje
        BYTE $00,$00,$00
        BYTE $1F,$E0,$00
        BYTE $3F,$F0,$00
        BYTE $3C,$F8,$00
        BYTE $3C,$3C,$00
        BYTE $3C,$0E,$00
        BYTE $3C,$07,$00
        BYTE $3C,$03,$80
        BYTE $3C,$01,$C0
        BYTE $3C,$00,$E0
        BYTE $3C,$00,$E0
        BYTE $3C,$00,$70
        BYTE $3C,$00,$70
        BYTE $3C,$00,$38
        BYTE $3C,$00,$38
        BYTE $3C,$00,$18
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C

SpriteDAlja
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$18
        BYTE $3C,$00,$18
        BYTE $3C,$00,$18
        BYTE $3C,$00,$30
        BYTE $3C,$00,$70
        BYTE $3C,$00,$60
        BYTE $3C,$00,$E0
        BYTE $3C,$01,$C0
        BYTE $3C,$03,$80
        BYTE $3C,$03,$80
        BYTE $3C,$07,$00
        BYTE $3C,$1E,$00
        BYTE $3E,$78,$00
        BYTE $3F,$F0,$00
        BYTE $1F,$80,$00
        BYTE $00,$00,$00

SpriteGTeteje
        BYTE $00,$00,$00
        BYTE $00,$7F,$E0
        BYTE $03,$FF,$F8
        BYTE $0F,$FF,$FC
        BYTE $0F,$E0,$3E
        BYTE $1F,$00,$1E
        BYTE $3E,$00,$0E
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
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00

SpriteGAlja
        BYTE $3C,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$01,$FE
        BYTE $3C,$01,$FE
        BYTE $3C,$01,$FE
        BYTE $3C,$00,$1E
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$0E
        BYTE $3C,$00,$1E
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$38
        BYTE $3E,$00,$38
        BYTE $1F,$00,$70
        BYTE $0F,$FF,$F0
        BYTE $03,$FF,$E0
        BYTE $00,$FF,$80
        BYTE $00,$00,$00

SpriteKTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3C,$00,$00
        BYTE $3C,$00,$70
        BYTE $3C,$00,$F8
        BYTE $3C,$01,$F8
        BYTE $3C,$01,$F0
        BYTE $3C,$03,$F0
        BYTE $3C,$03,$E0
        BYTE $3C,$07,$E0
        BYTE $3C,$07,$C0
        BYTE $3C,$0F,$C0
        BYTE $3C,$0F,$80
        BYTE $3C,$1F,$80
        BYTE $3C,$1F,$00
        BYTE $3C,$3F,$00
        BYTE $3C,$3E,$00
        BYTE $3C,$7E,$00
        BYTE $3C,$7C,$00
        BYTE $3C,$F8,$00
        BYTE $3C,$F8,$00

SpriteKAlja
        BYTE $3D,$E0,$00
        BYTE $3F,$E0,$00
        BYTE $3F,$C0,$00
        BYTE $3F,$C0,$00
        BYTE $3F,$C0,$00
        BYTE $3F,$C0,$00
        BYTE $3F,$E0,$00
        BYTE $3F,$F0,$00
        BYTE $3F,$F8,$00
        BYTE $3C,$FC,$00
        BYTE $3C,$7E,$00
        BYTE $3C,$3F,$00
        BYTE $3C,$1F,$80
        BYTE $3C,$0F,$C0
        BYTE $3C,$07,$C0
        BYTE $3C,$03,$E0
        BYTE $3C,$01,$F0
        BYTE $3C,$00,$F8
        BYTE $3C,$00,$78
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteATeteje
        BYTE $00,$08,$00
        BYTE $00,$08,$00
        BYTE $00,$1C,$00
        BYTE $00,$1C,$00
        BYTE $00,$3E,$00
        BYTE $00,$36,$00
        BYTE $00,$36,$00
        BYTE $00,$77,$00
        BYTE $00,$63,$00
        BYTE $00,$E3,$80
        BYTE $00,$C1,$80
        BYTE $00,$C1,$80
        BYTE $01,$C1,$C0
        BYTE $01,$80,$C0
        BYTE $01,$80,$C0
        BYTE $03,$80,$E0
        BYTE $03,$00,$60
        BYTE $03,$00,$60
        BYTE $06,$00,$30
        BYTE $06,$00,$30
        BYTE $06,$00,$30

SpriteAAlja
        BYTE $0C,$00,$30
        BYTE $0C,$00,$30
        BYTE $0F,$FF,$F0
        BYTE $1F,$FF,$F8
        BYTE $18,$00,$18
        BYTE $18,$00,$18
        BYTE $38,$00,$1C
        BYTE $38,$00,$1C
        BYTE $38,$00,$1C
        BYTE $30,$00,$0C
        BYTE $30,$00,$0C
        BYTE $70,$00,$0E
        BYTE $70,$00,$06
        BYTE $60,$00,$06
        BYTE $60,$00,$06
        BYTE $E0,$00,$07
        BYTE $E0,$00,$07
        BYTE $C0,$00,$03
        BYTE $C0,$00,$03
        BYTE $80,$00,$01
        BYTE $80,$00,$01

SpriteRTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3F,$C0,$00
        BYTE $3F,$F8,$00
        BYTE $3C,$FF,$00
        BYTE $3C,$0F,$C0
        BYTE $3C,$01,$E0
        BYTE $3C,$00,$F0
        BYTE $3C,$00,$78
        BYTE $3C,$00,$38
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$06
        BYTE $3C,$00,$0C
        BYTE $3C,$00,$1C
        BYTE $3C,$00,$38

SpriteRAlja
        BYTE $3C,$00,$38
        BYTE $3C,$00,$F8
        BYTE $3C,$0F,$F8
        BYTE $3F,$FF,$F0
        BYTE $3F,$FF,$80
        BYTE $3F,$FC,$00
        BYTE $3C,$1C,$00
        BYTE $3C,$0E,$00
        BYTE $3C,$0F,$00
        BYTE $3C,$07,$00
        BYTE $3C,$07,$80
        BYTE $3C,$03,$80
        BYTE $3C,$01,$C0
        BYTE $3C,$01,$E0
        BYTE $3C,$00,$E0
        BYTE $3C,$00,$70
        BYTE $3C,$00,$70
        BYTE $3C,$00,$78
        BYTE $3C,$00,$38
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteAATeteje ; á
        BYTE $00,$00,$60
        BYTE $00,$00,$E0
        BYTE $00,$00,$C0
        BYTE $00,$01,$C0
        BYTE $00,$1B,$80
        BYTE $00,$1B,$80
        BYTE $00,$3D,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$66,$00
        BYTE $00,$66,$00
        BYTE $00,$E7,$00
        BYTE $00,$C3,$00
        BYTE $00,$C3,$00
        BYTE $00,$C3,$00
        BYTE $01,$C3,$80
        BYTE $01,$81,$80
        BYTE $01,$81,$80
        BYTE $03,$81,$C0
        BYTE $03,$00,$C0
        BYTE $03,$00,$C0

SpriteAAAlja ; á
        BYTE $07,$00,$E0
        BYTE $07,$00,$E0
        BYTE $07,$00,$E0
        BYTE $07,$FF,$E0
        BYTE $07,$FF,$E0
        BYTE $0F,$FF,$F0
        BYTE $0E,$00,$70
        BYTE $0E,$00,$70
        BYTE $0C,$00,$38
        BYTE $1C,$00,$38
        BYTE $1C,$00,$38
        BYTE $1C,$00,$38
        BYTE $3C,$00,$3C
        BYTE $38,$00,$1C
        BYTE $38,$00,$1C
        BYTE $38,$00,$1C
        BYTE $30,$00,$0C
        BYTE $30,$00,$0C
        BYTE $30,$00,$0C
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteCTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$1F,$C0
        BYTE $00,$3F,$F0
        BYTE $00,$70,$78
        BYTE $00,$E0,$38
        BYTE $01,$C0,$1C
        BYTE $01,$C0,$0C
        BYTE $03,$80,$06
        BYTE $03,$00,$06
        BYTE $07,$00,$02
        BYTE $06,$00,$00
        BYTE $0E,$00,$00
        BYTE $0E,$00,$00
        BYTE $0C,$00,$00
        BYTE $0C,$00,$00
        BYTE $0C,$00,$00
        BYTE $0C,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00

SpriteCAlja
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $0C,$00,$00
        BYTE $0E,$00,$00
        BYTE $0E,$00,$00
        BYTE $0E,$00,$00
        BYTE $06,$00,$0E
        BYTE $07,$00,$0E
        BYTE $07,$80,$0E
        BYTE $03,$80,$1E
        BYTE $01,$C0,$1C
        BYTE $01,$E0,$FC
        BYTE $00,$FF,$F8
        BYTE $00,$7F,$E0
        BYTE $00,$3F,$80
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteSTeteje
        BYTE $00,$00,$00
        BYTE $00,$3C,$00
        BYTE $01,$FF,$C0
        BYTE $07,$FF,$E0
        BYTE $07,$81,$F0
        BYTE $0F,$00,$F8
        BYTE $0E,$00,$78
        BYTE $0E,$00,$38
        BYTE $0E,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $1C,$00,$00
        BYTE $0E,$00,$00
        BYTE $0E,$00,$00
        BYTE $0E,$00,$00
        BYTE $07,$00,$00
        BYTE $07,$00,$00
        BYTE $03,$80,$00
        BYTE $01,$C0,$00
        BYTE $00,$F8,$00
        BYTE $00,$3C,$00

SpriteSAlja
        BYTE $00,$3C,$00
        BYTE $00,$1F,$80
        BYTE $00,$0F,$E0
        BYTE $00,$01,$F0
        BYTE $00,$00,$F0
        BYTE $00,$00,$F0
        BYTE $00,$00,$78
        BYTE $00,$00,$38
        BYTE $00,$00,$1C
        BYTE $00,$00,$1C
        BYTE $00,$00,$1C
        BYTE $00,$00,$0C
        BYTE $30,$00,$0C
        BYTE $38,$00,$0C
        BYTE $38,$00,$1C
        BYTE $1C,$00,$7C
        BYTE $1E,$00,$F8
        BYTE $0F,$FF,$E0
        BYTE $07,$FF,$80
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteNTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3E,$00,$3C
        BYTE $3E,$00,$3C
        BYTE $3F,$00,$3C
        BYTE $3F,$80,$3C
        BYTE $3F,$80,$3C
        BYTE $3F,$C0,$3C
        BYTE $3F,$C0,$3C
        BYTE $3F,$C0,$3C
        BYTE $3F,$E0,$3C
        BYTE $3D,$E0,$3C
        BYTE $3C,$E0,$3C
        BYTE $3C,$F0,$3C
        BYTE $3C,$70,$3C
        BYTE $3C,$70,$3C
        BYTE $3C,$78,$3C
        BYTE $3C,$78,$3C
        BYTE $3C,$38,$3C
        BYTE $3C,$3C,$3C
        BYTE $3C,$3C,$3C

SpriteNAlja
        BYTE $3C,$3C,$3C
        BYTE $3C,$3C,$3C
        BYTE $3C,$1E,$3C
        BYTE $3C,$1E,$3C
        BYTE $3C,$0E,$3C
        BYTE $3C,$0F,$3C
        BYTE $3C,$0F,$3C
        BYTE $3C,$07,$BC
        BYTE $3C,$07,$BC
        BYTE $3C,$03,$FC
        BYTE $3C,$01,$FC
        BYTE $3C,$01,$FC
        BYTE $3C,$01,$FC
        BYTE $3C,$00,$FC
        BYTE $3C,$00,$FC
        BYTE $3C,$00,$7C
        BYTE $3C,$00,$3C
        BYTE $3C,$00,$3C
        BYTE $3C,$00,$3C
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteYTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $30,$00,$0C
        BYTE $38,$00,$1C
        BYTE $1C,$00,$38
        BYTE $1C,$00,$38
        BYTE $0E,$00,$70
        BYTE $0F,$00,$F0
        BYTE $07,$00,$E0
        BYTE $07,$81,$E0
        BYTE $03,$81,$C0
        BYTE $01,$C3,$80
        BYTE $01,$E7,$80
        BYTE $00,$FF,$00
        BYTE $00,$FF,$00
        BYTE $00,$7E,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00

SpriteYAlja
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00

SpriteTTeteje
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $3F,$FF,$FC
        BYTE $3F,$FF,$FC
        BYTE $3F,$FF,$FC
        BYTE $3F,$FF,$FC
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00

SpriteTAlja
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$3C,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00













