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
    Some(utf8_bytes_to_string(buf))
  }
}

///|
#borrow(buf)
extern "c" fn native_system_locale_ffi(buf : Bytes, len : Int) -> Int = "sys_locale_native_current"

///|
fn utf8_bytes_to_string(bytes : Bytes) -> String {
  let res = StringBuilder::new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c == 0 {
      break
    } else if c < 0x80 {
      res.write_char(c.unsafe_to_char())
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c -= 0x10000
      res.write_char(((c >> 10) + 0xD800).unsafe_to_char())
      res.write_char(((c & 0x3FF) + 0xDC00).unsafe_to_char())
      i += 4
    }
  }
  res.to_string()
}
