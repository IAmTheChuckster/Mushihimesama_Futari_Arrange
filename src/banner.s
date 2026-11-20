! ARRANGE banner: in ARRANGE MODE the "God Mode" banner under the score shows アレンジモード instead.
! The picture (16 x 64, ARGB1555, sideways like all VRAM art) is not in this source: the patchers cut the
! アレンジモード label from the user's own Xbox 360 GOD package, colour it like "God Mode" (red text, dark brown
! drop shadow) and put it in the u4 at natural offset 0x1FF000 (CPU 0xA01FF000): magic 'ARG2', 12 zero
! bytes, 1024 big-endian words. Without a GOD package that area stays 0xFF and nothing changes.
!
! end_wrap: the frame renderer (0x0C05C3EC) runs the queued draw handlers and then closes the blitter list by
! calling 0x0C0512E4 (append one long) with 0xFFFFFFFF through the literal at 0x0C05C45C; that call comes here,
! so every list the blitter gets is handled, slowdown frames included (a draw-queue hook missed some of them and
! the banner flashed between God Mode and アレンジモード). In ARRANGE MODE it walks back from the write pointer
! (@0x0C05100C) to the list start (@0x0C051000) and points the two draws of the God Mode
! label (VRAM source 0x1538,0x160 and 0x1540,0x160, each 8x64) at the unused "Ultra Mode" label of the same
! sheet (0x1548,0x107 and 0x1550,0x107; Black Label has no Ultra Mode), and appends an upload of the picture to
! that spot every frame (0x2000 op: 16 header bytes, then w*h words), so it is there before the banner first shows. Draw records: header (top nibble 1), src x<<16|y, dest, (w-1)<<16|(h-1), tint.
        .align 2
end_wrap:
        mov.l   r4,@-r15
        mov.l   r8,@-r15
        mov.l   B_mode,r1
        mov.l   @r1,r0
        tst     r0,r0
        bt      9f                  ! ORIGINAL ARCADE: list closed untouched
        mov.l   B_glyph,r1
        mov.l   @r1,r0
        mov.l   B_magic,r2
        cmp/eq  r2,r0
        bf      9f                  ! no picture in the u4
        mov.l   B_wp,r0
        mov.l   @r0,r1              ! r1 = write pointer
        mov.l   B_start,r0
        mov.l   @r0,r2              ! r2 = list start
        mov.l   B_win,r3
        mov     r1,r0
        sub     r3,r0               ! r0 = wp - 0x8000
        cmp/hs  r1,r2               ! start >= wp: not this list
        bt      1f
        cmp/hs  r0,r2               ! start >= wp - 0x8000: use it
        bt      2f
1:      mov     r0,r2               ! otherwise scan the last 32 KB only
2:      add     #4,r2               ! a record needs its header word before the source word
        mov.l   B_t1,r3
        mov.l   B_t2,r4
        mov.l   B_sz,r5
        mov.l   B_delta,r8
        mov     r1,r6               ! r6 = p
        mov     #0,r7               ! r7 = draws changed
3:      add     #-4,r6
        cmp/hs  r2,r6
        bf      6f                  ! reached the start
        mov.l   @r6,r0
        cmp/eq  r3,r0
        bt      4f
        cmp/eq  r4,r0
        bf      3b
4:      mov.l   @(8,r6),r0          ! size 8x64?
        cmp/eq  r5,r0
        bf      3b
        mov     r6,r0               ! header is a draw (top nibble 1)?
        add     #-4,r0
        mov.l   @r0,r0
        shlr16  r0
        shlr8   r0
        shlr2   r0
        shlr2   r0
        cmp/eq  #1,r0
        bf      3b
        mov.l   @r6,r0
        add     r8,r0               ! 0x1538,0x160 -> 0x1548,0x107 (same step for 0x1540 -> 0x1550)
        mov.l   r0,@r6
        add     #1,r7
        mov     r7,r0
        cmp/eq  #2,r0
        bf      3b                  ! both halves found: stop scanning (the scan runs at the end of every frame)
6:      mova    B_hdr,r0            ! upload every frame (also before the banner first shows: the blitter
                                    ! applies an upload a few frames late, which showed Ultra Mode briefly)            ! append the upload: header, then the 1024 pixels from the u4
        mov.l   @r0,r3
        mov.l   r3,@r1
        mov.l   @(4,r0),r3
        mov.l   r3,@(4,r1)
        mov.l   @(8,r0),r3
        mov.l   r3,@(8,r1)
        mov.l   @(12,r0),r3
        mov.l   r3,@(12,r1)
        add     #16,r1
        mov.l   B_glyph,r3
        add     #16,r3
        mov.w   B_n,r0              ! 512 longs = 16 x 64 pixels
7:      mov.l   @r3+,r4
        mov.l   r4,@r1
        dt      r0
        bf/s    7b
        add     #4,r1
        mov.l   B_wp,r0
        mov.l   r1,@r0
9:      mov.l   @r15+,r8
        mov.l   @r15+,r4            ! 0xFFFFFFFF: close the list as the game does
        mov.l   B_emit,r0
        jmp     @r0
        nop
        .align 2
B_hdr:   .long  0x20000000, 0x99999999
         .word  0x1548, 0x107, 15, 63   ! upload: dst x, y, w-1, h-1
B_n:     .word  512
        .align 2
B_glyph: .long  0xA01FF000
B_mode:  .long  0x0C7BFF00
B_emit:  .long  0x0C0512E4
B_magic: .long  0x41524732          ! 'ARG2'
B_wp:    .long  0x0C05100C
B_start: .long  0x0C051000
B_win:   .long  0x00008000
B_t1:    .long  0x15380160          ! God Mode label, left 8 columns
B_t2:    .long  0x15400160          ! right 8 columns
B_sz:    .long  0x0007003F
B_delta: .long  0x000FFFA7          ! +0x10 in x, -0x59 in y
