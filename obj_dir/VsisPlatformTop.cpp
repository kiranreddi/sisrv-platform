// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VsisPlatformTop__pch.h"
#include "verilated_fst_c.h"

//============================================================
// Constructors

VsisPlatformTop::VsisPlatformTop(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VsisPlatformTop__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst_n{vlSymsp->TOP.rst_n}
    , tohost_pass{vlSymsp->TOP.tohost_pass}
    , tohost_fail{vlSymsp->TOP.tohost_fail}
    , tohost_code{vlSymsp->TOP.tohost_code}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VsisPlatformTop::VsisPlatformTop(const char* _vcname__)
    : VsisPlatformTop(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VsisPlatformTop::~VsisPlatformTop() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VsisPlatformTop___024root___eval_debug_assertions(VsisPlatformTop___024root* vlSelf);
#endif  // VL_DEBUG
void VsisPlatformTop___024root___eval_static(VsisPlatformTop___024root* vlSelf);
void VsisPlatformTop___024root___eval_initial(VsisPlatformTop___024root* vlSelf);
void VsisPlatformTop___024root___eval_settle(VsisPlatformTop___024root* vlSelf);
void VsisPlatformTop___024root___eval(VsisPlatformTop___024root* vlSelf);

void VsisPlatformTop::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VsisPlatformTop::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VsisPlatformTop___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VsisPlatformTop___024root___eval_static(&(vlSymsp->TOP));
        VsisPlatformTop___024root___eval_initial(&(vlSymsp->TOP));
        VsisPlatformTop___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VsisPlatformTop___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VsisPlatformTop::eventsPending() { return false; }

uint64_t VsisPlatformTop::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VsisPlatformTop::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VsisPlatformTop___024root___eval_final(VsisPlatformTop___024root* vlSelf);

VL_ATTR_COLD void VsisPlatformTop::final() {
    VsisPlatformTop___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VsisPlatformTop::hierName() const { return vlSymsp->name(); }
const char* VsisPlatformTop::modelName() const { return "VsisPlatformTop"; }
unsigned VsisPlatformTop::threads() const { return 1; }
void VsisPlatformTop::prepareClone() const { contextp()->prepareClone(); }
void VsisPlatformTop::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> VsisPlatformTop::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void VsisPlatformTop___024root__trace_decl_types(VerilatedFst* tracep);

void VsisPlatformTop___024root__trace_init_top(VsisPlatformTop___024root* vlSelf, VerilatedFst* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedFst* tracep, uint32_t code) {
    // Callback from tracep->open()
    VsisPlatformTop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<VsisPlatformTop___024root*>(voidSelf);
    VsisPlatformTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    VsisPlatformTop___024root__trace_decl_types(tracep);
    VsisPlatformTop___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void VsisPlatformTop___024root__trace_register(VsisPlatformTop___024root* vlSelf, VerilatedFst* tracep);

VL_ATTR_COLD void VsisPlatformTop::trace(VerilatedFstC* tfp, int levels, int options) {
    if (tfp->isOpen()) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'VsisPlatformTop::trace()' shall not be called after 'VerilatedFstC::open()'.");
    }
    if (false && levels && options) {}  // Prevent unused
    tfp->spTrace()->addModel(this);
    tfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    VsisPlatformTop___024root__trace_register(&(vlSymsp->TOP), tfp->spTrace());
}
