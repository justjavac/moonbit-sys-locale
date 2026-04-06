# Examples

These examples are small usage snippets for `justjavac/sys_locale`.

## Current locale

See [`current_locale/main.mbt`](current_locale/main.mbt) for a minimal example
that reads `current_tag()` and prints the normalized tag.

## Preferred locales

See [`preferred_locales/main.mbt`](preferred_locales/main.mbt) for iterating
over every normalized tag returned by `preferred_tags()`.

## Running the snippets

Run the examples from the module root:

```bash
moon run src/examples/current_locale --target native
moon run src/examples/preferred_locales --target native
```

If you want to copy the code into your own project, add the dependency first:

```bash
moon add justjavac/sys_locale
```
