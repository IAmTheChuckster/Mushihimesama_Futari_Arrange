! Title menu (ORIGINAL ARCADE / ARRANGE MODE) for Mushihime-Sama Futari Black Label (futariblj)
! Called every frame instead of the "PRESS 1P OR 2P START" text draw.
! Variables: VARS+0 = mode (0 = ORIGINAL ARCADE, 1 = ARRANGE MODE), VARS+4 = previous input
        .align 2
        .macro ITEM idx, x, ylit, strlit
        mov     #\idx,r0
        cmp/eq  r0,r9
        bf      1f
        mov.l   L_yel,r2
        mov.l   L_arrow,r3
        bra     2f
        nop
1:      mov.l   L_neu,r2
        mov.l   L_blank,r3
2:      mov.l   r2,@r10
        mov     #(\x-14),r4
        mov.l   \ylit,r5
        mov     r3,r7
        mov.w   L_pri,r6
        mov.l   L_T,r0
        jsr     @r0
        nop
        mov     #\x,r4
        mov.l   \ylit,r5
        mov.l   \strlit,r7
        mov.w   L_pri,r6
        mov.l   L_T,r0
        jsr     @r0
        nop
        .endm
menu:
        sts.l   pr,@-r15
        mov.l   r8,@-r15
        mov.l   r9,@-r15
        mov.l   r10,@-r15
        mov.l   L_vars,r8
        mov.l   L_inp,r0
        mov.l   @r0,r1          ! held input (P1)
        mov.l   @(4,r8),r2      ! previous
        mov.l   r1,@(4,r8)
        not     r2,r2
        and     r2,r1           ! newly pressed
        mov.l   @r8,r9          ! mode / selection
        mov     r1,r0
        tst     #1,r0           ! Up
        bt      3f
        mov     #0,r9
3:      tst     #2,r0           ! Down
        bt      4f
        mov     #1,r9
4:      mov.l   r9,@r8
        mov.l   L_tinit,r1       ! Mode Select timer start: "mov #10,r7" at 0x0C102560
        mov.w   L_t10,r0
        tst     r9,r9
        bt      5f
        mov.w   L_t1,r0          ! ARRANGE: 3 seconds, the cursor walks to God by itself
5:      mov.w   r0,@r1
        mov     #0,r0
        mov.l   L_meter,r1
        mov.l   r0,@r1          ! meter reset on the title
        mov.l   L_pend,r1
        mov.l   r0,@r1
        mov.l   L_win,r1
        mov.l   r0,@r1
        mov.l   L_latch,r1
        mov.l   r0,@r1
        mov.l   L_cg,r10
        mov.l   @r10,r0
        mov.l   r0,@-r15        ! save colour
        ITEM    0, 60, L_y0, L_s0
        ITEM    1, 72, L_y1, L_s1
        mov.l   L_red,r0         ! red "NOT FOR SALE" where "SALE BY AMI" was
        mov.l   r0,@r10
        mov     #72,r4
        mov.l   L_y2,r5
        mov.l   L_s2,r7
        mov.w   L_pri,r6
        mov.l   L_T,r0
        jsr     @r0
        nop
        mov     #73,r4
        mov.l   L_y2,r5
        mov.l   L_s2,r7
        mov.w   L_pri,r6
        mov.l   L_T,r0
        jsr     @r0
        nop
        mov.l   @r15+,r0
        mov.l   r0,@r10         ! restore colour
        mov.l   L_filt,r4       ! hide the "SALE BY AMI" glyph sprites in this frame's draw pass
        mov     #0,r5
        mov.w   L_pri2,r6
        mov.l   L_sub,r0
        jsr     @r0
        nop
        mov.l   @r15+,r10
        mov.l   @r15+,r9
        mov.l   @r15+,r8
        lds.l   @r15+,pr
        rts
        nop
        .align 2
L_pri:  .word   250
L_pri2: .word   255
L_t10:  .word   0xE70A
L_t1:   .word   0xE703
        .align 2
L_vars: .long   0x0C7BFF00
L_filt: .long   title_filter
L_sub:  .long   0x0C05C394
L_meter:.long   0x0C7BFF18
L_pend: .long   0x0C7BFF28
L_win:  .long   0x0C7BFF2C
L_latch:.long   0x0C7BFF30
L_tinit:.long   0x0C102560
L_inp:  .long   0x0C05C474
L_cg:   .long   0x0C05CB50
L_T:    .long   0x0C05CBD8
L_yel:  .long   0x80FFFF00      ! yellow (tint word, RGB order)
L_neu:  .long   0x80808080
L_y0:   .long   216
L_y1:   .long   232
L_y2:   .long   285
L_red:  .long   0x80FF2020
L_s2:   .long   str2
L_s0:   .long   str0
L_s1:   .long   str1
L_arrow:.long   str_arrow
L_blank:.long   str_blank
str0:   .asciz  "ORIGINAL ARCADE"
str1:   .asciz  "ARRANGE MODE"
str2:   .asciz  "NOT FOR SALE"
str_arrow: .asciz ">"
str_blank: .asciz " "
        .align 2

