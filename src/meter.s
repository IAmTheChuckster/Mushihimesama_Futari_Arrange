! Hyper meter (ARRANGE MODE only): 0..10000, small gem +1, big gem +10, full = extra bomb.
! Drawn as a red bar in the empty 2P boxes at the bottom right, with a debug number above it.
        .align 2
! gem_hook: replaces the gem-collect counter call 0x0C06B730(r4 = bomb/stock object, r5 = item type)
gem_hook:
        mov.l   M_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f
        mov.l   M_p1stock,r0
        cmp/eq  r0,r4
        bf      9f
        mov     r5,r0
        cmp/eq  #0,r0
        bt/s    1f
        mov     #1,r1            ! small gem
        cmp/eq  #1,r0
        bf      9f
        mov     #10,r1           ! big gem
1:      mov.l   M_meter,r2
        mov.l   @r2,r3
        add     r1,r3
        mov.w   M_full,r1
        cmp/ge  r1,r3
        bf/s    9f
        mov.l   r3,@r2
        mov     #0,r3            ! full: extra bomb, start again
        mov.l   r3,@r2
        sts.l   pr,@-r15
        mov.l   r4,@-r15
        mov.l   r5,@-r15
        mov.l   r6,@-r15
        mov.l   r7,@-r15
        mov.l   M_addbomb,r0
        jsr     @r0
        nop
        mov.l   @r15+,r7
        mov.l   @r15+,r6
        mov.l   @r15+,r5
        mov.l   @r15+,r4
        lds.l   @r15+,pr
9:      mov.l   M_gemadd,r0
        jmp     @r0
        nop

! player_hook: replaces the per-frame player update call 0x0C067B60(r4 = player).
! In ARRANGE MODE it queues meter_draw in the game's draw list (0x0C05C394, priority PRI).
player_hook:
        sts.l   pr,@-r15
        mov.l   M_pupd,r0
        jsr     @r0
        nop
        mov.l   M_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      8f
        mov.l   M_draw,r4
        mov     #0,r5
        mov.w   M_pri,r6
        mov.l   M_submit,r0
        jsr     @r0
        nop
8:      lds.l   @r15+,pr
        rts
        nop

! meter_draw: called by the game's draw pass; appends blitter sprite commands at @0x0C05100C.
meter_draw:
        mov.l   r8,@-r15
        mov.l   M_dlp,r0
        mov.l   @r0,r7           ! display list write pointer
        mov.l   M_org,r0
        mov.l   @r0+,r4          ! framebuffer origin (high half: y)
        mov.l   @r0,r0
        add     r0,r4            ! + x origin
        mov.l   M_meter,r0
        mov.l   @r0,r8           ! meter value
        ! --- bar: a red-tinted copy of the box strip, fill px wide ---
        mov     #104,r0
        mulu.w  r0,r8
        sts     macl,r1
        mov.l   M_recip1e4,r0
        dmulu.l r0,r1
        sts     mach,r1          ! fill 0..104
        tst     r1,r1
        bt      1f
        mov.l   M_bardest,r5
        add     r4,r5            ! dest of the first segment
3:      mov     #8,r2
        cmp/gt  r1,r2
        bf      4f
        mov     r1,r2            ! last, partial segment
4:      mov.l   M_hdr,r0
        mov.l   r0,@r7
        mov.l   M_bartile,r0
        mov.l   r0,@(4,r7)
        mov.l   r5,@(8,r7)
        mov     r2,r0
        add     #-1,r0
        mov.l   M_barsize,r3
        or      r3,r0
        mov.l   r0,@(12,r7)
        mov.l   M_red,r0
        mov.l   r0,@(16,r7)
        add     #20,r7
        add     r2,r5
        sub     r2,r1
        cmp/pl  r1
        bt      3b
        ! --- 5 digits, right to left ---
1:      mov.l   M_numdest,r6
        add     r4,r6
        mov     #5,r3
        mov.l   M_recip10,r5
2:      dmulu.l r5,r8
        sts     mach,r2
        shlr2   r2
        shlr    r2               ! q
        mov     r2,r1
        shll2   r1
        add     r2,r1
        add     r1,r1
        mov     r8,r0
        sub     r1,r0            ! digit
        mov     r2,r8
        shll2   r0
        add     r0,r0            ! digit*8
        mov.l   M_digtile,r1
        add     r1,r0
        mov.l   M_hdr,r1
        mov.l   r1,@r7
        mov.l   r0,@(4,r7)
        mov.l   r6,@(8,r7)
        mov.l   M_digsize,r0
        mov.l   r0,@(12,r7)
        mov.l   M_white,r0
        mov.l   r0,@(16,r7)
        add     #20,r7
        dt      r3
        bf/s    2b
        add     #-7,r6           ! next digit 7 px to the left
        mov.l   M_dlp,r0
        mov.l   r7,@r0
        rts
        mov.l   @r15+,r8
        .align 2
M_full:  .word FULL
M_pri:   .word PRI
        .align 2
M_mode:    .long 0x0C7BFF00
M_meter:   .long 0x0C7BFF18
M_p1stock: .long 0x0C383A1C
M_addbomb: .long 0x0C06BBD0
M_gemadd:  .long 0x0C06B730
M_pupd:    .long 0x0C067B60
M_submit:  .long 0x0C05C394
M_draw:    .long meter_draw
M_dlp:     .long 0x0C05100C
M_org:     .long 0x0C051004
M_hdr:     .long 0x11000000
M_bartile: .long 0x03F800B8      ! solid block tile (the HUD gauge segment)
M_bardest: .long ((0x138-312+BARY0)<<16)+BARX
M_barsize: .long BARROWS<<16     ! height-1 in the high half
M_red:     .long TINT
M_digtile: .long 0x04F80080
M_digsize: .long 0x00070007
M_numdest: .long ((0x138-NUMY)<<16)+NUMX
M_white:   .long 0x808080
M_recip10: .long 0xCCCCCCCD
M_recip1e4:.long 429497
