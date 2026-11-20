! Grazing (ARRANGE MODE only).
! graze_tick runs once per game frame from player_hook. Every live enemy bullet whose centre is within 24 px of the
! ship's centre counts: the graze counter (0x0C7BFF3C, cap 99999) gains 1 and the score 100 per bullet, every frame
! the bullet stays in the circle (also while the ship is invulnerable). It never counts down; it is reset to 0 on
! the score tally after each stage (player_hook) and on the title (menu.s).
! Ship and bullets share one coordinate system (x across, y up from the bottom, 16.16; high word = pixel):
! ship 0x0C383A68 / 0x0C383A6C, bullets +20 / +24 in the bullet list (manager @0x0C27DE48 + 0x48440, live when
! the state byte +8 is 1 or 2), as in chain.s.
! graze_draw is called from end_wrap (banner.s) when each blitter list is closed. It mimics the x counter (the gem
! multiplier on the left), anchored on its "x" sign (source 0x03E800C0, 8x8, usual row 256, x 4): it looks for that
! draw (backwards from the write pointer, stopping when found) and only then appends the graze counter, with the x
! counter's header (blend/fade), its row and x offsets (it moves and slides out with it) and a gold tint darkened by
! the x counter tint's brightest channel when that is below 0x80 (the max-multiplier colour flashing is not copied).
! Digits: score font (source 0x04F80080 + 8 * digit, 8x8, GSTEP apart), left-justified at GX like the x counter,
! row GY: just above the x counter, below the bomb icons.
        .equ GX, 12              ! left edge of the first digit (the x counter's digits start here too)
        .equ GY, 40
        .equ GSTEP, 7
        .align 2
graze_tick:
        sts.l   pr,@-r15
        mov.l   r8,@-r15
        mov.l   r9,@-r15
        mov.l   r10,@-r15
        mov.l   r11,@-r15
        mov.l   G_shipx,r1
        mov.w   @r1,r9           ! ship x (pixels)
        mov.w   @(4,r1),r0
        mov     r0,r10           ! ship y
        mov     #0,r11           ! bullets in the circle
        mov.l   G_mgr,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      5f
        mov.l   G_list,r1
        add     r1,r0
        mov.l   @r0,r8           ! first bullet
1:      tst     r8,r8
        bt      5f
        mov.b   @(8,r8),r0       ! state 1 or 2 = live
        add     #-1,r0
        extu.b  r0,r0
        mov     #1,r1
        cmp/hi  r1,r0
        bt      4f
        mov.w   @(20,r8),r0
        sub     r9,r0
        mov     r0,r2            ! dx
        cmp/pz  r0
        bt      2f
        neg     r0,r0
2:      mov     #24,r1
        cmp/gt  r1,r0
        bt      4f
        mov.w   @(24,r8),r0
        sub     r10,r0
        mov     r0,r3            ! dy
        cmp/pz  r0
        bt      3f
        neg     r0,r0
3:      cmp/gt  r1,r0
        bt      4f
        muls.w  r2,r2
        sts     macl,r4
        muls.w  r3,r3
        sts     macl,r0
        add     r0,r4            ! dx*dx + dy*dy
        mov.w   G_r2,r1
        cmp/gt  r1,r4
        bt      4f
        add     #1,r11
4:      bra     1b
        mov.l   @r8,r8           ! next bullet
5:      mov.l   G_cnt,r1
        tst     r11,r11
        bt      9f
        mov.l   @r1,r0           ! grazed: counter += n (cap 99999), score += 100 * n
        add     r11,r0
        mov.l   G_cap,r2
        cmp/gt  r2,r0
        bf      6f
        mov     r2,r0
6:      mov.l   r0,@r1
        mov     #100,r0
        mulu.w  r0,r11
        sts     macl,r5
        mov.l   G_stock,r4
        mov.l   G_scadd,r0
        jsr     @r0
        nop
9:      mov.l   @r15+,r11
        mov.l   @r15+,r10
        mov.l   @r15+,r9
        mov.l   @r15+,r8
        lds.l   @r15+,pr
        rts
        nop

graze_draw:
        mov.l   G_wp,r0
        mov.l   @r0,r1           ! r1 = write pointer (end of this frame's list)
        mov.l   G_start,r0
        mov.l   @r0,r2           ! r2 = list start
        mov.l   G_win,r3
        mov     r1,r0
        sub     r3,r0            ! wp - 64 KB
        cmp/hs  r1,r2
        bt      1f               ! start >= wp: not this list
        cmp/hs  r0,r2
        bt      2f
1:      mov     r0,r2            ! look at the last 64 KB only
2:      add     #4,r2            ! a draw record has its header word before the source word
        mov.l   G_org,r0
        mov.l   @r0,r3
        shlr16  r3               ! origin y (high half of dest)
        mov.l   G_xsrc,r5        ! the x counter's "x" sign: source 0x03E800C0, 8x8, usual row 256 / x 4
        mov.l   G_xsize,r6
        mov     r2,r7            ! r7 = lowest address to look at
        mov     r1,r2            ! backwards from the write pointer (the HUD is near the end), stop when found
3:      add     #-4,r2
        cmp/hs  r7,r2
        bf      9f               ! no x counter drawn in this frame: no graze counter either
        mov.l   @r2,r0
        cmp/eq  r5,r0
        bf      3b
        mov.l   @(8,r2),r0
        cmp/eq  r6,r0
        bf      3b
        mov.l   @(4,r2),r0       ! in the x counter's rows (240..275)?
        shlr16  r0
        sub     r3,r0
        mov.w   G_rlo,r1
        cmp/ge  r1,r0
        bf      3b
        mov.w   G_rhi,r1
        cmp/gt  r1,r0
        bt      3b
        mov     r2,r0
        add     #-4,r0
        mov.l   @r0,r4           ! the x counter digit's header (blend / fade)
        mov     r4,r0
        shlr16  r0
        shlr8   r0
        shlr2   r0
        shlr2   r0
        cmp/eq  #1,r0
        bf      3b
        mov.l   r8,@-r15
        mov.l   r9,@-r15
        mov.l   r10,@-r15
        mov     r4,r9            ! r9 = header
        mov.l   @(4,r2),r0       ! its row offset from the usual 256: the graze counter moves the same way
        shlr16  r0
        sub     r3,r0
        mov.w   G_xrow,r1
        sub     r1,r0
        shll16  r0
        mov     r0,r10           ! r10 = row offset << 16
        mov.l   G_org,r0         ! its x offset from the usual 4: the graze counter slides the same way
        mov.l   @(4,r0),r1       ! (out to the left with the x counter before the tally)
        mov.l   @(4,r2),r0
        extu.w  r0,r0
        sub     r1,r0
        mov     #4,r1
        sub     r1,r0
        exts.w  r0,r0
        add     r0,r10           ! + dx as a signed 32-bit value (same direction: both sit on the left)
        mov.l   @(12,r2),r4      ! its tint: brightness s = the brightest channel, at most 0x80
        mov     #0,r6
        mov     #3,r1
4:      mov     r4,r0
        extu.b  r0,r0
        cmp/hi  r6,r0
        bf      5f
        mov     r0,r6
5:      dt      r1
        bf/s    4b
        shlr8   r4
        mov.w   G_x80,r1
        cmp/hi  r1,r6
        bf      6f
        mov     r1,r6            ! r6 = s (0..0x80): flashing colours keep the gold, darkening fades it
6:      mov.l   G_gold,r5        ! gold, channel by channel: c = gold * s / 0x80
        mov     #0,r8
        mov     #0,r4            ! shift of this channel
7:      mov     r5,r0
        extu.b  r0,r0
        mulu.w  r0,r6
        sts     macl,r0
        shlr8   r0
        add     r0,r0            ! / 0x80
        shld    r4,r0
        or      r0,r8
        shlr8   r5
        add     #8,r4
        mov     r4,r0
        cmp/eq  #24,r0
        bf      7b               ! r8 = 0x00RRGGBB
        mov.l   G_wp,r0
        mov.l   @r0,r7           ! append at the write pointer
        mov.l   G_cnt,r0
        mov.l   @r0,r2           ! value
        mov.l   G_org,r0
        mov.l   @r0+,r6
        mov.l   @r0,r0
        add     r0,r6            ! framebuffer origin
        mov.l   G_dest,r0
        add     r0,r6
        add     r10,r6           ! dest of the first digit, moved with the x counter
        mova    G_pow,r0         ! left-justified: the rightmost digit goes (digits - 1) * GSTEP further right
        mov     r0,r3
        mov     #4,r1
1:      mov.l   @r3+,r0          ! 10, 100, 1000, 10000
        cmp/hs  r0,r2
        bf      2f
        add     #GSTEP,r6
        dt      r1
        bf      1b
2:
        mov.l   G_recip10,r5
8:      dmulu.l r5,r2
        sts     mach,r3
        shlr2   r3
        shlr    r3               ! q = value / 10
        mov     r3,r1
        shll2   r1
        add     r3,r1
        add     r1,r1            ! q * 10
        mov     r2,r0
        sub     r1,r0            ! digit
        mov     r3,r2
        shll2   r0
        add     r0,r0            ! digit * 8
        mov.l   G_digtile,r1
        add     r1,r0
        mov.l   r9,@r7
        mov.l   r0,@(4,r7)
        mov.l   r6,@(8,r7)
        mov.l   G_digsize,r0
        mov.l   r0,@(12,r7)
        mov.l   r8,@(16,r7)
        add     #20,r7
        tst     r2,r2
        bf/s    8b
        add     #-GSTEP,r6       ! next digit to the left
        mov.l   G_wp,r0
        mov.l   r7,@r0
        mov.l   @r15+,r10
        mov.l   @r15+,r9
        mov.l   @r15+,r8
9:      rts
        nop
        .align 2
G_pow:     .long 10, 100, 1000, 10000
G_r2:      .word 24*24
G_xrow:    .word 256
G_rlo:     .word 240
G_rhi:     .word 275
G_x80:     .word 0x80
        .align 2
G_shipx:   .long 0x0C383A68
G_mgr:     .long 0x0C27DE48
G_list:    .long 0x00048440
G_cnt:     .long 0x0C7BFF3C     ! graze counter
G_cap:     .long 99999
G_stock:   .long 0x0C383A1C
G_scadd:   .long 0x0C06B120
G_org:     .long 0x0C051004
G_dest:    .long ((0x138-GY)<<16)+GX
G_recip10: .long 0xCCCCCCCD
G_digtile: .long 0x04F80080     ! score font, y = 0x80 + 8 * digit
G_digsize: .long 0x00070007     ! 8 x 8
G_gold:    .long 0x00FFA830     ! tint for gold/orange (0x80 = as drawn)
G_xsrc:    .long 0x03E800C0     ! the x counter's "x" sign
G_xsize:   .long 0x00070007     ! 8x8
G_wp:      .long 0x0C05100C
G_start:   .long 0x0C051000
G_win:     .long 0x00010000
