! Mode Select in ARRANGE MODE: the cursor walks ORIGINAL -> MANIAC -> GOD by itself and the player's
! buttons are ignored. The Mode Select state-4 code reads P1 through three small accessors
! (0x0C05CA18 held, 0x0C05CA30 newly pressed, 0x0C05CA48 released; arg 0 = P1, 1 = P2). Their literals in
! that code are replaced by the wrappers below. In ORIGINAL ARCADE they jump straight to the real accessor.
! Time left R = seconds_left*60 + frame_counter (struct 0x0C519B2C +0x38 / +0x30); the screen confirms
! when R reaches about 60 (the timer starts at 3 s, set in menu.s, state 4 begins at R = 106). Walking
! starts at R <= 92 (S_thr): a fake held Down moves the cursor (+0x18) to MANIAC, then 8 frames later
! (S_gap) the game's move lock (busy word 0x0C519B90 and move counter +0x14) is cleared and a second
! Down moves it to GOD. Result: ORIGINAL about 14 frames, MANIAC about 17, GOD about 18, then the
! confirm. Walk state (cursor at the last move, R at that move) is kept at 0x0C7BFF20 / 0x0C7BFF24.
        .set    S_gap, 8
        .align 2
ms_held:
        mov.l   S_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f                 ! ORIGINAL ARCADE: real accessor
        tst     r4,r4
        bf      8f                 ! P2: nothing
        mov.l   S_struct,r1
        mov.l   @(48,r1),r2        ! frame counter
        mov.l   @(56,r1),r3        ! seconds left
        mov     #60,r0
        mulu.w  r0,r3
        sts     macl,r3
        add     r2,r3              ! R
        mov.l   S_thr,r0
        cmp/ge  r3,r0              ! walking starts when R <= S_thr
        bt      3f
        mov.l   S_prev,r0          ! before that: reset the walk state
        mov     #0,r2
        mov.l   r2,@r0
        mov.l   r3,@(4,r0)
        bra     8f
        nop
3:      mov.l   @(24,r1),r2        ! cursor
        mov     #2,r0
        cmp/ge  r0,r2              ! already on GOD
        bt      8f
        mov.l   S_prev,r0
        mov.l   @r0,r4             ! cursor at the last move
        cmp/eq  r4,r2
        bt      4f
        mov.l   r2,@r0             ! the cursor changed: remember when
        mov.l   r3,@(4,r0)
4:      tst     r2,r2
        bt      7f                 ! still on ORIGINAL: first move at once
        mov.l   @(4,r0),r4         ! R at the last move
        sub     r3,r4              ! frames since the last move
        mov     #S_gap,r0
        cmp/ge  r0,r4
        bf      8f                 ! wait
        mov     #0,r0              ! next step: free the game's move lock
        mov.l   S_busy,r4
        mov.w   r0,@r4             ! busy flag 0x0C519B90
        mov.l   r0,@(20,r1)        ! move counter +0x14
7:      mov     #2,r0
        rts
        nop
8:      rts
        mov     #0,r0
9:      mov.l   S_held,r0
        jmp     @r0
        nop
ms_edge:
        mov.l   S_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f
        rts
        mov     #0,r0
9:      mov.l   S_edge,r0
        jmp     @r0
        nop
ms_rel:
        mov.l   S_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f
        rts
        mov     #0,r0
9:      mov.l   S_rel,r0
        jmp     @r0
        nop
        .align 2
S_mode:   .long 0x0C7BFF00
S_struct: .long 0x0C519B2C
S_held:   .long 0x0C05CA18
S_edge:   .long 0x0C05CA30
S_rel:    .long 0x0C05CA48
S_thr:    .long 92
S_prev:   .long 0x0C7BFF20
S_busy:   .long 0x0C519B90
