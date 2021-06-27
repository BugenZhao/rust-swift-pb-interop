#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct ByteBuffer {
  const uint8_t *ptr;
  uintptr_t len;
  uintptr_t cap;
  const char *err;
} ByteBuffer;

typedef struct RustCallback {
  const void *user_data;
  void (*callback)(const void*, struct ByteBuffer);
} RustCallback;

/**
 * # Safety
 * totally unsafe
 */
struct ByteBuffer rust_call(const uint8_t *data, uintptr_t len);

/**
 * # Safety
 * totally unsafe
 */
void rust_call_async(const uint8_t *data, uintptr_t len, struct RustCallback callback);

/**
 * # Safety
 * totally unsafe
 */
void rust_free(struct ByteBuffer byte_buffer);
