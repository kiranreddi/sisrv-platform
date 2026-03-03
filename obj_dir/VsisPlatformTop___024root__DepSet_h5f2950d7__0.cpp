// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VsisPlatformTop.h for the primary calling header

#include "VsisPlatformTop__pch.h"
#include "VsisPlatformTop___024root.h"

void VsisPlatformTop___024root___eval_act(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_act\n"); );
}

VL_INLINE_OPT void VsisPlatformTop___024root___nba_sequent__TOP__0(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*2:0*/ __Vdly__sisPlatformTop__DOT__u_core__DOT__state;
    __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 0;
    IData/*31:0*/ __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus;
    __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus = 0;
    SData/*15:0*/ __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v0;
    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0;
    CData/*4:0*/ __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v0;
    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0;
    CData/*7:0*/ __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v0;
    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0;
    CData/*0:0*/ __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v0;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0;
    SData/*15:0*/ __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v1;
    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 0;
    CData/*4:0*/ __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v1;
    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 0;
    CData/*7:0*/ __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v1;
    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 0;
    CData/*0:0*/ __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v1;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 0;
    SData/*15:0*/ __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v2;
    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0;
    CData/*4:0*/ __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v2;
    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0;
    CData/*7:0*/ __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v2;
    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0;
    CData/*0:0*/ __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v2;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0;
    SData/*15:0*/ __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v3;
    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0;
    CData/*4:0*/ __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v3;
    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0;
    CData/*7:0*/ __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v3;
    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0;
    CData/*0:0*/ __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v3;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0;
    // Body
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0U;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 0U;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0U;
    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0U;
    __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus;
    __Vdly__sisPlatformTop__DOT__u_core__DOT__state 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__state;
    vlSelf->__Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg;
    if (vlSelf->rst_n) {
        if (((IData)(vlSelf->sisPlatformTop__DOT__ram_req_valid) 
             & (IData)(vlSelf->sisPlatformTop__DOT__ram_req_ready))) {
            if (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we) {
                if ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb))) {
                    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v0 
                        = (0xffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata);
                    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 1U;
                    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v0 = 0U;
                    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v0 
                        = (0xffffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                      >> 2U));
                }
                if ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb))) {
                    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v1 
                        = (0xffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                                    >> 8U));
                    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 1U;
                    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v1 = 8U;
                    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v1 
                        = (0xffffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                      >> 2U));
                }
                if ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb))) {
                    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v2 
                        = (0xffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                                    >> 0x10U));
                    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 1U;
                    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v2 = 0x10U;
                    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v2 
                        = (0xffffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                      >> 2U));
                }
                if ((8U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb))) {
                    __Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v3 
                        = (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                           >> 0x18U);
                    __Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 1U;
                    __Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v3 = 0x18U;
                    __Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v3 
                        = (0xffffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                      >> 2U));
                }
            }
            vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending = 1U;
            vlSelf->sisPlatformTop__DOT__u_ram__DOT__rdata_reg 
                = vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem
                [(0xffffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                             >> 2U))];
        } else if (((IData)(vlSelf->sisPlatformTop__DOT__ram_rsp_valid) 
                    & (IData)(vlSelf->sisPlatformTop__DOT__ram_rsp_ready))) {
            vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending = 0U;
        }
        if ((((IData)(vlSelf->sisPlatformTop__DOT__rom_req_valid) 
              & (IData)(vlSelf->sisPlatformTop__DOT__rom_req_ready)) 
             & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we)))) {
            vlSelf->sisPlatformTop__DOT__u_rom__DOT__rdata_reg 
                = vlSelf->sisPlatformTop__DOT__u_rom__DOT__mem
                [(0x3fffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                             >> 2U))];
            vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending = 1U;
        } else if (((IData)(vlSelf->sisPlatformTop__DOT__rom_rsp_valid) 
                    & (IData)(vlSelf->sisPlatformTop__DOT__rom_rsp_ready))) {
            vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending = 0U;
        }
        if (((IData)(vlSelf->sisPlatformTop__DOT__mmio_req_valid) 
             & (IData)(vlSelf->sisPlatformTop__DOT__mmio_req_ready))) {
            vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending = 1U;
            if (((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we) 
                 & (0x10000000U == vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr))) {
                if ((0U == vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata)) {
                    vlSelf->tohost_fail = 1U;
                }
                if ((1U == vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata)) {
                    vlSelf->tohost_pass = 1U;
                }
                vlSelf->tohost_code = vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata;
            }
        } else if (((IData)(vlSelf->sisPlatformTop__DOT__mmio_rsp_valid) 
                    & (IData)(vlSelf->sisPlatformTop__DOT__mmio_rsp_ready))) {
            vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending = 0U;
        }
        if ((((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid) 
              & (IData)(vlSelf->sisPlatformTop__DOT__core_req_ready)) 
             & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending)))) {
            vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending = 1U;
            vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave 
                = ((0U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                           >> 0x10U)) ? 0U : ((0x2000U 
                                               == (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                   >> 0x12U))
                                               ? 1U
                                               : ((0x1000U 
                                                   == 
                                                   (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                    >> 0x10U))
                                                   ? 2U
                                                   : 3U)));
        } else if (((IData)(vlSelf->sisPlatformTop__DOT__core_rsp_valid) 
                    & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready))) {
            vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending = 0U;
        }
        if ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
            if ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
                if ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
                    __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 0U;
                } else {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__pc 
                        = ((0x6fU == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode))
                            ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__pc 
                               + vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_j)
                            : ((0x67U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode))
                                ? (0xfffffffeU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                                                  + vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i))
                                : (((0x63U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode)) 
                                    & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__branch_taken))
                                    ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__pc 
                                       + vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_b)
                                    : (((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall) 
                                        | (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak))
                                        ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec
                                        : ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret)
                                            ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc
                                            : ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal)
                                                ? ((IData)(4U) 
                                                   + vlSelf->sisPlatformTop__DOT__u_core__DOT__pc)
                                                : vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec))))));
                    __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 0U;
                }
            } else if ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
                if (vlSelf->sisPlatformTop__DOT__core_rsp_valid) {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                        = vlSelf->sisPlatformTop__DOT__core_rsp_rdata;
                    __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 6U;
                }
            } else if (vlSelf->sisPlatformTop__DOT__core_req_ready) {
                __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 5U;
            }
        } else if ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
            if ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result;
                __Vdly__sisPlatformTop__DOT__u_core__DOT__state 
                    = (((3U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode)) 
                        | (0x23U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode)))
                        ? 4U : 6U);
            } else {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs1_data;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs2_data;
                __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 3U;
            }
        } else if ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
            if (vlSelf->sisPlatformTop__DOT__core_rsp_valid) {
                vlSelf->__Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg 
                    = vlSelf->sisPlatformTop__DOT__core_rsp_rdata;
                __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 2U;
            }
        } else if (vlSelf->sisPlatformTop__DOT__core_req_ready) {
            __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 1U;
        }
        if (vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter) {
            __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
                = ((0xffffff00U & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus) 
                   | ((0x80U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
                                << 4U)) | (0x77U & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus)));
            vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_val;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc;
        } else {
            if (vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec) {
                __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
                    = (0x80U | ((0xffffff00U & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus) 
                                | ((0x70U & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus) 
                                   | ((8U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
                                             >> 4U)) 
                                      | (7U & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus)))));
            } else if (vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w) {
                if ((0x300U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                >> 0x14U))) {
                    __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                }
            }
            if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec)))) {
                if (vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w) {
                    if ((0x300U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                    >> 0x14U))) {
                        if ((0x304U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                        >> 0x14U))) {
                            if ((0x305U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                            >> 0x14U))) {
                                if ((0x340U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                >> 0x14U))) {
                                    if ((0x341U != 
                                         (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0x14U))) {
                                        if ((0x342U 
                                             == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                 >> 0x14U))) {
                                            vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause 
                                                = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                                        }
                                        if ((0x342U 
                                             != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                 >> 0x14U))) {
                                            if ((0x343U 
                                                 == 
                                                 (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                  >> 0x14U))) {
                                                vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval 
                                                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                                            }
                                        }
                                    }
                                    if ((0x341U == 
                                         (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0x14U))) {
                                        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc 
                                            = (0xfffffffcU 
                                               & vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter)))) {
            if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec)))) {
                if (vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w) {
                    if ((0x300U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                    >> 0x14U))) {
                        if ((0x304U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                        >> 0x14U))) {
                            if ((0x305U != (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                            >> 0x14U))) {
                                if ((0x340U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                >> 0x14U))) {
                                    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch 
                                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                                }
                            }
                            if ((0x305U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                            >> 0x14U))) {
                                vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec 
                                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                            }
                        }
                        if ((0x304U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                        >> 0x14U))) {
                            vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie 
                                = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
                        }
                    }
                }
            }
        }
    } else {
        __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus = 0U;
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending = 0U;
        vlSelf->sisPlatformTop__DOT__u_rom__DOT__rdata_reg = 0U;
        vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending = 0U;
        vlSelf->tohost_fail = 0U;
        vlSelf->tohost_pass = 0U;
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__rdata_reg = 0U;
        vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending = 0U;
        vlSelf->tohost_code = 0U;
        vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave = 0U;
        vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__pc = 0U;
        __Vdly__sisPlatformTop__DOT__u_core__DOT__state = 0U;
        vlSelf->__Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg = 0x13U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc = 0U;
    }
    if ((1U & (~ (IData)(vlSelf->rst_n)))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mip = 0U;
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus 
        = __Vdly__sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus;
    if (__Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v0) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v0] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v0))) 
                & vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem
                [__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v0]) 
               | (0xffffffffULL & ((IData)(__Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v0) 
                                   << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v0))));
    }
    if (__Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v1) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v1] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v1))) 
                & vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem
                [__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v1]) 
               | (0xffffffffULL & ((IData)(__Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v1) 
                                   << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v1))));
    }
    if (__Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v2) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v2] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v2))) 
                & vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem
                [__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v2]) 
               | (0xffffffffULL & ((IData)(__Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v2) 
                                   << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v2))));
    }
    if (__Vdlyvset__sisPlatformTop__DOT__u_ram__DOT__mem__v3) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v3] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v3))) 
                & vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem
                [__Vdlyvdim0__sisPlatformTop__DOT__u_ram__DOT__mem__v3]) 
               | (0xffffffffULL & ((IData)(__Vdlyvval__sisPlatformTop__DOT__u_ram__DOT__mem__v3) 
                                   << (IData)(__Vdlyvlsb__sisPlatformTop__DOT__u_ram__DOT__mem__v3))));
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__state 
        = __Vdly__sisPlatformTop__DOT__u_core__DOT__state;
    vlSelf->sisPlatformTop__DOT__ram_rsp_valid = vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending;
    vlSelf->sisPlatformTop__DOT__mmio_rsp_valid = vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending;
    vlSelf->sisPlatformTop__DOT__rom_rsp_valid = vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending;
    if ((0U == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave))) {
        vlSelf->sisPlatformTop__DOT__core_rsp_rdata 
            = vlSelf->sisPlatformTop__DOT__u_rom__DOT__rdata_reg;
        vlSelf->sisPlatformTop__DOT__core_rsp_valid 
            = vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending;
    } else if ((1U == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave))) {
        vlSelf->sisPlatformTop__DOT__core_rsp_rdata 
            = vlSelf->sisPlatformTop__DOT__u_ram__DOT__rdata_reg;
        vlSelf->sisPlatformTop__DOT__core_rsp_valid 
            = vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending;
    } else if ((2U == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave))) {
        vlSelf->sisPlatformTop__DOT__core_rsp_rdata 
            = vlSelf->tohost_code;
        vlSelf->sisPlatformTop__DOT__core_rsp_valid 
            = vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending;
    } else {
        vlSelf->sisPlatformTop__DOT__core_rsp_rdata = 0xdeadbeefU;
        vlSelf->sisPlatformTop__DOT__core_rsp_valid 
            = vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending;
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready = 0U;
    if ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
        if ((1U & (~ ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state) 
                      >> 1U)))) {
            if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state)))) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 1U;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
            }
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready 
                = (1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state));
        }
    } else if ((1U & (~ ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state) 
                         >> 1U)))) {
        if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
        }
        vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready 
            = (1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state));
    }
    vlSelf->sisPlatformTop__DOT__rom_req_valid = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid) 
                                                  & (0U 
                                                     == 
                                                     (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                      >> 0x10U)));
    vlSelf->sisPlatformTop__DOT__ram_req_valid = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid) 
                                                  & (0x2000U 
                                                     == 
                                                     (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                      >> 0x12U)));
    vlSelf->sisPlatformTop__DOT__mmio_req_valid = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid) 
                                                   & (0x1000U 
                                                      == 
                                                      (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                       >> 0x10U)));
    vlSelf->sisPlatformTop__DOT__rom_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                  & (0U 
                                                     == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
    vlSelf->sisPlatformTop__DOT__ram_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                  & (1U 
                                                     == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
    vlSelf->sisPlatformTop__DOT__mmio_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                   & (2U 
                                                      == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
    vlSelf->sisPlatformTop__DOT__rom_req_ready = (1U 
                                                  & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending)) 
                                                     | (IData)(vlSelf->sisPlatformTop__DOT__rom_rsp_ready)));
    vlSelf->sisPlatformTop__DOT__ram_req_ready = (1U 
                                                  & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending)) 
                                                     | (IData)(vlSelf->sisPlatformTop__DOT__ram_rsp_ready)));
    vlSelf->sisPlatformTop__DOT__mmio_req_ready = (1U 
                                                   & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending)) 
                                                      | (IData)(vlSelf->sisPlatformTop__DOT__mmio_rsp_ready)));
    vlSelf->sisPlatformTop__DOT__core_req_ready = (
                                                   (0U 
                                                    == 
                                                    (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                     >> 0x10U))
                                                    ? (IData)(vlSelf->sisPlatformTop__DOT__rom_req_ready)
                                                    : 
                                                   ((0x2000U 
                                                     == 
                                                     (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                      >> 0x12U))
                                                     ? (IData)(vlSelf->sisPlatformTop__DOT__ram_req_ready)
                                                     : 
                                                    ((0x1000U 
                                                      != 
                                                      (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                                       >> 0x10U)) 
                                                     | (IData)(vlSelf->sisPlatformTop__DOT__mmio_req_ready))));
}

