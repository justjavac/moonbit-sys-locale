// Example: print every preferred locale in order.
//
// Add the dependency first:
//   moon add justjavac/sys_locale

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
