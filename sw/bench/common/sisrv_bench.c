#include "sisrv_bench.h"

void sisrv_uart_putc(char c) {
  *SISRV_UART_TXDATA = (uint32_t)(uint8_t)c;
}

void sisrv_uart_puts(const char *s) {
  while (*s != '\0') {
    sisrv_uart_putc(*s++);
  }
}

void sisrv_exit(int pass) {
  *SISRV_TOHOST = pass ? 1u : 0u;
  for (;;) {
  }
}

static uint32_t read_mcycle(void) {
  uint32_t value;
  __asm__ volatile("csrr %0, mcycle" : "=r"(value));
  return value;
}

static uint32_t read_mcycleh(void) {
  uint32_t value;
  __asm__ volatile("csrr %0, mcycleh" : "=r"(value));
  return value;
}

static uint32_t read_minstret(void) {
  uint32_t value;
  __asm__ volatile("csrr %0, minstret" : "=r"(value));
  return value;
}

static uint32_t read_minstreth(void) {
  uint32_t value;
  __asm__ volatile("csrr %0, minstreth" : "=r"(value));
  return value;
}

uint64_t sisrv_read_mcycle64(void) {
  uint32_t hi0;
  uint32_t lo;
  uint32_t hi1;
  do {
    hi0 = read_mcycleh();
    lo = read_mcycle();
    hi1 = read_mcycleh();
  } while (hi0 != hi1);
  return ((uint64_t)hi1 << 32) | lo;
}

uint64_t sisrv_read_minstret64(void) {
  uint32_t hi0;
  uint32_t lo;
  uint32_t hi1;
  do {
    hi0 = read_minstreth();
    lo = read_minstret();
    hi1 = read_minstreth();
  } while (hi0 != hi1);
  return ((uint64_t)hi1 << 32) | lo;
}

void sisrv_print_u32(uint32_t value) {
  char buf[10];
  unsigned pos = 0;
  if (value == 0) {
    sisrv_uart_putc('0');
    return;
  }
  while (value != 0) {
    buf[pos++] = (char)('0' + (value % 10u));
    value /= 10u;
  }
  while (pos != 0) {
    sisrv_uart_putc(buf[--pos]);
  }
}

void sisrv_print_u64(uint64_t value) {
  char buf[20];
  unsigned pos = 0;
  if (value == 0) {
    sisrv_uart_putc('0');
    return;
  }
  while (value != 0) {
    buf[pos++] = (char)('0' + (uint32_t)(value % 10u));
    value /= 10u;
  }
  while (pos != 0) {
    sisrv_uart_putc(buf[--pos]);
  }
}

void sisrv_print_hex32(uint32_t value) {
  static const char hex[] = "0123456789abcdef";
  sisrv_uart_puts("0x");
  for (int shift = 28; shift >= 0; shift -= 4) {
    sisrv_uart_putc(hex[(value >> shift) & 0xfu]);
  }
}

void sisrv_print_fixed3(uint64_t milli_value) {
  sisrv_print_u64(milli_value / 1000u);
  sisrv_uart_putc('.');
  uint32_t frac = (uint32_t)(milli_value % 1000u);
  sisrv_uart_putc((char)('0' + (frac / 100u)));
  sisrv_uart_putc((char)('0' + ((frac / 10u) % 10u)));
  sisrv_uart_putc((char)('0' + (frac % 10u)));
}

static void print_padded_decimal(uint32_t value, int width, char pad) {
  char buf[10];
  int pos = 0;
  if (value == 0) {
    buf[pos++] = '0';
  } else {
    while (value != 0) {
      buf[pos++] = (char)('0' + (value % 10u));
      value /= 10u;
    }
  }
  while (pos < width) {
    sisrv_uart_putc(pad);
    --width;
  }
  while (pos != 0) {
    sisrv_uart_putc(buf[--pos]);
  }
}

int sisrv_vprintf(const char *fmt, va_list ap) {
  int written = 0;
  while (*fmt != '\0') {
    if (*fmt != '%') {
      sisrv_uart_putc(*fmt++);
      ++written;
      continue;
    }
    ++fmt;
    char pad = ' ';
    int width = 0;
    int long_arg = 0;
    if (*fmt == '0') {
      pad = '0';
      ++fmt;
    }
    while (*fmt >= '0' && *fmt <= '9') {
      width = width * 10 + (*fmt - '0');
      ++fmt;
    }
    if (*fmt == 'l') {
      long_arg = 1;
      ++fmt;
    }
    switch (*fmt) {
      case 'c':
        sisrv_uart_putc((char)va_arg(ap, int));
        break;
      case 's': {
        const char *s = va_arg(ap, const char *);
        sisrv_uart_puts(s ? s : "(null)");
        break;
      }
      case 'd': {
        int32_t v = long_arg ? (int32_t)va_arg(ap, long) : va_arg(ap, int);
        if (v < 0) {
          sisrv_uart_putc('-');
          v = -v;
        }
        print_padded_decimal((uint32_t)v, width, pad);
        break;
      }
      case 'u': {
        uint32_t v = long_arg ? (uint32_t)va_arg(ap, unsigned long)
                              : va_arg(ap, unsigned int);
        print_padded_decimal(v, width, pad);
        break;
      }
      case 'x': {
        uint32_t v = long_arg ? (uint32_t)va_arg(ap, unsigned long)
                              : va_arg(ap, unsigned int);
        static const char hex[] = "0123456789abcdef";
        int nibbles = width > 0 ? width : 1;
        int started = 0;
        for (int shift = 28; shift >= 0; shift -= 4) {
          uint32_t digit = (v >> shift) & 0xfu;
          if (digit != 0 || started || shift == 0 || nibbles >= (shift / 4 + 1)) {
            started = 1;
            sisrv_uart_putc(hex[digit]);
          }
        }
        break;
      }
      case '%':
        sisrv_uart_putc('%');
        break;
      default:
        sisrv_uart_putc('%');
        sisrv_uart_putc(*fmt);
        break;
    }
    if (*fmt != '\0') {
      ++fmt;
    }
  }
  return written;
}

int sisrv_printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = sisrv_vprintf(fmt, ap);
  va_end(ap);
  return ret;
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = sisrv_vprintf(fmt, ap);
  va_end(ap);
  return ret;
}

void *memcpy(void *dst, const void *src, size_t n) {
  uint8_t *d = (uint8_t *)dst;
  const uint8_t *s = (const uint8_t *)src;
  while (n-- != 0u) {
    *d++ = *s++;
  }
  return dst;
}

void *memmove(void *dst, const void *src, size_t n) {
  uint8_t *d = (uint8_t *)dst;
  const uint8_t *s = (const uint8_t *)src;
  if (d < s) {
    while (n-- != 0u) {
      *d++ = *s++;
    }
  } else if (d > s) {
    d += n;
    s += n;
    while (n-- != 0u) {
      *--d = *--s;
    }
  }
  return dst;
}

void *memset(void *dst, int c, size_t n) {
  uint8_t *d = (uint8_t *)dst;
  while (n-- != 0u) {
    *d++ = (uint8_t)c;
  }
  return dst;
}

int memcmp(const void *a, const void *b, size_t n) {
  const uint8_t *pa = (const uint8_t *)a;
  const uint8_t *pb = (const uint8_t *)b;
  while (n-- != 0u) {
    if (*pa != *pb) {
      return (int)*pa - (int)*pb;
    }
    ++pa;
    ++pb;
  }
  return 0;
}

size_t strlen(const char *s) {
  const char *p = s;
  while (*p != '\0') {
    ++p;
  }
  return (size_t)(p - s);
}

char *strcpy(char *dst, const char *src) {
  char *ret = dst;
  while ((*dst++ = *src++) != '\0') {
  }
  return ret;
}

int strcmp(const char *a, const char *b) {
  while (*a != '\0' && *a == *b) {
    ++a;
    ++b;
  }
  return (int)(unsigned char)*a - (int)(unsigned char)*b;
}
