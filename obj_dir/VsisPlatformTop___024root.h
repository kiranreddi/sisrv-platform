// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VsisPlatformTop.h for the primary calling header

#ifndef VERILATED_VSISPLATFORMTOP___024ROOT_H_
#define VERILATED_VSISPLATFORMTOP___024ROOT_H_  // guard

#include "verilated.h"


class VsisPlatformTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VsisPlatformTop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        VL_IN8(clk,0,0);
        VL_IN8(rst_n,0,0);
        VL_OUT8(tohost_pass,0,0);
        VL_OUT8(tohost_fail,0,0);
        CData/*0:0*/ sisPlatformTop__DOT__core_req_ready;
        CData/*0:0*/ sisPlatformTop__DOT__core_rsp_valid;
        CData/*0:0*/ sisPlatformTop__DOT__rom_req_valid;
        CData/*0:0*/ sisPlatformTop__DOT__rom_req_ready;
        CData/*0:0*/ sisPlatformTop__DOT__rom_rsp_valid;
        CData/*0:0*/ sisPlatformTop__DOT__rom_rsp_ready;
        CData/*0:0*/ sisPlatformTop__DOT__ram_req_valid;
        CData/*0:0*/ sisPlatformTop__DOT__ram_req_ready;
        CData/*0:0*/ sisPlatformTop__DOT__ram_rsp_valid;
        CData/*0:0*/ sisPlatformTop__DOT__ram_rsp_ready;
        CData/*0:0*/ sisPlatformTop__DOT__mmio_req_valid;
        CData/*0:0*/ sisPlatformTop__DOT__mmio_req_ready;
        CData/*0:0*/ sisPlatformTop__DOT__mmio_rsp_valid;
        CData/*0:0*/ sisPlatformTop__DOT__mmio_rsp_ready;
        CData/*2:0*/ sisPlatformTop__DOT__u_core__DOT__state;
        CData/*2:0*/ sisPlatformTop__DOT__u_core__DOT__state_next;
        CData/*6:0*/ sisPlatformTop__DOT__u_core__DOT__dec_opcode;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__dec_is_legal;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__rf_wr_en;
        CData/*3:0*/ sisPlatformTop__DOT__u_core__DOT__alu_op;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__csr_wen_w;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__trap_enter;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__mret_exec;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__branch_taken;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__is_ecall;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__is_ebreak;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__is_mret;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__is_csr_op;
        CData/*1:0*/ sisPlatformTop__DOT__u_core__DOT__csr_op_type;
        CData/*3:0*/ sisPlatformTop__DOT__u_core__DOT__store_strb;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__out_req_valid;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__out_req_we;
        CData/*3:0*/ sisPlatformTop__DOT__u_core__DOT__out_req_wstrb;
        CData/*0:0*/ sisPlatformTop__DOT__u_core__DOT__out_rsp_ready;
        CData/*1:0*/ sisPlatformTop__DOT__u_fabric__DOT__active_slave;
        CData/*0:0*/ sisPlatformTop__DOT__u_fabric__DOT__has_pending;
        CData/*0:0*/ sisPlatformTop__DOT__u_rom__DOT__pending;
        CData/*0:0*/ sisPlatformTop__DOT__u_ram__DOT__pending;
        CData/*0:0*/ sisPlatformTop__DOT__u_tohost__DOT__pending;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__rst_n__0;
        CData/*0:0*/ __VactContinue;
        VL_OUT(tohost_code,31,0);
        IData/*31:0*/ sisPlatformTop__DOT__core_rsp_rdata;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__pc;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__pc_next;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__instr_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__dec_imm_i;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__dec_imm_b;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__dec_imm_j;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__rf_rs1_data;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__rf_rs2_data;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__rf_rd_data;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__rs1_val;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__rs2_val;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__alu_a;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__alu_b;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__alu_result;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__csr_rdata_w;
    };
    struct {
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__trap_cause;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__trap_val;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__trap_epc;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__alu_result_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__mem_addr_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__mem_rdata_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__store_data;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__load_result;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__out_req_addr;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__out_req_wdata;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT____Vlvbound_h41f78afe__0;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mstatus;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mie;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtvec;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mscratch;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mepc;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mcause;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mtval;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__mip;
        IData/*31:0*/ sisPlatformTop__DOT__u_core__DOT__u_csr__DOT__csr_new_val;
        IData/*31:0*/ sisPlatformTop__DOT__u_rom__DOT__rdata_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_rom__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ sisPlatformTop__DOT__u_ram__DOT__rdata_reg;
        IData/*31:0*/ sisPlatformTop__DOT__u_ram__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ __Vdly__sisPlatformTop__DOT__u_core__DOT__instr_reg;
        IData/*31:0*/ __VactIterCount;
        VlUnpacked<IData/*31:0*/, 31> sisPlatformTop__DOT__u_core__DOT__u_regfile__DOT__regs;
        VlUnpacked<IData/*31:0*/, 16384> sisPlatformTop__DOT__u_rom__DOT__mem;
        VlUnpacked<IData/*31:0*/, 65536> sisPlatformTop__DOT__u_ram__DOT__mem;
        VlUnpacked<CData/*0:0*/, 4> __Vm_traceActivity;
    };
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    VsisPlatformTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VsisPlatformTop___024root(VsisPlatformTop__Syms* symsp, const char* v__name);
    ~VsisPlatformTop___024root();
    VL_UNCOPYABLE(VsisPlatformTop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
