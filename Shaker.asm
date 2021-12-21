; 10 SYS (2304)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28, $32, $33, $30, $34, $29, $00, $00, $00

*=$0900

POS_VAR = $02 ; következő kiírandó
POS_START_VAR = $FB ; előzőleg kiírt (legelőre)
SCROLL_VAR = $FC
DIR_VAR = $FD ; 0: balra, 1: jobbra

VIC_IRQ = $FE ; FE-FF: vector to IRQ
; együtt mozgassuk a kettőt!
START_CHARACTER = $0400
END_LINE = 58
START_CHARACTER_INDEX = 40 ; start for POS_VAR
START_START_CHARACTER_INDEX = 1 ; start for POS_START_VAR

Start
        sei
        jsr InitIRQs
        jsr InitFirstLine
        cli

        ; nem használhatunk regisztereket,
        ; mert nincs stack-kezelés az IRQ handlerekben
        jmp *
        rts

InitFirstLine
        ; setup step variables
        lda #START_CHARACTER_INDEX
        sta POS_VAR
        lda #START_START_CHARACTER_INDEX
        sta POS_START_VAR

        ; fill screen
        ldx #39
        lda POS_VAR
        sec
        sbc #1
        tay
@Loop   lda Message,Y
        sta START_CHARACTER,X
        dey
        bpl @ConD
        ldy MessageEndIndex

@ConD   dex

        bpl @Loop

        rts


InitIRQs
        ; disable KERNAL ROM
        lda #$35
        sta $01

        ; setup CIA IRQs
        lda #%00011111 ; reset the CIA IRQs
        sta $DC0D
        lda #%10000010 ; IRQ on timer B underflow
        sta $DC0D
        lda $DC0D ; clear IRQ flags

        lda #$10 ; set timer A to 10.000 and B to 100: 1.000.000 utasítás (1 mp)
        sta $DC04
        lda #$27
        sta $DC05
        lda #100
        sta $DC06
        lda #$00
        sta $DC07

        ; setup and start the A timer
        lda #%00010001
        ; setup and start the B timer
        lda #%01010001
        sta $DC0F


        ; set VIC-II interrupt
        lda #$7F
        and $D011 ; clear MSB of RASTER (IRQ in upper half of screen)
        sta $D011

        ; set RASTER value
        lda #$00
        sta $D012

        ; enable IRQs from VIC-II
        lda #$01
        sta $D01A

        ; set handling routines
        lda #<IRQHandler
        sta $FFFE
        lda #>IRQHandler
        sta $FFFF

        lda #<ScrollerSor
        sta VIC_IRQ
        lda #>ScrollerSor
        sta VIC_IRQ+1

        ; setup IRQ variables
        lda #7
        sta SCROLL_VAR
        lda #$00
        sta DIR_VAR

        ; set CSEL to 0 and XSCROLL to 7
        lda #$07
        sta $D016
        rts


; VIC IRQ esetén 13, CIA IRQ esetén 11 ciklus
IRQHandler
        lda #$01
        and $D019 ; nem nulla: VIC IRQ, nulla: CIA IRQ
        beq CIA_IRQ ; közelben kell lennie
        jmp (VIC_IRQ)





CIA_IRQ
        ; switch direction
        lda #$01
        eor DIR_VAR
        sta DIR_VAR
        bne @Right
; set POS_VAR and POS_START_VAR
@Left   lda POS_START_VAR
        clc
        adc #39
        cmp MessageLength
        bcc @Stl ; nincs carry => nincs overflow
        ; overflow
        sbc MessageLength

@StL    sta POS_VAR

        ; stop the B timer
        lda #%01010000
        ; setup B timer
        lda #100
        sta $DC06
        ; start the B timer
        lda #%01010001
        sta $DC0F

        jmp @End



@Right  lda POS_VAR
        sec
        sbc #39
        bcs @StR ; van carry => nincs underflow
        ; underflow
        adc MessageLength
@StR    sta POS_START_VAR

        ; stop the B timer
        lda #%01010000
        ; setup B timer
        lda #50
        sta $DC06
        ; start the B timer
        lda #%01010001
        sta $DC0F


@End    ; reset IRQ flags in CIA
        lda $DC0D
        rti







ScrollerSor
        lda SCROLL_VAR
        sta $D016

        ldx DIR_VAR
        bne @Right
@Left   lda SCROLL_VAR
        beq @StepLeft ; if 0 then step
        sec
        sbc #$01
        sta SCROLL_VAR
        sta $D016
        jmp @End

@Right  lda SCROLL_VAR
        cmp #7
        beq @StepRight ; if 7 then step
        clc
        adc #$01
        sta SCROLL_VAR
        sta $D016

@End    ; setup next IRQ
        lda #END_LINE
        sta $D012
        lda #<ScrollerEnd
        sta VIC_IRQ
        lda #>ScrollerEnd
        sta VIC_IRQ+1

        asl $D019

        rti




@StepLeft
        lda #$07 ; set XSCROLL to 7
        sta SCROLL_VAR
        sta $D016

        ldx POS_VAR
        lda Message,X
        bne @LpStp

        ; jump to message start
        lda #$00
        sta POS_VAR
        lda Message

        ; balra másolás
        ; A: előző, Y: most feldolgozott
@LpStp  inc POS_VAR
        ldx #39
@Loop   ldy START_CHARACTER,X
        sta START_CHARACTER,X

        tya
        dex

        bpl @Loop ; branch on positive => vége van, ha elértünk $255-höz

        jmp @End




@StepRight
        lda #$00 ; set XSCROLL to 0
        sta SCROLL_VAR
        sta $D016

        ; jobbra másolás
        dec POS_START_VAR
        ldx #39
@Loop2  lda START_CHARACTER-1,X
        sta START_CHARACTER,X

        dex

        bne @Loop2 ; branch on positive => vége van, ha elértünk 0-hoz


        ldx POS_START_VAR
        ;sec
        ;  ; első előtti x|...|P
        ; (x: kell, |: képrenyő széle, ...: 40 db karakter a képernyőn, p: POS_VAR)
        ; lenti -1 miatt nem kell 40-et kivonni
        ;sbc #39
        ;tax
        lda Message-1,X ; -1, hogy a kezdeti 0 is látszódjon
        bne @New

        ; jump to message end
        ldx MessageLength
        stx POS_START_VAR
        lda Message-1,X

@New    sta START_CHARACTER

        jmp @End





ScrollerEnd
        ; wait 44 (63-lda#-sta-init{13}) cycles then load and store A
repeat 22
        nop
endrepeat
        lda #$07
        sta $D016 ; set XSCROLL to 7
@End    ; setup next IRQ
        lda #$00
        sta $D012
        lda #<ScrollerSor
        sta VIC_IRQ
        lda #>ScrollerSor
        sta VIC_IRQ+1

        asl $D019

        rti

Map
        text '0123456789'

        byte 0
Message
        null 'hello, this is a long text scrolling through your screen! i love pizza! '
MessageLength
        byte 72 ; max 128 lehet!!
MessageEndIndex
        byte 71





