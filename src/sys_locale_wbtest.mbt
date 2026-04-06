///|
/// Captures the current locale-related environment variables.
fn locale_env_snapshot() -> Array[(String, String?)] {
  let snapshot : Array[(String, String?)] = []
  for key in locale_env_keys() {
    snapshot.push((key, @env.get_env_var(key)))
  }
  snapshot
}

///|
/// Restores locale-related environment variables from a snapshot.
fn restore_locale_env(snapshot : Array[(String, String?)]) -> Unit {
  for pair in snapshot {
    let (key, value) = pair
    match value {
      Some(existing) => @env.set_env_var(key, existing)
      None => @env.unset_env_var(key)
    }
  }
}

///|
/// Clears locale-related environment variables.
fn clear_locale_env() -> Unit {
  for key in locale_env_keys() {
    @env.unset_env_var(key)
  }
}

///|
/// Runs a callback with locale-related env vars temporarily cleared.
fn with_locale_env_cleared(f : () -> Unit raise) -> Unit raise {
  let snapshot = locale_env_snapshot()
  clear_locale_env()
  try f() catch {
    e => {
      restore_locale_env(snapshot)
      raise e
    }
  } noraise {
    _ => restore_locale_env(snapshot)
  }
}

///|
test "locale helpers cover none cases" {
  let locales : Array[Locale] = []
  assert_eq(first_locale(locales), None)
  assert_eq(locale_tag(None), None)
  inspect(
    locale_tag(
      Some(Locale::{
        tag: "en-US",
        language: "en",
        script: None,
        region: Some("US"),
      }),
    ),
    content="Some(\"en-US\")",
  )
}

///|
test "parse accepts bare language numeric region and variants" {
  inspect(
    parse_locale("en"),
    content="Some({tag: \"en\", language: \"en\", script: None, region: None})",
  )
  inspect(
    parse_locale("es-419"),
    content="Some({tag: \"es-419\", language: \"es\", script: None, region: Some(\"419\")})",
  )
  inspect(
    parse_locale("de-CH-1901"),
    content="Some({tag: \"de-CH-1901\", language: \"de\", script: None, region: Some(\"CH\")})",
  )
  inspect(
    parse_locale("sl-rozaj-biske"),
    content="Some({tag: \"sl-rozaj-biske\", language: \"sl\", script: None, region: None})",
  )
}

///|
test "parse rejects malformed locale pieces" {
  inspect(parse_locale("___"), content="None")
  inspect(parse_locale("1n-US"), content="None")
  inspect(parse_locale("en-US-a!"), content="None")
}

///|
test "parsing helpers cover separator and candidate edge cases" {
  let target : Array[String] = []
  push_candidate(target, "   ")
  assert_eq(target.length(), 0)

  let locales = locales_from_raw_candidates([
    "", "C", "POSIX", "en_US.UTF-8,en_US", "fr_FR:de_DE",
  ])
  assert_eq(locales.length(), 3)
  assert_eq(locales[0].tag, "en-US")
  assert_eq(locales[1].tag, "fr-FR")
  assert_eq(locales[2].tag, "de-DE")

  assert_eq(split_locale_list("en_US, , fr_FR:ja_JP"), [
    "en_US", "fr_FR", "ja_JP",
  ])
  assert_eq(strip_after("en-US;q=0.8", ";"), "en-US")
  assert_eq(normalize_separators("zh_Hans_CN"), "zh-Hans-CN")
  assert_eq(split_nonempty("-en--US-", "-"), ["en", "US"])
}

///|
test "subtag validators cover failure branches" {
  assert_eq(parse_language_subtag("englishx"), Some("englishx"))
  assert_eq(parse_language_subtag("e"), None)
  assert_eq(parse_script_subtag("latn"), Some("Latn"))
  assert_eq(parse_script_subtag("lat"), None)
  assert_eq(parse_region_subtag("US"), Some("US"))
  assert_eq(parse_region_subtag("419"), Some("419"))
  assert_eq(parse_region_subtag("USA1"), None)
  assert_eq(canonicalize_extra_subtag("oxendict"), Some("oxendict"))
  assert_eq(canonicalize_extra_subtag("toolong09"), None)

  assert_eq(is_ascii_alpha("AbCd"), true)
  assert_eq(is_ascii_alpha("ab1"), false)
  assert_eq(is_ascii_alpha(""), false)
  assert_eq(is_ascii_digit("419"), true)
  assert_eq(is_ascii_digit("41a"), false)
  assert_eq(is_ascii_digit(""), false)
  assert_eq(is_ascii_alnum("a1b2"), true)
  assert_eq(is_ascii_alnum("a-1"), false)
  assert_eq(is_ascii_alnum(""), false)
  assert_eq(titlecase_ascii("hANS"), "Hans")

  let empty_parts : Array[String] = []
  assert_eq(join_subtags(empty_parts), "")
  assert_eq(join_subtags(["zh", "Hans", "CN"]), "zh-Hans-CN")
}

///|
test "environment and native helpers cover none branches" {
  with_locale_env_cleared(fn() raise {
    let env_candidates : Array[String] = []
    append_env_locale_candidates(env_candidates)
    assert_eq(env_candidates.length(), 0)
  })

  let target : Array[String] = []
  append_optional_locale_candidate(target, None)
  assert_eq(target.length(), 0)
  append_optional_locale_candidate(target, Some(" fr_FR.UTF-8 "))
  assert_eq(target, ["fr_FR.UTF-8"])

  let valid_utf8 : Bytes = Bytes::from_array([b'\xE4', b'\xB8', b'\xAD'])
  assert_eq(
    decode_native_system_locale(valid_utf8, 3),
    Some(@utf8.decode(valid_utf8)),
  )
  inspect(decode_native_system_locale(valid_utf8, 0), content="None")
  inspect(
    decode_native_system_locale(Bytes::from_array([b'\xFF']), 1),
    content="None",
  )
}
