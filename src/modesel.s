! Mode Select in ARRANGE MODE: the cursor walks ORIGINAL -> MANIAC -> GOD by itself and the player's
! buttons are ignored. The Mode Select state-4 code reads P1 through three small accessors
! (0x0C05CA18 held, 0x0C05CA30 newly pressed, 0x0C05CA48 released; arg 0 = P1, 1 = P2). Their literals in
! that code are replaced by the wrappers below. In ORIGINAL ARCADE they jump straight to the real accessor.
! Time left R = seconds_left*60 + frame_counter (struct 0x0C519B2C +0x38 / +0x30); the screen confirms
! when R reaches about 60 (the timer starts at 4 s, set in menu.s). Once R <= 146 a fake held Down is
! given until the cursor (+0x18) is on GOD (the game's own move animation and 20-frame cooldown make
! it step ORIGINAL -> MANIAC -> GOD).
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
        cmp/ge  r3,r0              ! start walking when R <= S_thr
        bf      8f
        mov.l   @(24,r1),r3        ! cursor
        mov     #2,r2
        cmp/gt  r3,r2              ! 2 > cursor: still short of GOD
        bf      8f
        rts
        mov     #2,r0              ! fake Down held
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
S_thr:    .long 146
