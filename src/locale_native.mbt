///|
fn locale_raw_candidates_internal() -> Array[String] {
  let result : Array[String] = []
  append_env_locale_candidates(result)
  match native_system_locale() {
    Some(locale) => push_candidate(result, locale)
    None => ()
  }
  result
}

///|
fn native_system_locale() -> String? {
  let buf = Bytes::new(128)
  let written = native_system_locale_ffi(buf, buf.length())
  if written <= 0 {
    None
  } else {
    Some(@utf8.decode(buf[:written])) catch { _ => None }
  }
}

///|
#borrow(buf)
extern "c" fn native_system_locale_ffi(buf : Bytes, len : Int) -> Int = "sys_locale_native_current"
