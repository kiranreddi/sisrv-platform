#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_BOOT

#define RVMODEL_DATA_BEGIN \
  .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END \
  .align 4; .global end_signature; end_signature:

/* Signal architectural-test completion to the Verilator harness (tohost=3). */
#define RVMODEL_HALT \
  li t0, 3; \
  li t1, 0x10000000; \
  sw t0, 0(t1); \
  riscof_halt_spin: j riscof_halt_spin;

/* CLINT at 0x0200_0000 — software/timer interrupt hooks for ACT tests. */
#define RVMODEL_SET_MSW_INT \
  li t0, 0x02000000; \
  li t1, 1; \
  sw t1, 0(t0);

#define RVMODEL_CLEAR_MSW_INT \
  li t0, 0x02000000; \
  sw x0, 0(t0);

#define RVMODEL_CLEAR_MTIMER_INT \
  li t0, 0x02004000; \
  li t1, -1; \
  sw t1, 0(t0); \
  sw t1, 4(t0);

#define RVMODEL_CLEAR_MEXT_INT \
  li t0, 0x0C002000; \
  sw x0, 0(t0);

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#endif
