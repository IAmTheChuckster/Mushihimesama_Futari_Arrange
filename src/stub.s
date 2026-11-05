! ROM stub, linked at 0x801F8000 (free tail of u4). The u4 header entry (file offset 0x1C4) points here.
! Copies the patch blob to RAM and jumps to it.
        .section .text
        .align 2
        .global romstub
romstub:
        mov.l   L_src,r1
        mov.l   L_dst,r2
        mov.l   L_cnt,r3
1:      mov.l   @r1+,r0
        mov.l   r0,@r2
        add     #4,r2
        dt      r3
        bf      1b
        mov.l   L_go,r0
        jmp     @r0
        nop
        .align 2
L_src:  .long   blob
L_dst:  .long   0xAC7C0000
L_cnt:  .long   BLOBLEN/4
L_go:   .long   0x0C7C0000
blob:
