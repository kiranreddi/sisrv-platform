#ifndef SISRV_BENCH_H
#define SISRV_BENCH_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#define SISRV_UART_TXDATA ((volatile uint32_t *)0x10004000u)
#define SISRV_TOHOST     ((volatile uint32_t *)0x10000000u)

void sisrv_uart_putc(char c);
void sisrv_uart_puts(const char *s);
void sisrv_exit(int pass);

uint64_t sisrv_read_mcycle64(void);
uint64_t sisrv_read_minstret64(void);

void sisrv_print_u32(uint32_t value);
void sisrv_print_u64(uint64_t value);
void sisrv_print_hex32(uint32_t value);
void sisrv_print_fixed3(uint64_t milli_value);
int sisrv_vprintf(const char *fmt, va_list ap);
int sisrv_printf(const char *fmt, ...);

void *memcpy(void *dst, const void *src, size_t n);
void *memmove(void *dst, const void *src, size_t n);
void *memset(void *dst, int c, size_t n);
int memcmp(const void *a, const void *b, size_t n);
size_t strlen(const char *s);
char *strcpy(char *dst, const char *src);
int strcmp(const char *a, const char *b);

#endif
