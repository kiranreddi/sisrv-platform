/* sisrv RISCOF linker script: code in ROM, data/signature in RAM */
OUTPUT_ARCH(riscv)
ENTRY(rvtest_entry_point)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 2048K
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 2048K
}

SECTIONS
{
  .text.init : {
    *(.text.init)
  } > ROM

  .text : {
    *(.text)
    *(.text.*)
  } > ROM

  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
  } > ROM

  .data : AT(ADDR(.rodata) + SIZEOF(.rodata)) {
    . = ALIGN(16);
    *(.tohost)
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
  } > RAM

  .bss : {
    . = ALIGN(16);
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
