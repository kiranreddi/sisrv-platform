#include "coremark.h"
#include "sisrv_bench.h"

#ifndef COREMARK_SEED1
#define COREMARK_SEED1 0
#endif
#ifndef COREMARK_SEED2
#define COREMARK_SEED2 0
#endif
#ifndef COREMARK_SEED3
#define COREMARK_SEED3 0x66
#endif
#ifndef COREMARK_ITERATIONS
#define COREMARK_ITERATIONS 1
#endif
#ifndef COREMARK_TICKS_PER_SEC
#define COREMARK_TICKS_PER_SEC 1000000u
#endif

volatile ee_s32 seed1_volatile = COREMARK_SEED1;
volatile ee_s32 seed2_volatile = COREMARK_SEED2;
volatile ee_s32 seed3_volatile = COREMARK_SEED3;
volatile ee_s32 seed4_volatile = COREMARK_ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

static CORE_TICKS start_time_val;
static CORE_TICKS stop_time_val;

ee_u32 default_num_contexts = 1;

static CORE_TICKS bench_clock(void) {
  return (CORE_TICKS)sisrv_read_mcycle64();
}

void start_time(void) {
  start_time_val = bench_clock();
}

void stop_time(void) {
  stop_time_val = bench_clock();
}

CORE_TICKS get_time(void) {
  return stop_time_val - start_time_val;
}

secs_ret time_in_secs(CORE_TICKS ticks) {
  return ticks / COREMARK_TICKS_PER_SEC;
}

void portable_init(core_portable *p, int *argc, char *argv[]) {
  (void)argc;
  (void)argv;
  if (sizeof(ee_ptr_int) != sizeof(ee_u8 *)) {
    ee_printf("ERROR! ee_ptr_int cannot hold a pointer\n");
  }
  if (sizeof(ee_u32) != 4u) {
    ee_printf("ERROR! ee_u32 is not 32-bit\n");
  }
  p->portable_id = 1u;
}

void portable_fini(core_portable *p) {
  p->portable_id = 0u;
}

void *portable_malloc(ee_size_t size) {
  (void)size;
  return NULL;
}

void portable_free(void *p) {
  (void)p;
}

int ee_printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = sisrv_vprintf(fmt, ap);
  va_end(ap);
  return ret;
}
