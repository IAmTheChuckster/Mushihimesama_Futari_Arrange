! Hyper Bomb (ARRANGE MODE only).
! The bomb routine (0x0C06BBF0) calls the blast spawner 0x0C10EB90 through the literal at 0x0C06BC80
! and then sets the bomb invulnerability (0x0C068AA0, literal at 0x0C06BC88). The character voice is
! played by the caller afterwards, so it is kept.
! In ARRANGE MODE the blast is replaced by the game's own bullet cancel (0x0C06E620), which turns every
! bullet into gems, and the invulnerability is shortened.
        .align 2
hyper_blast:
        mov.l   H_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bf      1f
        mov.l   H_blast,r0      ! ORIGINAL ARCADE: normal bomb blast (arguments untouched)
        jmp     @r0
        nop
1:      mov     #0,r0
        mov.w   r0,@(12,r4)     ! clear the "bombing" flag (normally cleared when the blast ends)
        sts.l   pr,@-r15
        mov.w   H_cnt,r0
        mov.l   @(r0,r4),r1     ! x counter
        mov.l   H_cap,r2
        mov     #0,r3
        cmp/ge  r2,r1
        bf      4f
        mov     #0,r1           ! cash out at x99999: the multiplier starts again from 0, the gems keep 99999 for a while
        mov.l   r1,@(r0,r4)
        mov.l   H_win,r0
        mov.w   H_winlen,r1
        mov.l   r1,@r0
        mov     #1,r3
4:      mov.l   H_gem,r4
        mov.l   @r4,r4          ! gem type
        tst     r3,r3
        bt      3f
        mov     #3,r4           ! cash out: big (gold) gems
3:
        mov.l   H_gemarg,r5
        mov.l   @r5,r5
        mov.l   H_cancel,r0
        jsr     @r0
        nop
        lds.l   @r15+,pr
        rts
        mov     #1,r0           ! bomb used
        .align 2
hyper_inv:
        mov.l   H_mode,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      2f
        mov.l   H_invlen,r5     ! ARRANGE MODE: short invulnerability
        mov.l   @r5,r5
2:      mov.l   H_setinv,r0
        jmp     @r0
        nop
        .align 2
H_cnt:    .word 168
H_winlen: .word 600
        .align 2
H_cap:    .long 99999
H_win:    .long 0x0C7BFF2C
H_mode:   .long 0x0C7BFF00
H_gem:    .long 0x0C7BFF08
H_gemarg: .long 0x0C7BFF0C
H_invlen: .long 0x0C7BFF10
H_blast:  .long 0x0C10EB90
H_cancel: .long 0x0C06E620
H_setinv: .long 0x0C068AA0

! mode_set: replaces the Mode Select setter 0x0C068520(player, mode) (literal 0x0C10458C).
! ARRANGE MODE always plays God Mode (mode 2).
        .align 2
mode_set:
        mov.l   H_mode2,r0
        mov.l   @r0,r0
        tst     r0,r0
        bt      1f
        mov     #2,r5
1:      mov.l   H_setmode,r0
        jmp     @r0
        nop
        .align 2
H_setmode: .long 0x0C068520
H_mode2:   .long 0x0C7BFF00
