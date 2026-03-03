/* Minimal linker script skeleton (RV32) */
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
  } > ROM

  .rodata : { *(.rodata*) } > ROM

  .data : AT(ADDR(.rodata) + SIZEOF(.rodata)) {
    *(.data*)
  } > RAM

  .bss : {
    *(.bss*)
    *(COMMON)
  } > RAM
}
