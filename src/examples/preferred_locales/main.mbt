///|
/// Prints every preferred locale tag in order.
fn main {
  let tags = @sys_locale.preferred_tags()
  if tags.length() == 0 {
    println("no locale detected")
  } else {
    for tag in tags {
      println(tag)
    }
  }
}
