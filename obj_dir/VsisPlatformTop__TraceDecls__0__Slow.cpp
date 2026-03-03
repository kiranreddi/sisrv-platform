// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing declarations
#include "verilated_fst_c.h"


void VsisPlatformTop___024root__traceDeclTypesSub0(VerilatedFst* tracep) {
    {
        const char* __VenumItemNames[]
        = {"S_FETCH_REQ", "S_FETCH_WAIT", "S_DECODE", 
                                "S_EXECUTE", "S_MEM_REQ", 
                                "S_MEM_WAIT", "S_WB"};
        const char* __VenumItemValues[]
        = {"0", "1", "10", "11", "100", "101", "110"};
        tracep->declDTypeEnum(1, "sisRvCore.state_t", 7, 3, __VenumItemNames, __VenumItemValues);
    }
}

void VsisPlatformTop___024root__trace_decl_types(VerilatedFst* tracep) {
    VsisPlatformTop___024root__traceDeclTypesSub0(tracep);
}
