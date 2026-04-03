# justjavac/sys_locale

Read and normalize the current system locale in MoonBit.

This package supports the `native` target only.

## Example

```mbt check
///|
test "basic locale helpers" {
  assert_eq(@sys_locale.canonicalize("en_US.UTF-8"), Some("en-US"))

  let current = @sys_locale.current_tag()
  let preferred = @sys_locale.preferred_tags()

  match current {
    Some(_) => ()
    None => ()
  }
  assert_true(preferred.length() >= 0)
}
```
