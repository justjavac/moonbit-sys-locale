///|
/// Appends the native locale only when one was detected.
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
/// Collects raw locale candidates from env vars and native APIs.
fn locale_raw_candidates_internal() -> Array[String] {
  let result : Array[String] = []
  append_env_locale_candidates(result)
  append_optional_locale_candidate(result, native_system_locale())
  result
}

///|
/// Decodes the native locale bytes when the FFI call succeeds.
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
/// Reads the current locale through the native shim.
fn native_system_locale() -> String? {
  let buf = Bytes::new(128)
  let written = native_system_locale_ffi(buf, buf.length())
  decode_native_system_locale(buf, written)
}

///|
/// Binds to the native function that writes the current locale tag.
#borrow(buf)
extern "c" fn native_system_locale_ffi(buf : Bytes, len : Int) -> Int = "sys_locale_native_current"
