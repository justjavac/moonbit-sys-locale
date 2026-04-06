///|
/// Parses and deduplicates locale candidates in preference order.
fn locales_from_raw_candidates(raw_candidates : Array[String]) -> Array[Locale] {
  let locales : Array[Locale] = []
  let seen : Map[String, Bool] = {}
  for raw in raw_candidates {
    for piece in split_locale_list(raw) {
      append_parsed_locale_if_new(locales, seen, piece)
    }
  }
  locales
}

///|
/// Appends a parsed locale only when its tag has not been seen yet.
fn append_parsed_locale_if_new(
  target : Array[Locale],
  seen : Map[String, Bool],
  raw : String,
) -> Unit {
  match parse_locale(raw) {
    Some(locale) if seen.get(locale.tag) is None => {
      seen[locale.tag] = true
      target.push(locale)
    }
    _ => ()
  }
}

///|
/// Returns locale-related environment variable keys in precedence order.
fn locale_env_keys() -> Array[String] {
  ["LC_ALL", "LC_MESSAGES", "LANGUAGE", "LANG"]
}

///|
/// Appends locale-related environment variable values in precedence order.
fn append_env_locale_candidates(target : Array[String]) -> Unit {
  for key in locale_env_keys() {
    match @env.get_env_var(key) {
      Some(value) => push_candidate(target, value)
      None => ()
    }
  }
}

///|
/// Trims and stores a non-empty raw locale candidate.
fn push_candidate(target : Array[String], raw : String) -> Unit {
  let trimmed = raw.trim().to_string()
  if trimmed != "" {
    target.push(trimmed)
  }
}

///|
/// Splits a locale preference list on `:` and `,`.
fn split_locale_list(raw : String) -> Array[String] {
  let items : Array[String] = []
  let mut buf = StringBuilder::new(size_hint=raw.length())
  for ch in raw {
    if ch == ':' || ch == ',' {
      push_candidate(items, buf.to_string())
      buf = StringBuilder::new(size_hint=raw.length())
    } else {
      buf.write_char(ch)
    }
  }
  push_candidate(items, buf.to_string())
  items
}

///|
/// Parses a raw locale string into a normalized locale record.
fn parse_locale(raw : String) -> Locale? {
  let trimmed = raw.trim().to_string()
  if trimmed == "" {
    return None
  }
  let cleaned = strip_locale_suffixes(trimmed)
  if cleaned == "" || cleaned == "C" || cleaned == "POSIX" {
    return None
  }

  let subtags = split_nonempty(normalize_separators(cleaned), "-")
  if subtags.length() == 0 {
    return None
  }

  guard parse_language_subtag(subtags[0]) is Some(language) else { return None }
  let parts : Array[String] = [language]
  let mut index = 1

  let script = if index < subtags.length() {
    match parse_script_subtag(subtags[index]) {
      Some(value) => {
        index += 1
        parts.push(value)
        Some(value)
      }
      None => None
    }
  } else {
    None
  }

  let region = if index < subtags.length() {
    match parse_region_subtag(subtags[index]) {
      Some(value) => {
        index += 1
        parts.push(value)
        Some(value)
      }
      None => None
    }
  } else {
    None
  }

  for i in index..<subtags.length() {
    guard canonicalize_extra_subtag(subtags[i]) is Some(extra) else {
      return None
    }
    parts.push(extra)
  }

  Some(Locale::{ tag: join_subtags(parts), language, script, region })
}

///|
/// Removes quality, encoding, and modifier suffixes from a locale string.
fn strip_locale_suffixes(raw : String) -> String {
  strip_after(strip_after(strip_after(raw, ";"), "."), "@")
}

///|
/// Returns the prefix before the first marker.
fn strip_after(raw : String, marker : StringView) -> String {
  match raw.split_once(marker) {
    Some((prefix, _)) => prefix.to_string()
    None => raw
  }
}

///|
/// Replaces POSIX locale separators with BCP 47 separators.
fn normalize_separators(raw : String) -> String {
  let buf = StringBuilder::new(size_hint=raw.length())
  for ch in raw {
    if ch == '_' {
      buf.write_char('-')
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

///|
/// Splits a string and drops empty trimmed pieces.
fn split_nonempty(raw : String, sep : StringView) -> Array[String] {
  let parts : Array[String] = []
  for part in raw.split(sep) {
    push_candidate(parts, part.to_string())
  }
  parts
}

///|
/// Validates and normalizes a language subtag.
fn parse_language_subtag(raw : String) -> String? {
  if raw.length() < 2 || raw.length() > 8 || !is_ascii_alpha(raw) {
    None
  } else {
    Some(raw.to_lower())
  }
}

///|
/// Validates and normalizes a script subtag.
fn parse_script_subtag(raw : String) -> String? {
  if raw.length() != 4 || !is_ascii_alpha(raw) {
    None
  } else {
    Some(titlecase_ascii(raw))
  }
}

///|
/// Validates and normalizes a region subtag.
fn parse_region_subtag(raw : String) -> String? {
  if raw.length() == 2 && is_ascii_alpha(raw) {
    Some(raw.to_upper())
  } else if raw.length() == 3 && is_ascii_digit(raw) {
    Some(raw)
  } else {
    None
  }
}

///|
/// Validates and normalizes trailing variant subtags.
fn canonicalize_extra_subtag(raw : String) -> String? {
  if raw.length() == 0 || raw.length() > 8 || !is_ascii_alnum(raw) {
    None
  } else {
    Some(raw.to_lower())
  }
}

///|
/// Reports whether every character is ASCII alphabetic.
fn is_ascii_alpha(raw : String) -> Bool {
  if raw == "" {
    return false
  }
  for ch in raw {
    if !ch.is_ascii_alphabetic() {
      return false
    }
  }
  true
}

///|
/// Reports whether every character is an ASCII digit.
fn is_ascii_digit(raw : String) -> Bool {
  if raw == "" {
    return false
  }
  for ch in raw {
    if !ch.is_ascii_digit() {
      return false
    }
  }
  true
}

///|
/// Reports whether every character is ASCII alphanumeric.
fn is_ascii_alnum(raw : String) -> Bool {
  if raw == "" {
    return false
  }
  for ch in raw {
    if !(ch.is_ascii_alphabetic() || ch.is_ascii_digit()) {
      return false
    }
  }
  true
}

///|
/// Title-cases an ASCII script subtag.
fn titlecase_ascii(raw : String) -> String {
  let buf = StringBuilder::new(size_hint=raw.length())
  let mut is_first = true
  for ch in raw {
    if is_first {
      buf.write_char(ch.to_ascii_uppercase())
      is_first = false
    } else {
      buf.write_char(ch.to_ascii_lowercase())
    }
  }
  buf.to_string()
}

///|
/// Joins normalized subtags with `-`.
fn join_subtags(parts : Array[String]) -> String {
  if parts.length() == 0 {
    return ""
  }
  let buf = StringBuilder::new()
  for i in 0..<parts.length() {
    if i != 0 {
      buf.write_char('-')
    }
    buf.write_string(parts[i])
  }
  buf.to_string()
}
