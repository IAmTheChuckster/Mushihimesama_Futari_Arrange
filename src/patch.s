! Futari Arrange patch blob, linked at 0x0C7C0000 (RAM, uncached alias 0xAC7C0000 used for the copy).
! patcher: clears the variables, installs the title-menu hook in the unpacked program, runs the game.
        .section .text
        .align 2
        .global patcher
patcher:
        mov.l   P_vars,r1
        mov     #0,r0
        mov.l   r0,@r1             ! mode = ARCADE
        mov.l   r0,@(4,r1)         ! previous input
        mov.l   P_hook,r1
        mov.w   P_op,r0        ! mov.l @(3,PC),r0
        mov.w   r0,@r1             ! 0x0C092128: PRESS-line call now loads our routine
        mov.l   P_lit,r1
        mov.l   P_menu,r0
        mov.l   r0,@r1             ! literal at 0x0C092138 -> menu
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
        .align 2
        .include "menu.s"
        .align 2
blob_end:
