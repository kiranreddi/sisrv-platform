// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "VsisPlatformTop__Syms.h"


void VsisPlatformTop___024root__trace_chg_0_sub_0(VsisPlatformTop___024root* vlSelf, VerilatedFst::Buffer* bufp);

void VsisPlatformTop___024root__trace_chg_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root__trace_chg_0\n"); );
    // Init
    VsisPlatformTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VsisPlatformTop___024root*>(voidSelf);
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    VsisPlatformTop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void VsisPlatformTop___024root__trace_chg_0_sub_0(VsisPlatformTop___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[0U])) {
        bufp->chgIData(oldp+0,(vlSelf->sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i),32);
        bufp->chgIData(oldp+1,(vlSelf->sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i),32);
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
        bufp->chgBit(oldp+2,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_valid));
        bufp->chgBit(oldp+3,(vlSelf->sisPlatformTop__DOT__core_req_ready));
        bufp->chgIData(oldp+4,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr),32);
        bufp->chgBit(oldp+5,(vlSelf->sisPlatformTop__DOT__core_rsp_valid));
        bufp->chgBit(oldp+6,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_rsp_ready));
        bufp->chgIData(oldp+7,(vlSelf->sisPlatformTop__DOT__core_rsp_rdata),32);
        bufp->chgBit(oldp+8,(((0U != (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)) 
                              && ((1U != (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave)) 
                                  && (2U != (IData)(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave))))));
        bufp->chgBit(oldp+9,(vlSelf->sisPlatformTop__DOT__rom_req_valid));
        bufp->chgBit(oldp+10,(vlSelf->sisPlatformTop__DOT__rom_req_ready));
        bufp->chgBit(oldp+11,(vlSelf->sisPlatformTop__DOT__u_rom__DOT__pending));
        bufp->chgBit(oldp+12,(vlSelf->sisPlatformTop__DOT__rom_rsp_ready));
        bufp->chgIData(oldp+13,(vlSelf->sisPlatformTop__DOT__u_rom__DOT__rdata_reg),32);
        bufp->chgBit(oldp+14,(vlSelf->sisPlatformTop__DOT__ram_req_valid));
        bufp->chgBit(oldp+15,(vlSelf->sisPlatformTop__DOT__ram_req_ready));
        bufp->chgBit(oldp+16,(vlSelf->sisPlatformTop__DOT__u_ram__DOT__pending));
        bufp->chgBit(oldp+17,(vlSelf->sisPlatformTop__DOT__ram_rsp_ready));
        bufp->chgIData(oldp+18,(vlSelf->sisPlatformTop__DOT__u_ram__DOT__rdata_reg),32);
        bufp->chgBit(oldp+19,(vlSelf->sisPlatformTop__DOT__mmio_req_valid));
        bufp->chgBit(oldp+20,(vlSelf->sisPlatformTop__DOT__mmio_req_ready));
        bufp->chgBit(oldp+21,(vlSelf->sisPlatformTop__DOT__u_tohost__DOT__pending));
        bufp->chgBit(oldp+22,(vlSelf->sisPlatformTop__DOT__mmio_rsp_ready));
        bufp->chgCData(oldp+23,(vlSelf->sisPlatformTop__DOT__u_core__DOT__state),3);
        bufp->chgIData(oldp+24,(vlSelf->sisPlatformTop__DOT__u_core__DOT__pc),32);
        bufp->chgIData(oldp+25,(vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val),32);
        bufp->chgIData(oldp+26,(vlSelf->sisPlatformTop__DOT__u_core__DOT__rs2_val),32);
        bufp->chgIData(oldp+27,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec),32);
        bufp->chgIData(oldp+28,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc),32);
        bufp->chgIData(oldp+29,(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result_reg),32);
        bufp->chgIData(oldp+30,(vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_addr_reg),32);
        bufp->chgIData(oldp+31,(vlSelf->sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg),32);
        bufp->chgIData(oldp+32,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus),32);
        bufp->chgIData(oldp+33,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie),32);
        bufp->chgIData(oldp+34,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch),32);
        bufp->chgIData(oldp+35,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause),32);
        bufp->chgIData(oldp+36,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval),32);
        bufp->chgIData(oldp+37,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mip),32);
        bufp->chgBit(oldp+38,((0U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                      >> 0x10U))));
        bufp->chgBit(oldp+39,((0x2000U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                           >> 0x12U))));
        bufp->chgBit(oldp+40,((0x1000U == (vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_addr 
                                           >> 0x10U))));
        bufp->chgCData(oldp+41,(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__active_slave),2);
        bufp->chgBit(oldp+42,(vlSelf->sisPlatformTop__DOT__u_fabric__DOT__has_pending));
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[2U])) {
        bufp->chgIData(oldp+43,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[0]),32);
        bufp->chgIData(oldp+44,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[1]),32);
        bufp->chgIData(oldp+45,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[2]),32);
        bufp->chgIData(oldp+46,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[3]),32);
        bufp->chgIData(oldp+47,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[4]),32);
        bufp->chgIData(oldp+48,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[5]),32);
        bufp->chgIData(oldp+49,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[6]),32);
        bufp->chgIData(oldp+50,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[7]),32);
        bufp->chgIData(oldp+51,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[8]),32);
        bufp->chgIData(oldp+52,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[9]),32);
        bufp->chgIData(oldp+53,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[10]),32);
        bufp->chgIData(oldp+54,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[11]),32);
        bufp->chgIData(oldp+55,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[12]),32);
        bufp->chgIData(oldp+56,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[13]),32);
        bufp->chgIData(oldp+57,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[14]),32);
        bufp->chgIData(oldp+58,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[15]),32);
        bufp->chgIData(oldp+59,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[16]),32);
        bufp->chgIData(oldp+60,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[17]),32);
        bufp->chgIData(oldp+61,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[18]),32);
        bufp->chgIData(oldp+62,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[19]),32);
        bufp->chgIData(oldp+63,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[20]),32);
        bufp->chgIData(oldp+64,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[21]),32);
        bufp->chgIData(oldp+65,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[22]),32);
        bufp->chgIData(oldp+66,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[23]),32);
        bufp->chgIData(oldp+67,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[24]),32);
        bufp->chgIData(oldp+68,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[25]),32);
        bufp->chgIData(oldp+69,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[26]),32);
        bufp->chgIData(oldp+70,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[27]),32);
        bufp->chgIData(oldp+71,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[28]),32);
        bufp->chgIData(oldp+72,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[29]),32);
        bufp->chgIData(oldp+73,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs[30]),32);
    }
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[3U])) {
        bufp->chgBit(oldp+74,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_we));
        bufp->chgIData(oldp+75,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wdata),32);
        bufp->chgCData(oldp+76,(vlSelf->sisPlatformTop__DOT__u_core__DOT__out_req_wstrb),4);
        bufp->chgIData(oldp+77,(vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg),32);
        bufp->chgCData(oldp+78,((0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0xfU))),5);
        bufp->chgCData(oldp+79,((0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 0x14U))),5);
        bufp->chgCData(oldp+80,((0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                          >> 7U))),5);
        bufp->chgIData(oldp+81,(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_imm_i),32);
        bufp->chgIData(oldp+82,((((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                              >> 0x1fU))) 
                                  << 0xcU) | ((0xfe0U 
                                               & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                  >> 0x14U)) 
                                              | (0x1fU 
                                                 & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                    >> 7U))))),32);
        bufp->chgIData(oldp+83,((((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                              >> 0x1fU))) 
                                  << 0xdU) | ((0x1000U 
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
                                                          >> 7U))))))),32);
        bufp->chgIData(oldp+84,((0xfffff000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)),32);
        bufp->chgIData(oldp+85,((((- (IData)((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                              >> 0x1fU))) 
                                  << 0x15U) | ((0x100000U 
                                                & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                   >> 0xbU)) 
                                               | ((0xff000U 
                                                   & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg) 
                                                  | ((0x800U 
                                                      & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                         >> 9U)) 
                                                     | (0x7feU 
                                                        & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                           >> 0x14U))))))),32);
        bufp->chgCData(oldp+86,((0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)),7);
        bufp->chgCData(oldp+87,((7U & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                       >> 0xcU))),3);
        bufp->chgCData(oldp+88,((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                 >> 0x19U)),7);
        bufp->chgBit(oldp+89,((0x37U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+90,((0x17U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+91,((0x6fU == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+92,((0x67U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+93,((0x63U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+94,((3U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+95,((0x23U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+96,((0x13U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+97,((0x33U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+98,((0x73U == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+99,((0xfU == (0x7fU & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg))));
        bufp->chgBit(oldp+100,(vlSelf->sisPlatformTop__DOT__u_core__DOT__dec_is_legal));
        bufp->chgBit(oldp+101,(vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_wr_en));
        bufp->chgIData(oldp+102,(vlSelf->sisPlatformTop__DOT__u_core__DOT__rf_rd_data),32);
        bufp->chgIData(oldp+103,(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_a),32);
        bufp->chgIData(oldp+104,(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_b),32);
        bufp->chgCData(oldp+105,(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_op),4);
        bufp->chgIData(oldp+106,(vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result),32);
        bufp->chgBit(oldp+107,((0U == vlSelf->sisPlatformTop__DOT__u_core__DOT__alu_result)));
        bufp->chgSData(oldp+108,((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                  >> 0x14U)),12);
        bufp->chgCData(oldp+109,(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_op_type),2);
        bufp->chgBit(oldp+110,(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_wen_w));
        bufp->chgIData(oldp+111,(vlSelf->sisPlatformTop__DOT__u_core__DOT__csr_rdata_w),32);
        bufp->chgBit(oldp+112,(vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_enter));
        bufp->chgIData(oldp+113,(vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_cause),32);
        bufp->chgIData(oldp+114,(vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_val),32);
        bufp->chgIData(oldp+115,(vlSelf->sisPlatformTop__DOT__u_core__DOT__trap_epc),32);
        bufp->chgBit(oldp+116,(vlSelf->sisPlatformTop__DOT__u_core__DOT__mret_exec));
        bufp->chgBit(oldp+117,(vlSelf->sisPlatformTop__DOT__u_core__DOT__branch_taken));
        bufp->chgBit(oldp+118,(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ecall));
        bufp->chgBit(oldp+119,(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_ebreak));
        bufp->chgBit(oldp+120,(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_mret));
        bufp->chgBit(oldp+121,(vlSelf->sisPlatformTop__DOT__u_core__DOT__is_csr_op));
        bufp->chgIData(oldp+122,(vlSelf->sisPlatformTop__DOT__u_core__DOT__store_data),32);
        bufp->chgCData(oldp+123,(vlSelf->sisPlatformTop__DOT__u_core__DOT__store_strb),4);
        bufp->chgIData(oldp+124,(vlSelf->sisPlatformTop__DOT__u_core__DOT__load_result),32);
        bufp->chgIData(oldp+125,(vlSelf->sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val),32);
    }
    bufp->chgBit(oldp+126,(vlSelf->clk));
    bufp->chgBit(oldp+127,(vlSelf->rst_n));
    bufp->chgBit(oldp+128,(vlSelf->tohost_pass));
    bufp->chgBit(oldp+129,(vlSelf->tohost_fail));
    bufp->chgIData(oldp+130,(vlSelf->tohost_code),32);
    bufp->chgIData(oldp+131,(((0U == (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                               >> 0xfU)))
                               ? 0U : ((0x1eU >= (0x1fU 
                                                  & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                      >> 0xfU) 
                                                     - (IData)(1U))))
                                        ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs
                                       [(0x1fU & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                   >> 0xfU) 
                                                  - (IData)(1U)))]
                                        : 0U))),32);
    bufp->chgIData(oldp+132,(((0U == (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                               >> 0x14U)))
                               ? 0U : ((0x1eU >= (0x1fU 
                                                  & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                      >> 0x14U) 
                                                     - (IData)(1U))))
                                        ? vlSelf->sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs
                                       [(0x1fU & ((vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                                   >> 0x14U) 
                                                  - (IData)(1U)))]
                                        : 0U))),32);
    bufp->chgIData(oldp+133,(((0x4000U & vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg)
                               ? (0x1fU & (vlSelf->sisPlatformTop__DOT__u_core__DOT__instr_reg 
                                           >> 0xfU))
                               : vlSelf->sisPlatformTop__DOT__u_core__DOT__rs1_val)),32);
}

void VsisPlatformTop___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root__trace_cleanup\n"); );
    // Init
    VsisPlatformTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VsisPlatformTop___024root*>(voidSelf);
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[2U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[3U] = 0U;
}
