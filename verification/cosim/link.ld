/* Co-sim linker script: code in ROM at 0x0 (the platform's dedicated instruction
 * port serves only the ROM range; i-fetch outside it faults), data/stack in RAM at
 * 0x80000000. Matches the directed-test / real-platform memory model. */
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 2M
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
  } > ROM

  .rodata : { *(.rodata*) } > ROM

  .data : {
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
