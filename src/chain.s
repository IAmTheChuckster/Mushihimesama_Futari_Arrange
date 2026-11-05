! Chain cancel (ARRANGE MODE only).
! The game's enemy-remove routine 0x0C0764C0(r4 = enemy) is entered through a jump placed at its start.
! In ARRANGE MODE, every live bullet within 24 px of the dying enemy is cancelled into a small gem
! (the game's own per-bullet cancel, as done by 0x0C06E620), and every bullet within 16 px of a
! cancelled bullet is cancelled too, until nothing new is in range.
        .align 2
enemy_kill:
        mov.l   C_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      9f
        mov.l   r8,@-r15
        mov.l   r9,@-r15
        mov.l   r10,@-r15
        mov.l   r11,@-r15
        mov.l   r12,@-r15
        mov.l   r13,@-r15
        mov.l   r4,@-r15
        sts.l   pr,@-r15
        mov.w   C_o900,r0
        mov.l   @(r0,r4),r1      ! enemy actor
        tst     r1,r1
        bt      8f
        mov.l   @(8,r1),r9       ! x (16.16)
        mov.l   @(12,r1),r10     ! y
        mov.l   C_r1,r11
        mov.l   C_qlen,r12
        mov     #0,r0
        mov.l   r0,@r12          ! queue empty
        bsr     scan
        nop
        mov     #0,r13           ! queue index
1:      mov.l   @r12,r0
        cmp/ge  r0,r13
        bt      8f
        mov.l   C_queue,r1
        mov     r13,r0
        shll2   r0
        mov.l   @(r0,r1),r1      ! cancelled bullet
        mov.l   @(20,r1),r9
        mov.l   @(24,r1),r10
        mov.l   C_r2,r11
        bsr     scan
        nop
        bra     1b
        add     #1,r13
8:      lds.l   @r15+,pr
        mov.l   @r15+,r4
        mov.l   @r15+,r13
        mov.l   @r15+,r12
        mov.l   @r15+,r11
        mov.l   @r15+,r10
        mov.l   @r15+,r9
        mov.l   @r15+,r8
9:      mov.l   r14,@-r15        ! replay the 3 overwritten instructions
        mov.l   C_cnt,r0
        mov.l   C_back,r1
        jmp     @r1
        mov.l   @r0,r3

! scan: r9 = x, r10 = y, r11 = radius (16.16), r12 = &queue length. Uses r8, r0-r7.
scan:
        sts.l   pr,@-r15
        mov.l   C_mgr,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      7f
        mov.l   C_list,r1
        add     r1,r0
        mov.l   @r0,r8           ! first bullet
2:      tst     r8,r8
        bt      7f
        mov.b   @(8,r8),r0       ! state
        add     #-1,r0
        extu.b  r0,r0
        mov     #1,r1
        cmp/hi  r1,r0
        bt      6f               ! not a live bullet
        mov.l   @(20,r8),r2
        sub     r9,r2
        cmp/pz  r2
        bt      3f
        neg     r2,r2
3:      cmp/hs  r11,r2
        bt      6f
        mov.l   @(24,r8),r2
        sub     r10,r2
        cmp/pz  r2
        bt      4f
        neg     r2,r2
4:      cmp/hs  r11,r2
        bt      6f
        ! cancel this bullet (same steps as 0x0C06E680)
        mov     r8,r1
        add     #124,r1
        mov.l   @(16,r1),r4
        mov.l   C_free,r0
        jsr     @r0
        nop
        mov.w   @(14,r8),r0
        mov     r0,r7
        mov     #0,r0
        mov.b   r0,@(11,r8)
        mov     r8,r1
        add     #42,r1
        mov.b   r0,@r1           ! gem type 0 = small gem
        mov     #1,r2
        add     #-1,r1
        mov.b   r2,@r1           ! +0x29 = 1
        add     #-1,r1
        mov.b   r2,@r1           ! +0x28 = 1
        mov     r7,r0
        mov.w   r0,@(12,r8)
        mov     r8,r1
        add     #124,r1
        mov     #0,r0
        mov.l   r0,@(16,r1)
        mov.l   r0,@(12,r1)
        mov     #3,r0
        mov.b   r0,@(8,r8)       ! state 3 = cancelling
        mov.l   @r12,r0          ! queue it for the chain
        mov.w   C_qmax,r1
        cmp/ge  r1,r0
        bt      6f
        mov.l   C_queue,r1
        mov     r0,r2
        shll2   r2
        add     r2,r1
        mov.l   r8,@r1
        add     #1,r0
        mov.l   r0,@r12
6:      bra     2b
        mov.l   @r8,r8           ! next
7:      lds.l   @r15+,pr
        rts
        nop
        .align 2
C_o900: .word 0x900
C_qmax: .word 512
        .align 2
C_mode:  .long 0x0C7BFF00
C_qlen:  .long 0x0C7BFF14
C_queue: .long 0x0C7BF000
C_r1:    .long 24<<16
C_r2:    .long 16<<16
C_mgr:   .long 0x0C27DE48
C_list:  .long 0x00048440
C_free:  .long 0x0C0647B0
C_cnt:   .long 0x0C4752FC
C_back:  .long 0x0C0764C6