! title_text_hook: replaces the text-draw function literal (0x0C092184) of the title screen routine, so every text
! call of that routine goes through here and is forwarded to the game's text function 0x0C05CBD8 unchanged.
! When the call is the "INSERT COIN" line (no credit yet), the title_filter is queued, and once it has seen the
! "SALE BY AMI" glyphs (flag set by title_filter in the previous frame) the red "NOT FOR SALE" is drawn too.
! The game skips the INSERT COIN call on the frames where the line blinks off, which let SALE BY AMI flash back,
! so patch.s makes that call happen every frame (blink test at 0x0C0920B4 masked to 0) and the blink is done here.
        .align 2
title_text_hook:
        mov.l   N_ins,r0
        cmp/eq  r0,r7
        bf      9f
        sts.l   pr,@-r15
        mov.l   r4,@-r15
        mov.l   r5,@-r15
        mov.l   r6,@-r15
        mov.l   r7,@-r15
        mov.l   r10,@-r15
        mov.l   N_nsf,r1
        mov.l   @r1,r0
        tst     r0,r0
        bt      1f
        mov.l   N_cg,r10
        mov.l   @r10,r0
        mov.l   r0,@-r15         ! save colour
        mov.l   N_red,r0
        mov.l   r0,@r10
        mov     #72,r4
        mov.l   N_y2,r5
        mov.l   N_s2,r7
        mov.w   N_pri,r6
        mov.l   N_T,r0
        jsr     @r0
        nop
        mov     #73,r4
        mov.l   N_y2,r5
        mov.l   N_s2,r7
        mov.w   N_pri,r6
        mov.l   N_T,r0
        jsr     @r0
        nop
        mov.l   @r15+,r0
        mov.l   r0,@r10          ! restore colour
1:      mov     #0,r0
        mov.l   N_nsf,r1
        mov.l   r0,@r1
        mov.l   N_filt,r4        ! hide the "SALE BY AMI" glyph sprites in this frame's draw pass
        mov     #0,r5
        mov.w   N_pri2,r6
        mov.l   N_sub,r0
        jsr     @r0
        nop
        mov.l   @r15+,r10
        mov.l   @r15+,r7
        mov.l   @r15+,r6
        mov.l   @r15+,r5
        mov.l   @r15+,r4
        lds.l   @r15+,pr
        mov.l   N_blink,r0       ! the game's INSERT COIN blink bit: set = this frame the line is not shown
        mov.l   @r0,r0
        tst     #16,r0
        bt      9f
        rts                      ! blink off: SALE BY AMI is still hidden, but skip the INSERT COIN text
        nop
9:      mov.l   N_T,r0
        jmp     @r0
        nop
        .align 2
N_pri:  .word   250
N_pri2: .word   255
        .align 2
N_ins:  .long   0x0C1D2D64      ! the "INSERT COIN" string
N_nsf:  .long   0x0C7BFF38      ! "SALE BY AMI was seen last frame" flag
N_cg:   .long   0x0C05CB50
N_red:  .long   0x80FF2020
N_y2:   .long   285
N_s2:   .long   str2
N_T:    .long   0x0C05CBD8
N_filt: .long   title_filter
N_sub:  .long   0x0C05C394
N_blink:.long   0x0C383300      ! bit 4 = INSERT COIN blink (set = hidden this frame)

! title_filter: draw-pass handler. The title screen's "SALE BY AMI" is nine 16x8 font glyph sprites (display list
! record: header, tile, dest, size, tint) at screen y 289 (dest y high half = origin + 0x17, size 0x000F0007).
! Every such sprite already in the display list is moved 64 px down, off the screen.
        .align 2
title_filter:
        mov.l   F_dlp,r0
        mov.l   @r0,r1           ! display list write pointer
        mov.l   F_org,r0
        mov.l   @r0,r2
        shlr16  r2
        add     #0x17,r2         ! dest y high half of the line
        mov.w   F_n,r3           ! words to scan back
        mov.l   F_sz,r5
1:      add     #-4,r1
        mov.l   @(8,r1),r0
        cmp/eq  r5,r0
        bf      2f
        mov.l   @(4,r1),r0
        mov     r0,r6
        shlr16  r6
        cmp/eq  r2,r6
        bf      2f
        mov.l   @r1,r0
        shlr16  r0
        mov.w   F_mask,r6
        and     r6,r0
        mov.w   F_tile,r6
        cmp/eq  r6,r0
        bf      2f
        mov.l   @(4,r1),r0
        mov.l   F_down,r6
        sub     r6,r0
        mov.l   r0,@(4,r1)
        mov.l   F_flag,r6        ! tell title_text_hook that the line was there
        mov     #1,r0
        mov.l   r0,@r6
2:      dt      r3
        bf      1b
        rts
        nop
        .align 2
F_n:    .word   3500
F_mask: .word   0xFFE0
F_tile: .word   0x03C0
        .align 2
F_dlp:  .long   0x0C05100C
F_org:  .long   0x0C051004
F_sz:   .long   0x000F0007
F_down: .long   0x00400000
F_flag: .long   0x0C7BFF38
