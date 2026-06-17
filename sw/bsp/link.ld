/* Linker script for sisrv-platform bare-metal tests and benchmarks */
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

  .rodata : {
    *(.rodata*)
    *(.srodata*)
    *(.eh_frame*)
  } > ROM

  .data : AT(ALIGN(ADDR(.rodata) + SIZEOF(.rodata), 4)) {
    _data_start = .;
    *(.sdata*)
    *(.data*)
    . = ALIGN(4);
    _data_end = .;
  } > RAM
  _data_lma = LOADADDR(.data);

  .bss : {
    _bss_start = .;
    *(.sbss*)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
