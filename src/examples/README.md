# Examples

These examples are small usage snippets for `justjavac/sys_locale`.

## Current locale

See [`current_locale.mbt`](current_locale.mbt) for a minimal example that reads
the current locale and prints the normalized tag.

## Preferred locales

See [`preferred_locales.mbt`](preferred_locales.mbt) for iterating over every
locale discovered from the process environment and native system fallback.

## Running the snippets

The files in this directory are example source snippets meant to be copied into
your own MoonBit project after adding the dependency:

```bash
moon add justjavac/sys_locale
```
