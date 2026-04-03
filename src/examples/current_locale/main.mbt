///|
fn main {
  match @sys_locale.current() {
    Some(locale) => println("current locale: \{locale.tag}")
    None => println("locale unavailable")
  }
}
