ENTRY(_start)

SECTIONS
{
    . = 0x80004000;
    .text : {
        KEEP(*(.text.boot))
        *(.text .text.*)
    }
}
