! Futari Arrange patch blob, linked at 0x0C7C0000 (RAM, uncached alias 0xAC7C0000 used for the copy).
! patcher: clears the variables, installs the title-menu hook in the unpacked program, runs the game.
        .section .text
        .align 2
        .global patcher
patcher:
        mov.l   P_vars,r1
        mov     #0,r0
        mov.l   r0,@r1             ! mode = ORIGINAL
        mov.l   r0,@(4,r1)         ! previous input
        mov.l   P_hook,r1
        mov.w   P_op,r0        ! mov.l @(3,PC),r0
        mov.w   r0,@r1             ! 0x0C092128: PRESS-line call now loads our routine
        mov.l   P_lit,r1
        mov.l   P_menu,r0
        mov.l   r0,@r1             ! literal at 0x0C092138 -> menu
        mov.l   P_blastlit,r1
        mov.l   P_hb,r0
        mov.l   r0,@r1             ! 0x0C06BC80 -> hyper_blast
        mov.l   P_invlit,r1
        mov.l   P_hi,r0
        mov.l   r0,@r1             ! 0x0C06BC88 -> hyper_inv
        mov.l   P_kill,r1
        mov.l   P_kw1,r0
        mov.l   r0,@r1             ! 0x0C0764C0: mov.l @(0x12,PC),r0 / jmp @r0
        mov.w   P_nop,r0
        mov.w   r0,@(4,r1)         ! 0x0C0764C4: nop
        mov.l   P_klit,r1
        mov.l   P_ek,r0
        mov.l   r0,@r1             ! literal at 0x0C07650C -> enemy_kill
        mov.l   P_vars,r1
        mov     #GEMTYPE,r0
        mov.l   r0,@(8,r1)         ! gem type for the cancel
        mov     #0,r0
        mov.l   r0,@(12,r1)
        mov.w   P_inv,r0
        mov.l   r0,@(16,r1)        ! hyper bomb invulnerability (frames)
        mov.l   P_main,r0
        jmp     @r0
        nop
        .align 2
P_vars:     .long 0xAC7BFF00
P_hook: .long 0xAC092128
P_lit:  .long 0xAC092138
P_menu:     .long menu
P_main:     .long 0x0C002A30
P_op:   .word 0xD003
P_inv:      .word INVLEN
P_nop:      .word 0x0009
        .align 2
P_blastlit: .long 0xAC06BC80
P_invlit:   .long 0xAC06BC88
P_hb:       .long hyper_blast
P_hi:       .long hyper_inv
P_kill:     .long 0xAC0764C0
P_kw1:      .long 0xD012402B
P_klit:     .long 0xAC07650C
P_ek:       .long enemy_kill
        .align 2
        .include "menu.s"
        .include "hyper.s"
        .include "chain.s"
        .align 2
blob_end:
