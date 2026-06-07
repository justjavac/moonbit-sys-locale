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
  @test.assert_eq(first_locale(locales), None)
  @test.assert_eq(locale_tag(None), None)
  debug_inspect(
    locale_tag(
      Some({ tag: "en-US", language: "en", script: None, region: Some("US") }),
    ),
    content="Some(\"en-US\")",
  )
}

///|
test "parse accepts bare language numeric region and variants" {
  debug_inspect(
    parse_locale("en"),
    content=(
      #|Some({ tag: "en", language: "en", script: None, region: None })
    ),
  )
  debug_inspect(
    parse_locale("es-419"),
    content=(
      #|Some({ tag: "es-419", language: "es", script: None, region: Some("419") })
    ),
  )
  debug_inspect(
    parse_locale("de-CH-1901"),
    content=(
      #|Some(
      #|  {
      #|    tag: "de-CH-1901",
      #|    language: "de",
      #|    script: None,
      #|    region: Some("CH"),
      #|  },
      #|)
    ),
  )
  debug_inspect(
    parse_locale("sl-rozaj-biske"),
    content=(
      #|Some({ tag: "sl-rozaj-biske", language: "sl", script: None, region: None })
    ),
  )
}

///|
test "parse rejects malformed locale pieces" {
  debug_inspect(parse_locale("___"), content="None")
  debug_inspect(parse_locale("1n-US"), content="None")
  debug_inspect(parse_locale("en-US-a!"), content="None")
}

///|
test "parsing helpers cover separator and candidate edge cases" {
  let target : Array[String] = []
  push_candidate(target, "   ")
  @test.assert_eq(target.length(), 0)

  let locales = locales_from_raw_candidates([
    "", "C", "POSIX", "en_US.UTF-8,en_US", "fr_FR:de_DE",
  ])
  @test.assert_eq(locales.length(), 3)
  @test.assert_eq(locales[0].tag, "en-US")
  @test.assert_eq(locales[1].tag, "fr-FR")
  @test.assert_eq(locales[2].tag, "de-DE")

  @test.assert_eq(split_locale_list("en_US, , fr_FR:ja_JP"), [
    "en_US", "fr_FR", "ja_JP",
  ])
  @test.assert_eq(strip_after("en-US;q=0.8", ";"), "en-US")
  @test.assert_eq(normalize_separators("zh_Hans_CN"), "zh-Hans-CN")
  @test.assert_eq(split_nonempty("-en--US-", "-"), ["en", "US"])
}

///|
test "subtag validators cover failure branches" {
  @test.assert_eq(parse_language_subtag("englishx"), Some("englishx"))
  @test.assert_eq(parse_language_subtag("e"), None)
  @test.assert_eq(parse_script_subtag("latn"), Some("Latn"))
  @test.assert_eq(parse_script_subtag("lat"), None)
  @test.assert_eq(parse_region_subtag("US"), Some("US"))
  @test.assert_eq(parse_region_subtag("419"), Some("419"))
  @test.assert_eq(parse_region_subtag("USA1"), None)
  @test.assert_eq(canonicalize_extra_subtag("oxendict"), Some("oxendict"))
  @test.assert_eq(canonicalize_extra_subtag("toolong09"), None)

  @test.assert_eq(is_ascii_alpha("AbCd"), true)
  @test.assert_eq(is_ascii_alpha("ab1"), false)
  @test.assert_eq(is_ascii_alpha(""), false)
  @test.assert_eq(is_ascii_digit("419"), true)
  @test.assert_eq(is_ascii_digit("41a"), false)
  @test.assert_eq(is_ascii_digit(""), false)
  @test.assert_eq(is_ascii_alnum("a1b2"), true)
  @test.assert_eq(is_ascii_alnum("a-1"), false)
  @test.assert_eq(is_ascii_alnum(""), false)
  @test.assert_eq(titlecase_ascii("hANS"), "Hans")

  let empty_parts : Array[String] = []
  @test.assert_eq(join_subtags(empty_parts), "")
  @test.assert_eq(join_subtags(["zh", "Hans", "CN"]), "zh-Hans-CN")
}

///|
test "environment and native helpers cover none branches" {
  with_locale_env_cleared(fn() raise {
    let env_candidates : Array[String] = []
    append_env_locale_candidates(env_candidates)
    @test.assert_eq(env_candidates.length(), 0)
  })

  let target : Array[String] = []
  append_optional_locale_candidate(target, None)
  @test.assert_eq(target.length(), 0)
  append_optional_locale_candidate(target, Some(" fr_FR.UTF-8 "))
  @test.assert_eq(target, ["fr_FR.UTF-8"])

  let valid_utf8 : Bytes = Bytes::from_array([b'\xE4', b'\xB8', b'\xAD'])
  @test.assert_eq(
    decode_native_system_locale(valid_utf8, 3),
    Some(@utf8.decode(valid_utf8)),
  )
  @test.assert_eq(decode_native_system_locale(valid_utf8, 4), None)
  debug_inspect(decode_native_system_locale(valid_utf8, 0), content="None")
  debug_inspect(
    decode_native_system_locale(Bytes::from_array([b'\xFF']), 1),
    content="None",
  )
}

///|
test "native buffer helpers cover retry decisions" {
  @test.assert_eq(native_locale_initial_buffer_size(), 128)
  @test.assert_eq(native_locale_max_buffer_size(), 4096)

  @test.assert_eq(next_native_locale_buffer_capacity(8, 7), None)
  @test.assert_eq(next_native_locale_buffer_capacity(8, 8), Some(16))
  @test.assert_eq(
    next_native_locale_buffer_capacity(
      native_locale_max_buffer_size(),
      native_locale_max_buffer_size(),
    ),
    None,
  )

  match read_native_system_locale_with_capacity(1) {
    Some(locale) => assert_true(locale != "")
    None => ()
  }
}
