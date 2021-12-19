; 10 SYS (2304)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28, $32, $33, $30, $34, $29, $00, $00, $00

*=$0900

POS_VAR = $02
TIME_VAR = $FB
SCROLL_VAR = $FC
TIME = 1
; együtt mozgassuk a kettőt!
START_CHARACTER = $0400
END_LINE = 58

Start
        sei
        ; disable KERNAL ROM
        lda #$35
        sta $01

        ; disable CIA IRQs
        lda #$7F
        sta $DC0D
        lda $DC0D ; reset flags

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

        ; set handling routine
        lda #<ScrollerSor
        sta $FFFE
        lda #>ScrollerSor
        sta $FFFF

        ; setup IRQ variables
        lda #TIME
        sta TIME_VAR
        lda #$00
        sta POS_VAR
        sta SCROLL_VAR

        ; set CSEL and XSCROLL to 0
        lda #$00
        sta $D016

        cli

        ; nem használhatunk regisztereket,
        ; mert nincs stack-kezelés az IRQ handlerekben
        jmp *
        rts

ScrollerSor
        lda SCROLL_VAR
        sta $D016

        dec TIME_VAR
        bne @End
        lda #TIME
        sta TIME_VAR

        lda SCROLL_VAR
        beq @Step ; if 0 then step
        sec
        sbc #$01
        sta SCROLL_VAR
        sta $D016

@End    ; setup next IRQ
        lda #END_LINE
        sta $D012
        lda #<ScrollerEnd
        sta $FFFE
        lda #>ScrollerEnd
        sta $FFFF

        asl $D019

        rti

@Step
        lda #$07 ; set XSCROLL to 7
        sta SCROLL_VAR
        sta $D016

        ; A: előző, Y: most feldolgozott
        ldx POS_VAR
        lda Message,X
        bne @LpStp

        ; jump to message start
        lda #$00
        sta POS_VAR
        lda Message

@LpStp  inc POS_VAR
        ldx #39
@Loop   ldy START_CHARACTER,X
        sta START_CHARACTER,X

        tya
        dex

        bpl @Loop ; branch on positive => vége van, ha elértünk $255-höz

        jmp @End


ScrollerEnd
        ; wait 57 (63-lda#-sta) cycles then load and store A
        jmp *+3 ; 3 cycles
repeat 27
        nop
endrepeat
        lda #$07
        sta $D016 ; set XSCROLL to 7
@End    ; setup next IRQ
        lda #$00
        sta $D012
        lda #<ScrollerSor
        sta $FFFE
        lda #>ScrollerSor
        sta $FFFF

        asl $D019

        rti

Map
        text '0123456789'

Message
        null 'hello, this is a long text scrolling through your screen! i love pizza! '