VL_INLINE_OPT void VsisPlatformTop___024root___nba_sequent__TOP__1(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___nba_sequent__TOP__1\n"); );
    // Init
    CData/*4:0*/ __Vdlyvdim0__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0;
    __Vdlyvdim0__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 = 0;
    IData/*31:0*/ __Vdlyvval__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0;
    __Vdlyvval__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 = 0;
    CData/*0:0*/ __Vdlyvset__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0;
    __Vdlyvset__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 = 0;
    // Body
    __Vdlyvset__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 = 0U;
    if (((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en) 
         & (0U != (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                            >> 7U))))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT____Vlvbound_h41f78afe__0 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data;
        if ((0x1eU >= (0x1fU & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                 >> 7U) - (IData)(1U))))) {
            __Vdlyvval__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT____Vlvbound_h41f78afe__0;
            __Vdlyvset__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 = 1U;
            __Vdlyvdim0__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0 
                = (0x1fU & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 7U) - (IData)(1U)));
        }
    }
    if (__Vdlyvset__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[__Vdlyvdim0__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0] 
            = __Vdlyvval__sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs__v0;
    }
}

extern const VlUnpacked<CData/*1:0*/, 8> VsisPlatformTop__ConstPool__TABLE_h61de470f_0;

VL_INLINE_OPT void VsisPlatformTop___024root___nba_sequent__TOP__2(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___nba_sequent__TOP__2\n"); );
    // Init
    CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0;
    sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0 = 0;
    CData/*2:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
        = vlSelf->__Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_j 
        = (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                        >> 0x1fU))) << 0x15U) | ((0x100000U 
                                                  & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                     >> 0xbU)) 
                                                 | ((0xff000U 
                                                     & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg) 
                                                    | ((0x800U 
                                                        & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                           >> 9U)) 
                                                       | (0x7feU 
                                                          & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                             >> 0x14U))))));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_b 
        = (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                        >> 0x1fU))) << 0xdU) | ((0x1000U 
                                                 & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                    >> 0x13U)) 
                                                | ((0x800U 
                                                    & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                       << 4U)) 
                                                   | ((0x7e0U 
                                                       & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                          >> 0x14U)) 
                                                      | (0x1eU 
                                                         & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                            >> 7U))))));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode 
        = (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__branch_taken = 0U;
    if ((0x63U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__branch_taken 
            = ((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                ? ((0x2000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                    ? ((0x1000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                           >= vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val)
                        : (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                           < vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val))
                    : ((0x1000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                        ? VL_GTES_III(32, vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val, vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val)
                        : VL_LTS_III(32, vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val, vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val)))
                : ((1U & (~ (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 0xdU))) && ((0x1000U 
                                             & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                                             ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                                                != vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val)
                                             : (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val 
                                                == vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val))));
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 0U;
    if ((0U == (3U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                      >> 0xcU)))) {
        if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg)) {
            if ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg)) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                    = (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val 
                       << 0x18U);
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 8U;
            } else {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                    = (0xff0000U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val 
                                    << 0x10U));
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 4U;
            }
        } else if ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg)) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                = (0xff00U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val 
                              << 8U));
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 2U;
        } else {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                = (0xffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val);
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 1U;
        }
    } else if ((1U == (3U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 0xcU)))) {
        if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg)) {
            if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg)) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                    = (vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val 
                       << 0x10U);
                vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 0xcU;
            }
        } else {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
                = (0xffffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val);
            vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 3U;
        }
    } else if ((2U == (3U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 0xcU)))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = 0xfU;
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val;
    __Vtableidx1 = (7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                          >> 0xcU));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type 
        = VsisPlatformTop__ConstPool__TABLE_h61de470f_0
        [__Vtableidx1];
    vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result = 0U;
    if ((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) {
        if ((0x2000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg;
        } else if ((0x1000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) {
            if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)) {
                if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)) {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                        = (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                           >> 0x10U);
                }
            } else {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                    = (0xffffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg);
            }
        } else {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                = ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                    ? ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                           >> 0x18U) : (0xffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                                 >> 0x10U)))
                    : ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                        ? (0xffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                    >> 8U)) : (0xffU 
                                               & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg)));
        }
    } else if ((0x2000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg;
    } else if ((0x1000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) {
        if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)) {
            if ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                    = (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                    >> 0x1fU))) << 0x10U) 
                       | (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                          >> 0x10U));
            }
        } else {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
                = (((- (IData)((1U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                      >> 0xfU)))) << 0x10U) 
                   | (0xffffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg));
        }
    } else {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result 
            = ((2U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                ? ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                    ? (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                    >> 0x1fU))) << 8U) 
                       | (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                          >> 0x18U)) : (((- (IData)(
                                                    (1U 
                                                     & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                                        >> 0x17U)))) 
                                         << 8U) | (0xffU 
                                                   & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                                      >> 0x10U))))
                : ((1U & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg)
                    ? (((- (IData)((1U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                          >> 0xfU)))) 
                        << 8U) | (0xffU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                           >> 8U)))
                    : (((- (IData)((1U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg 
                                          >> 7U)))) 
                        << 8U) | (0xffU & vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg))));
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i 
        = (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                        >> 0x1fU))) << 0xcU) | (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                >> 0x14U));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w 
        = (((((((((0x300U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                              >> 0x14U)) | (0x304U 
                                            == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                >> 0x14U))) 
                 | (0x305U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                               >> 0x14U))) | (0x340U 
                                              == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                  >> 0x14U))) 
               | (0x341U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 0x14U))) | (0x342U 
                                            == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                >> 0x14U))) 
             | (0x343U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                           >> 0x14U))) | (0x344U == 
                                          (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                           >> 0x14U)))
            ? ((0x300U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                           >> 0x14U)) ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus
                : ((0x304U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                               >> 0x14U)) ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie
                    : ((0x305U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                   >> 0x14U)) ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec
                        : ((0x340U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                       >> 0x14U)) ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch
                            : ((0x341U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                           >> 0x14U))
                                ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc
                                : ((0x342U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                               >> 0x14U))
                                    ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause
                                    : ((0x343U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                   >> 0x14U))
                                        ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval
                                        : vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mip)))))))
            : 0U);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal 
        = ((0x37U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
           | ((0x17U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
              | ((0x6fU == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                 | ((0x67U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                    | ((0x63U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                       | ((3U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                          | ((0x23U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                             | ((0x13U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                                | ((0x33U == (0x7fU 
                                              & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                                   | ((0x73U == (0x7fU 
                                                 & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                                      | (0xfU == (0x7fU 
                                                  & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))))))))))));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op 
        = ((0x73U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
           & (0U != (7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                           >> 0xcU))));
    sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0 
        = (IData)((0x73U == (0x707fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = 0U;
    if ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
        if ((1U & (~ ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state) 
                      >> 1U)))) {
            if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state)))) {
                if ((0x23U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 1U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb;
                } else {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 0U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = 0U;
                }
            }
        }
    } else if ((1U & (~ ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state) 
                         >> 1U)))) {
        if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 0U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = 0U;
        }
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val;
    if ((0x33U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op 
            = ((8U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                      >> 0x1bU)) | (7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0xcU)));
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val;
    } else if ((0x13U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op 
            = ((5U == (7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                             >> 0xcU))) ? ((8U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                  >> 0x1bU)) 
                                           | (7U & 
                                              (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                               >> 0xcU)))
                : (7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                         >> 0xcU)));
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i;
    } else if (((3U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                | (0x23U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = ((0x23U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))
                ? (((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                >> 0x1fU))) << 0xcU) 
                   | ((0xfe0U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                 >> 0x14U)) | (0x1fU 
                                               & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                  >> 7U))))
                : vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i);
    } else if ((0x63U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 8U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val;
    } else if ((0x37U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = (0xfffff000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg);
    } else if ((0x17U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b 
            = (0xfffff000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg);
    } else if (((0x6fU == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                | (0x67U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = 0U;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
            = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
        vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b = 4U;
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val 
        = ((1U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type))
            ? ((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                ? (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                            >> 0xfU)) : vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val)
            : ((2U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type))
                ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w 
                   | ((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                       ? (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                   >> 0xfU)) : vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val))
                : ((3U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type))
                    ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w 
                       & (~ ((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                              ? (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0xfU))
                              : vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val)))
                    : vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w)));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall 
        = ((IData)(sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0) 
           & (0U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                     >> 0x14U)));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak 
        = ((IData)(sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0) 
           & (1U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                     >> 0x14U)));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret 
        = ((IData)(sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0) 
           & (0x302U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                         >> 0x14U)));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result 
        = ((8U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
            ? ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                ? ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                    ? 0U : ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                             ? VL_SHIFTRS_III(32,32,5, vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a, 
                                              (0x1fU 
                                               & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))
                             : 0U)) : ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                                        ? 0U : ((1U 
                                                 & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                                                 ? 0U
                                                 : 
                                                (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                                                 - vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))))
            : ((4U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                ? ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                    ? ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b)
                        : (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           | vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))
                    : ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           >> (0x1fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))
                        : (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           ^ vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b)))
                : ((2U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                    ? ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           < vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b)
                        : VL_LTS_III(32, vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a, vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))
                    : ((1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op))
                        ? (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           << (0x1fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b))
                        : (vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a 
                           + vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b)))));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_val = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc 
        = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
    if ((6U == (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state))) {
        if (vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w = 1U;
        }
        if (((0x33U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
             | (0x13U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
        } else if (((0x37U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                    | (0x17U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
        } else if (((0x6fU == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)) 
                    | (0x67U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
        } else if ((3U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result;
        } else if (vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w;
        }
        if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op)))) {
            if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall)))) {
                if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak)))) {
                    if (vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret) {
                        vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec = 1U;
                    }
                    if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret)))) {
                        if (((~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal)) 
                             & (0xfU != (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
                            vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_val 
                                = vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg;
                        }
                    }
                }
            }
            if (vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter = 1U;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause = 0xbU;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
            } else if (vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak) {
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter = 1U;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause = 3U;
                vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc 
                    = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
            } else if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret)))) {
                if (((~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal)) 
                     & (0xfU != (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)))) {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter = 1U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause = 2U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
                }
            }
        }
    }
}

VL_INLINE_OPT void VsisPlatformTop___024root___nba_comb__TOP__0(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___nba_comb__TOP__0\n"); );
    // Body
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs1_data 
        = ((0U == (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                            >> 0xfU))) ? 0U : ((0x1eU 
                                                >= 
                                                (0x1fU 
                                                 & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                     >> 0xfU) 
                                                    - (IData)(1U))))
                                                ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs
                                               [(0x1fU 
                                                 & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                     >> 0xfU) 
                                                    - (IData)(1U)))]
                                                : 0U));
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs2_data 
        = ((0U == (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                            >> 0x14U))) ? 0U : ((0x1eU 
                                                 >= 
                                                 (0x1fU 
                                                  & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                      >> 0x14U) 
                                                     - (IData)(1U))))
                                                 ? 
                                                vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs
                                                [(0x1fU 
                                                  & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                      >> 0x14U) 
                                                     - (IData)(1U)))]
                                                 : 0U));
}

void VsisPlatformTop___024root___eval_nba(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VsisPlatformTop___024root___nba_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VsisPlatformTop___024root___nba_sequent__TOP__1(vlSelf);
        vlSelf->__Vm_traceActivity[2U] = 1U;
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VsisPlatformTop___024root___nba_sequent__TOP__2(vlSelf);
        vlSelf->__Vm_traceActivity[3U] = 1U;
    }
    if ((3ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VsisPlatformTop___024root___nba_comb__TOP__0(vlSelf);
    }
}

void VsisPlatformTop___024root___eval_triggers__act(VsisPlatformTop___024root* vlSelf);

bool VsisPlatformTop___024root___eval_phase__act(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    VsisPlatformTop___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        VsisPlatformTop___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool VsisPlatformTop___024root___eval_phase__nba(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        VsisPlatformTop___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__nba(VsisPlatformTop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__act(VsisPlatformTop___024root* vlSelf);
#endif  // VL_DEBUG

void VsisPlatformTop___024root___eval(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            VsisPlatformTop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("rtl/sisPlatformTop.sv", 4, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                VsisPlatformTop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("rtl/sisPlatformTop.sv", 4, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (VsisPlatformTop___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (VsisPlatformTop___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void VsisPlatformTop___024root___eval_debug_assertions(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst_n & 0xfeU))) {
        Verilated::overWidthError("rst_n");}
}
#endif  // VL_DEBUG
