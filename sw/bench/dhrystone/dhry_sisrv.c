#include "dhry.h"
#include "sisrv_bench.h"

#ifndef DHRY_ITERATIONS
#define DHRY_ITERATIONS 1000
#endif
#ifndef REG
#define REG
#endif

extern Rec_Pointer Ptr_Glob;
extern Rec_Pointer Next_Ptr_Glob;
extern int Int_Glob;
extern Boolean Bool_Glob;
extern char Ch_1_Glob;
extern char Ch_2_Glob;
extern int Arr_1_Glob[50];
extern int Arr_2_Glob[50][50];
extern Boolean Reg;

Enumeration Func_1(Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val);
Boolean Func_2(Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref);
void Proc_1(Rec_Pointer Ptr_Val_Par);
void Proc_2(One_Fifty *Int_Par_Ref);
void Proc_4(void);
void Proc_5(void);
void Proc_6(Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par);
void Proc_7(One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref);
void Proc_8(Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref, int Int_1_Par_Val, int Int_2_Par_Val);

static Rec_Type rec_storage;
static Rec_Type next_rec_storage;

static int verify_results(int runs, One_Fifty int_1, One_Fifty int_2,
                          One_Fifty int_3, Enumeration enum_loc,
                          const char *str_1, const char *str_2) {
  int ok = 1;
  ok &= (Int_Glob == 5);
  ok &= (Bool_Glob == true);
  ok &= (Ch_1_Glob == 'A');
  ok &= (Ch_2_Glob == 'B');
  ok &= (Arr_1_Glob[8] == 7);
  ok &= (Arr_2_Glob[8][7] == runs + 10);
  ok &= (Ptr_Glob->Discr == Ident_1);
  ok &= (Ptr_Glob->variant.var_1.Enum_Comp == Ident_3);
  ok &= (Ptr_Glob->variant.var_1.Int_Comp == 17);
  ok &= (strcmp(Ptr_Glob->variant.var_1.Str_Comp,
                "DHRYSTONE PROGRAM, SOME STRING") == 0);
  ok &= (Next_Ptr_Glob->Discr == Ident_1);
  ok &= (Next_Ptr_Glob->variant.var_1.Enum_Comp == Ident_2);
  ok &= (Next_Ptr_Glob->variant.var_1.Int_Comp == 18);
  ok &= (strcmp(Next_Ptr_Glob->variant.var_1.Str_Comp,
                "DHRYSTONE PROGRAM, SOME STRING") == 0);
  ok &= (int_1 == 5);
  ok &= (int_2 == 13);
  ok &= (int_3 == 7);
  ok &= (enum_loc == Ident_2);
  ok &= (strcmp(str_1, "DHRYSTONE PROGRAM, 1'ST STRING") == 0);
  ok &= (strcmp(str_2, "DHRYSTONE PROGRAM, 2'ND STRING") == 0);
  return ok;
}

int main(void) {
  One_Fifty Int_1_Loc;
  REG One_Fifty Int_2_Loc;
  One_Fifty Int_3_Loc;
  REG char Ch_Index;
  Enumeration Enum_Loc = Ident_1;
  Str_30 Str_1_Loc;
  Str_30 Str_2_Loc;
  REG int Run_Index;
  const int Number_Of_Runs = DHRY_ITERATIONS;

  Next_Ptr_Glob = &next_rec_storage;
  Ptr_Glob = &rec_storage;

  Ptr_Glob->Ptr_Comp = Next_Ptr_Glob;
  Ptr_Glob->Discr = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp = 40;
  strcpy(Ptr_Glob->variant.var_1.Str_Comp,
         "DHRYSTONE PROGRAM, SOME STRING");
  strcpy(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");
  Arr_2_Glob[8][7] = 10;

  sisrv_printf("Dhrystone Benchmark, Version 2.1 (Language: C)\n");
  sisrv_printf("Execution starts, %d runs through Dhrystone\n", Number_Of_Runs);

  uint64_t start_cycle = sisrv_read_mcycle64();
  uint64_t start_instret = sisrv_read_minstret64();

  for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index) {
    Proc_5();
    Proc_4();
    Int_1_Loc = 2;
    Int_2_Loc = 3;
    strcpy(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
    Enum_Loc = Ident_2;
    Bool_Glob = !Func_2(Str_1_Loc, Str_2_Loc);
    while (Int_1_Loc < Int_2_Loc) {
      Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
      Proc_7(Int_1_Loc, Int_2_Loc, &Int_3_Loc);
      Int_1_Loc += 1;
    }
    Proc_8(Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
    Proc_1(Ptr_Glob);
    for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index) {
      if (Enum_Loc == Func_1(Ch_Index, 'C')) {
        Proc_6(Ident_1, &Enum_Loc);
        strcpy(Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
        Int_2_Loc = Run_Index;
        Int_Glob = Run_Index;
      }
    }
    Int_2_Loc = Int_2_Loc * Int_1_Loc;
    Int_1_Loc = Int_2_Loc / Int_3_Loc;
    Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
    Proc_2(&Int_1_Loc);
  }

  uint64_t end_instret = sisrv_read_minstret64();
  uint64_t end_cycle = sisrv_read_mcycle64();
  uint64_t cycles = end_cycle - start_cycle;
  uint64_t instret = end_instret - start_instret;
  int ok = verify_results(Number_Of_Runs, Int_1_Loc, Int_2_Loc, Int_3_Loc,
                          Enum_Loc, Str_1_Loc, Str_2_Loc);

  uint64_t cycles_per_iter_milli = (cycles * 1000u) / (uint64_t)Number_Of_Runs;
  uint64_t inst_per_iter_milli = (instret * 1000u) / (uint64_t)Number_Of_Runs;
  uint64_t dhrystones_per_sec_per_mhz_milli =
      ((uint64_t)Number_Of_Runs * 1000000000ull) / cycles;
  uint64_t dmips_per_mhz_milli =
      ((uint64_t)Number_Of_Runs * 1000000000ull) / (cycles * 1757ull);
  uint64_t cpi_milli = (cycles * 1000u) / instret;

  sisrv_printf("Execution ends\n");
  sisrv_printf("Validation        : %s\n", ok ? "PASS" : "FAIL");
  sisrv_printf("SISRV_BENCH benchmark=dhrystone\n");
  sisrv_printf("SISRV_BENCH iterations=%d\n", Number_Of_Runs);
  sisrv_printf("SISRV_BENCH cycles=");
  sisrv_print_u64(cycles);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH instret=");
  sisrv_print_u64(instret);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH cycles_per_iteration=");
  sisrv_print_fixed3(cycles_per_iter_milli);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH instructions_per_iteration=");
  sisrv_print_fixed3(inst_per_iter_milli);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH cpi=");
  sisrv_print_fixed3(cpi_milli);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH dhrystones_per_sec_per_mhz=");
  sisrv_print_fixed3(dhrystones_per_sec_per_mhz_milli);
  sisrv_uart_putc('\n');
  sisrv_printf("SISRV_BENCH dmips_per_mhz=");
  sisrv_print_fixed3(dmips_per_mhz_milli);
  sisrv_uart_putc('\n');

  sisrv_exit(ok);
  return ok ? 0 : 1;
}

void *malloc(unsigned int size) {
  (void)size;
  return 0;
}

int scanf(const char *fmt, ...) {
  (void)fmt;
  return 0;
}

long time(long *tloc) {
  long now = (long)sisrv_read_mcycle64();
  if (tloc != 0) {
    *tloc = now;
  }
  return now;
}
