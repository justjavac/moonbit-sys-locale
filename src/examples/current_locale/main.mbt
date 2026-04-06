///|
/// Prints the current locale tag when one is available.
fn main {
  match @sys_locale.current_tag() {
    Some(tag) => println("current locale: \{tag}")
    None => println("locale unavailable")
  }
}
