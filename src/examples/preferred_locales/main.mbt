///|
/// Prints every preferred locale tag in order.
fn main {
  let locales = @sys_locale.preferred()
  if locales.length() == 0 {
    println("no locale detected")
  } else {
    for locale in locales {
      println(locale.tag)
    }
  }
}
