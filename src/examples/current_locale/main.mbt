///|
/// Prints the current locale tag when one is available.
fn main {
  match @sys_locale.current() {
    Some(locale) => println("current locale: \{locale.tag}")
    None => println("locale unavailable")
  }
}
