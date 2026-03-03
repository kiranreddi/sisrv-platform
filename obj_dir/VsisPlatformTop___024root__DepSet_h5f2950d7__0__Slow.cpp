// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VsisPlatformTop.h for the primary calling header

#include "VsisPlatformTop__pch.h"
#include "VsisPlatformTop___024root.h"

VL_ATTR_COLD void VsisPlatformTop___024root___eval_static(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_static\n"); );
}

VL_ATTR_COLD void VsisPlatformTop___024root___eval_initial__TOP(VsisPlatformTop___024root* vlSelf);

VL_ATTR_COLD void VsisPlatformTop___024root___eval_initial(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_initial\n"); );
    // Body
    VsisPlatformTop___024root___eval_initial__TOP(vlSelf);
    vlSelf->__Vm_traceActivity[3U] = 1U;
    vlSelf->__Vm_traceActivity[2U] = 1U;
    vlSelf->__Vm_traceActivity[1U] = 1U;
    vlSelf->__Vm_traceActivity[0U] = 1U;
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
    vlSelf->__Vtrigprevexpr___TOP__rst_n__0 = vlSelf->rst_n;
}

VL_ATTR_COLD void VsisPlatformTop___024root___eval_initial__TOP(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_initial__TOP\n"); );
    // Body
    vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i = 0U;
    while (VL_GTS_III(32, 0x4000U, vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i)) {
        vlSelf->sisPlatformTop__DOT__u_rom__DOT__mem[(0x3fffU 
                                                      & vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i)] = 0x13U;
        vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i 
            = ((IData)(1U) + vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i);
    }
    VL_READMEM_N(true, 32, 16384, 0, std::string{"rom.hex"}
                 ,  &(vlSelf->sisPlatformTop__DOT__u_rom__DOT__mem)
                 , 0, ~0ULL);
    vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i = 0U;
    while (VL_GTS_III(32, 0x10000U, vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i)) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[(0xffffU 
                                                      & vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i)] = 0U;
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i 
            = ((IData)(1U) + vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i);
    }
}

VL_ATTR_COLD void VsisPlatformTop___024root___eval_final(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__stl(VsisPlatformTop___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool VsisPlatformTop___024root___eval_phase__stl(VsisPlatformTop___024root* vlSelf);

VL_ATTR_COLD void VsisPlatformTop___024root___eval_settle(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            VsisPlatformTop___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("rtl/sisPlatformTop.sv", 4, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (VsisPlatformTop___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__stl(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

extern const VlUnpacked<CData/*1:0*/, 8> VsisPlatformTop__ConstPool__TABLE_h61de470f_0;

VL_ATTR_COLD void VsisPlatformTop___024root___stl_sequent__TOP__0(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___stl_sequent__TOP__0\n"); );
    // Init
    CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0;
    sisPlatformTop__DOT__u_core__DOT____VdfgTmp_h1f071938__0 = 0;
    CData/*2:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelf->sisPlatformTop__DOT__rom_rsp_valid = vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending;
    vlSelf->sisPlatformTop__DOT__ram_rsp_valid = vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending;
    vlSelf->sisPlatformTop__DOT__mmio_rsp_valid = vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending;
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
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 0U;
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr = 0U;
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
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready = 0U;
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
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 1U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb;
                } else {
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 0U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 1U;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata 
                        = vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data;
                    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = 0U;
                }
            }
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready 
                = (1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state));
        }
    } else if ((1U & (~ ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state) 
                         >> 1U)))) {
        if ((1U & (~ (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state)))) {
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = 0U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = 1U;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                = vlSelf->sisPlatformTop__DOT__u_core__DOT__pc;
            vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = 0U;
        }
        vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready 
            = (1U & (IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__state));
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
    vlSelf->sisPlatformTop__DOT__rom_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                  & (0U 
                                                     == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
    vlSelf->sisPlatformTop__DOT__ram_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                  & (1U 
                                                     == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
    vlSelf->sisPlatformTop__DOT__mmio_rsp_ready = ((IData)(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready) 
                                                   & (2U 
                                                      == (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)));
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
    vlSelf->sisPlatformTop__DOT__rom_req_ready = (1U 
                                                  & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending)) 
                                                     | (IData)(vlSelf->sisPlatformTop__DOT__rom_rsp_ready)));
    vlSelf->sisPlatformTop__DOT__ram_req_ready = (1U 
                                                  & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending)) 
                                                     | (IData)(vlSelf->sisPlatformTop__DOT__ram_rsp_ready)));
    vlSelf->sisPlatformTop__DOT__mmio_req_ready = (1U 
                                                   & ((~ (IData)(vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending)) 
                                                      | (IData)(vlSelf->sisPlatformTop__DOT__mmio_rsp_ready)));
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

VL_ATTR_COLD void VsisPlatformTop___024root___eval_stl(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VsisPlatformTop___024root___stl_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[3U] = 1U;
        vlSelf->__Vm_traceActivity[2U] = 1U;
        vlSelf->__Vm_traceActivity[1U] = 1U;
        vlSelf->__Vm_traceActivity[0U] = 1U;
    }
}

VL_ATTR_COLD void VsisPlatformTop___024root___eval_triggers__stl(VsisPlatformTop___024root* vlSelf);

VL_ATTR_COLD bool VsisPlatformTop___024root___eval_phase__stl(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    VsisPlatformTop___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        VsisPlatformTop___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__act(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk or negedge rst_n)\n");
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__nba(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk or negedge rst_n)\n");
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VsisPlatformTop___024root___ctor_var_reset(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst_n = VL_RAND_RESET_I(1);
    vlSelf->tohost_pass = VL_RAND_RESET_I(1);
    vlSelf->tohost_fail = VL_RAND_RESET_I(1);
    vlSelf->tohost_code = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__core_req_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__core_rsp_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__core_rsp_rdata = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__rom_req_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__rom_req_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__rom_rsp_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__rom_rsp_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__ram_req_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__ram_req_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__ram_rsp_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__ram_rsp_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__mmio_req_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__mmio_req_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__mmio_rsp_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__mmio_rsp_ready = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__state = VL_RAND_RESET_I(3);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__state_next = VL_RAND_RESET_I(3);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__pc = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__pc_next = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_b = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_j = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_opcode = VL_RAND_RESET_I(7);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs1_data = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rs2_data = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op = VL_RAND_RESET_I(4);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_val = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__branch_taken = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type = VL_RAND_RESET_I(2);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb = VL_RAND_RESET_I(4);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb = VL_RAND_RESET_I(4);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 31; ++__Vi0) {
        vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT____Vlvbound_h41f78afe__0 = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mip = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave = VL_RAND_RESET_I(2);
    vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 16384; ++__Vi0) {
        vlSelf->sisPlatformTop__DOT__u_rom__DOT__mem[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_rom__DOT__rdata_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i = 0;
    for (int __Vi0 = 0; __Vi0 < 65536; ++__Vi0) {
        vlSelf->sisPlatformTop__DOT__u_ram__DOT__mem[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending = VL_RAND_RESET_I(1);
    vlSelf->sisPlatformTop__DOT__u_ram__DOT__rdata_reg = VL_RAND_RESET_I(32);
    vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i = 0;
    vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending = VL_RAND_RESET_I(1);
    vlSelf->__Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg = VL_RAND_RESET_I(32);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst_n__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
