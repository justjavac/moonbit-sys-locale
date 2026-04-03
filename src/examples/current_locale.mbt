// Example: print the current normalized locale tag.
//
// Add the dependency first:
//   moon add justjavac/sys_locale

fn main {
  match @sys_locale.current() {
    Some(locale) => println("current locale: \{locale.tag}")
    None => println("locale unavailable")
  }
}
