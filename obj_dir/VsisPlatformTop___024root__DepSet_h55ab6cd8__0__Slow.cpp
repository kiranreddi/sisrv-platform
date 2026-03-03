// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VsisPlatformTop.h for the primary calling header

#include "VsisPlatformTop__pch.h"
#include "VsisPlatformTop__Syms.h"
#include "VsisPlatformTop___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void VsisPlatformTop___024root___dump_triggers__stl(VsisPlatformTop___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void VsisPlatformTop___024root___eval_triggers__stl(VsisPlatformTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VsisPlatformTop___024root___eval_triggers__stl\n"); );
    // Body
    vlSelf->__VstlTriggered.set(0U, (IData)(vlSelf->__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VsisPlatformTop___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
