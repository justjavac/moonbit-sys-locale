# justjavac/sys_locale

[![CI](https://github.com/justjavac/moonbit-sys-locale/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-sys-locale/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![linux](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=linux&label=linux)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![macos](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=macos&label=macos)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![windows](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=windows&label=windows)](https://codecov.io/gh/justjavac/moonbit-sys-locale)

Read the current system locale and preferred locale list from MoonBit, with
normalization for common native spellings such as `en_US.UTF-8`.

This package currently supports the `native` target only.

## Install

```bash
moon add justjavac/sys_locale
```

## API

- `current()` returns the first preferred locale, if one is available.
- `current_tag()` returns the normalized tag for the current locale.
- `preferred()` returns all discovered locales in preference order.
- `preferred_tags()` returns normalized tags only.
- `parse()` parses a raw locale string into a `Locale`.
- `canonicalize()` returns only the normalized locale tag.

## Example

```moonbit
match @sys_locale.current_tag() {
  Some(tag) => println(tag)
  None => println("locale unavailable")
}
```

More usage snippets live in [`src/examples/`](src/examples/README.md).

## Notes

- Environment variables are checked in this order: `LC_ALL`, `LC_MESSAGES`,
  `LANGUAGE`, `LANG`.
- On Windows, the package falls back to the user default locale from the system
  API.
- POSIX encodings and modifiers such as `.UTF-8` and `@euro` are stripped while
  canonicalizing tags.
