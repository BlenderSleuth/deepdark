.section .text.boot,"ax"

.global _start
_start:
    li %r3, 0x4242
    b .