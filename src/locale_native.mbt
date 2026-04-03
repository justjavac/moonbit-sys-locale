///|
fn append_optional_locale_candidate(
  target : Array[String],
  locale : String?,
) -> Unit {
  match locale {
    Some(locale) => push_candidate(target, locale)
    None => ()
  }
}

///|
fn locale_raw_candidates_internal() -> Array[String] {
  let result : Array[String] = []
  append_env_locale_candidates(result)
  append_optional_locale_candidate(result, native_system_locale())
  result
}

///|
fn decode_native_system_locale(buf : Bytes, written : Int) -> String? {
  if written <= 0 {
    None
  } else {
    Some(@utf8.decode(buf[:written])) catch {
      _ => None
    }
  }
}

///|
fn native_system_locale() -> String? {
  let buf = Bytes::new(128)
  let written = native_system_locale_ffi(buf, buf.length())
  decode_native_system_locale(buf, written)
}

///|
#borrow(buf)
extern "c" fn native_system_locale_ffi(buf : Bytes, len : Int) -> Int = "sys_locale_native_current"
