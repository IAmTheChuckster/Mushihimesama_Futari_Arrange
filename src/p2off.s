! 2P off (ARRANGE MODE only). The main loop calls the input poll 0x0C05C55C once per frame through a literal
! (0x0C062F80). In ARRANGE MODE this wrapper runs the poll and then clears the P2 input struct
! (0x0C05C4AC: held +12, newly pressed +16, released +20), so 2P START, the P2 stick and buttons never reach the game.
        .align 2
p2_hook:
        sts.l   pr,@-r15
        mov.l   Q_poll,r0
        jsr     @r0
        nop
        mov.l   Q_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f
        mov.l   Q_p2,r1
        mov     #0,r0
        mov.l   r0,@(12,r1)
        mov.l   r0,@(16,r1)
        mov.l   r0,@(20,r1)
9:      lds.l   @r15+,pr
        rts
        nop
        .align 2
Q_poll:   .long 0x0C05C55C
Q_mode:   .long 0x0C7BFF00
Q_p2:     .long 0x0C05C4AC
