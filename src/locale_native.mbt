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
/// Returns the initial byte capacity used for the native locale buffer.
fn native_locale_initial_buffer_size() -> Int {
  128
}

///|
/// Returns a conservative upper bound for locale buffer growth.
fn native_locale_max_buffer_size() -> Int {
  4096
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
  if written <= 0 || written > buf.length() {
    None
  } else {
    Some(@utf8.decode(buf[:written])) catch {
      _ => None
    }
  }
}

///|
/// Reads the current locale through the native shim using a growing buffer.
fn read_native_system_locale_with_capacity(capacity : Int) -> String? {
  let buf = Bytes::new(capacity)
  let written = native_system_locale_ffi(buf, capacity)
  if written >= capacity {
    if capacity >= native_locale_max_buffer_size() {
      None
    } else {
      read_native_system_locale_with_capacity(capacity * 2)
    }
  } else {
    decode_native_system_locale(buf, written)
  }
}

///|
/// Reads the current locale through the native shim.
fn native_system_locale() -> String? {
  read_native_system_locale_with_capacity(native_locale_initial_buffer_size())
}

///|
/// Binds to the native function that writes the current locale tag.
///
/// The native side returns the byte count written on success, or the required
/// byte count when the provided buffer is too small.
#borrow(buf)
extern "c" fn native_system_locale_ffi(buf : Bytes, len : Int) -> Int = "sys_locale_native_current"
