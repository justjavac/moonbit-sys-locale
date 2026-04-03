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
  let key_pairs = [
    ("LC_ALL", @env.get_env_var("LC_ALL")),
    ("LC_MESSAGES", @env.get_env_var("LC_MESSAGES")),
    ("LANGUAGE", @env.get_env_var("LANGUAGE")),
    ("LANG", @env.get_env_var("LANG")),
  ]

  @env.set_env_var("LC_ALL", "de_DE.UTF-8")
  @env.set_env_var("LC_MESSAGES", "it_IT.UTF-8")
  @env.set_env_var("LANGUAGE", "fr_FR:en_US.UTF-8")
  @env.set_env_var("LANG", "ja_JP.UTF-8")

  let tags = @sys_locale.preferred_tags()
  assert_true(tags.length() >= 5)
  assert_eq(tags[0], "de-DE")
  assert_eq(tags[1], "it-IT")
  assert_eq(tags[2], "fr-FR")
  assert_eq(tags[3], "en-US")
  assert_eq(tags[4], "ja-JP")
  inspect(@sys_locale.current_tag(), content="Some(\"de-DE\")")

  for pair in key_pairs {
    let (key, value) = pair
    match value {
      Some(existing) => @env.set_env_var(key, existing)
      None => @env.unset_env_var(key)
    }
  }
}
