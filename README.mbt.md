# justjavac/sys_locale

[![CI](https://github.com/justjavac/moonbit-sys-locale/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-sys-locale/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![linux](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=linux&label=linux)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![macos](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=macos&label=macos)](https://codecov.io/gh/justjavac/moonbit-sys-locale)
[![windows](https://img.shields.io/codecov/c/github/justjavac/moonbit-sys-locale/main?flag=windows&label=windows)](https://codecov.io/gh/justjavac/moonbit-sys-locale)

Read and normalize the current system locale in MoonBit.

## Example

```mbt check
///|
test "basic locale helpers" {
  assert_eq(@sys_locale.canonicalize("en_US.UTF-8"), Some("en-US"))

  let tags = @sys_locale.preferred_tags()
  match @sys_locale.current_tag() {
    Some(tag) => {
      assert_true(tags.length() > 0)
      assert_eq(tags[0], tag)
    }
    None => assert_eq(tags.length(), 0)
  }
}
```
