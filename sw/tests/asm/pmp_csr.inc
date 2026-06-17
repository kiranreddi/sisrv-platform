# pmp_csr.inc — RV32 standard PMP CSR packing helpers
#
# pmpcfg0 packs entries 0..3; pmpcfg1 packs entries 4..7.

.macro PMP_SET_CFG entry, cfg, r_tmp, r_mask
  .if \entry < 4
    csrr    \r_tmp, pmpcfg0
    li      \r_mask, 0xff
    slli    \r_mask, \r_mask, (8 * \entry)
    not     \r_mask, \r_mask
    and     \r_tmp, \r_tmp, \r_mask
    li      \r_mask, (\cfg & 0xff)
    slli    \r_mask, \r_mask, (8 * \entry)
    or      \r_tmp, \r_tmp, \r_mask
    csrw    pmpcfg0, \r_tmp
  .else
    csrr    \r_tmp, pmpcfg1
    li      \r_mask, 0xff
    slli    \r_mask, \r_mask, (8 * (\entry - 4))
    not     \r_mask, \r_mask
    and     \r_tmp, \r_tmp, \r_mask
    li      \r_mask, (\cfg & 0xff)
    slli    \r_mask, \r_mask, (8 * (\entry - 4))
    or      \r_tmp, \r_tmp, \r_mask
    csrw    pmpcfg1, \r_tmp
  .endif
.endm

.macro PMP_HARNESS_ENTRY0
    li   t0, 0x1FFF
    csrw pmpaddr0, t0
    li   t0, 0x1F
    csrw pmpcfg0, t0
.endm
