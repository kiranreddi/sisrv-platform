/* Co-sim linker script: load above Spike's low device window at 0x0. */
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00010000, LENGTH = 48K
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
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > RAM

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
