///|
/// Captures the current locale-related environment variables.
fn locale_env_snapshot() -> Array[(String, String?)] {
  let snapshot : Array[(String, String?)] = []
  for key in ["LC_ALL", "LC_MESSAGES", "LANGUAGE", "LANG"] {
    snapshot.push((key, @env.get_env_var(key)))
  }
  snapshot
}

///|
/// Applies locale-related environment variable overrides.
fn apply_locale_env(entries : Array[(String, String?)]) -> Unit {
  for pair in entries {
    let (key, value) = pair
    match value {
      Some(existing) => @env.set_env_var(key, existing)
      None => @env.unset_env_var(key)
    }
  }
}

///|
/// Runs a callback with locale-related environment variables temporarily set.
fn with_locale_env(
  entries : Array[(String, String?)],
  f : () -> Unit raise,
) -> Unit raise {
  let snapshot = locale_env_snapshot()
  apply_locale_env(entries)
  try f() catch {
    e => {
      apply_locale_env(snapshot)
      raise e
    }
  } noraise {
    _ => apply_locale_env(snapshot)
  }
}

///|
/// Asserts that the actual tags begin with the expected tags.
fn assert_locale_tag_prefix(
  actual : Array[String],
  expected : Array[String],
) -> Unit raise {
  assert_true(actual.length() >= expected.length())
  for i in 0..<expected.length() {
    assert_eq(actual[i], expected[i])
  }
}

///|
test "parse normalizes POSIX locales" {
  inspect(
    @sys_locale.parse("en_US.UTF-8"),
    content="Some({tag: \"en-US\", language: \"en\", script: None, region: Some(\"US\")})",
  )
  inspect(
    @sys_locale.parse("zh_Hans_CN"),
    content="Some({tag: \"zh-Hans-CN\", language: \"zh\", script: Some(\"Hans\"), region: Some(\"CN\")})",
  )
}

///|
test "parse strips modifiers and quality values" {
  inspect(@sys_locale.canonicalize("fr_FR@euro"), content="Some(\"fr-FR\")")
  inspect(@sys_locale.canonicalize("en-US;q=0.8"), content="Some(\"en-US\")")
}

///|
test "parse rejects empty or fallback C locales" {
  inspect(@sys_locale.parse(""), content="None")
  inspect(@sys_locale.parse("C.UTF-8"), content="None")
  inspect(@sys_locale.parse(" POSIX "), content="None")
}

///|
test "preferred uses environment overrides first" {
  with_locale_env(
    [
      ("LC_ALL", Some("de_DE.UTF-8")),
      ("LC_MESSAGES", Some("it_IT.UTF-8")),
      ("LANGUAGE", Some("fr_FR:en_US.UTF-8")),
      ("LANG", Some("ja_JP.UTF-8")),
    ],
    fn() raise {
      let tags = @sys_locale.preferred_tags()
      assert_locale_tag_prefix(tags, [
        "de-DE", "it-IT", "fr-FR", "en-US", "ja-JP",
      ])
      inspect(@sys_locale.current_tag(), content="Some(\"de-DE\")")
    },
  )
}
