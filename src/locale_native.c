#include "moonbit.h"

#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>

int32_t sys_locale_native_current(uint8_t *buffer, int32_t len) {
  if (buffer == NULL || len <= 0) {
    return 0;
  }

  WCHAR wide_locale[LOCALE_NAME_MAX_LENGTH];
  int wide_len = GetUserDefaultLocaleName(wide_locale, LOCALE_NAME_MAX_LENGTH);
  if (wide_len <= 1) {
    return 0;
  }

  int utf8_len = WideCharToMultiByte(
      CP_UTF8, 0, wide_locale, -1, (LPSTR)buffer, len, NULL, NULL);
  if (utf8_len <= 1) {
    buffer[0] = 0;
    return 0;
  }

  return utf8_len - 1;
}

#else

#include <locale.h>

int32_t sys_locale_native_current(uint8_t *buffer, int32_t len) {
  if (buffer == NULL || len <= 0) {
    return 0;
  }

  const char *locale = NULL;
#ifdef LC_MESSAGES
  locale = setlocale(LC_MESSAGES, NULL);
#endif
  if (locale == NULL || locale[0] == '\0') {
    locale = setlocale(LC_CTYPE, NULL);
  }
  if (locale == NULL || locale[0] == '\0') {
    return 0;
  }

  size_t locale_len = strlen(locale);
  if ((int32_t)locale_len >= len) {
    locale_len = (size_t)(len - 1);
  }
  memcpy(buffer, locale, locale_len);
  buffer[locale_len] = 0;
  return (int32_t)locale_len;
}

#endif
