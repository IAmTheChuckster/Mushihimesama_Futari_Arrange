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
        mov.l   L_cg,r10
        mov.l   @r10,r0
        mov.l   r0,@-r15        ! save colour
        ITEM    0, 60, L_y0, L_s0
        ITEM    1, 72, L_y1, L_s1
        mov.l   @r15+,r0
        mov.l   r0,@r10         ! restore colour
        mov.l   @r15+,r10
        mov.l   @r15+,r9
        mov.l   @r15+,r8
        lds.l   @r15+,pr
        rts
        nop
        .align 2
L_pri:  .word   250
L_t10:  .word   0xE70A
L_t1:   .word   0xE703
        .align 2
L_vars: .long   0x0C7BFF00
L_meter:.long   0x0C7BFF18
L_tinit:.long   0x0C102560
L_inp:  .long   0x0C05C474
L_cg:   .long   0x0C05CB50
L_T:    .long   0x0C05CBD8
L_yel:  .long   0x80FFFF00      ! yellow (tint word, RGB order)
L_neu:  .long   0x80808080
L_y0:   .long   216
L_y1:   .long   232
L_s0:   .long   str0
L_s1:   .long   str1
L_arrow:.long   str_arrow
L_blank:.long   str_blank
str0:   .asciz  "ORIGINAL ARCADE"
str1:   .asciz  "ARRANGE MODE"
str_arrow: .asciz ">"
str_blank: .asciz " "
        .align 2
