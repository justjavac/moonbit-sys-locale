///|
/// A normalized system locale tag.
///
/// The `tag` field keeps the canonicalized locale identifier, while the other
/// fields expose the most common structured pieces for MoonBit code.
pub struct Locale {
  tag : String
  language : String
  script : String?
  region : String?
} derive(Eq, Show)

///|
/// Returns the first locale from a non-empty list.
fn first_locale(locales : Array[Locale]) -> Locale? {
  if locales.length() == 0 {
    None
  } else {
    Some(locales[0])
  }
}

///|
/// Extracts the normalized tag from an optional locale.
fn locale_tag(locale : Locale?) -> String? {
  match locale {
    Some(locale) => Some(locale.tag)
    None => None
  }
}

///|
/// Returns the first preferred locale exposed by the current runtime.
///
/// This is equivalent to taking the first element from `preferred()`, while
/// keeping the common single-locale lookup easy to read.
///
/// Example:
/// ```
/// let current = @sys_locale.current()
/// let preferred = @sys_locale.preferred()
/// match current {
///   Some(locale) => {
///     assert_true(preferred.length() > 0)
///     assert_eq(preferred[0], locale)
///   }
///   None => assert_eq(preferred.length(), 0)
/// }
/// ```
pub fn current() -> Locale? {
  first_locale(preferred())
}

///|
/// Returns the normalized tag for the current locale.
///
/// This helper is useful when only the canonical locale identifier is needed
/// and the structured `Locale` fields are not required.
///
/// Example:
/// ```
/// assert_eq(
///   @sys_locale.current_tag(),
///   match @sys_locale.current() {
///     Some(locale) => Some(locale.tag)
///     None => None
///   },
/// )
/// ```
pub fn current_tag() -> String? {
  locale_tag(current())
}

///|
/// Returns all preferred locales discovered from the current runtime.
///
/// Locale values can come from environment overrides such as `LC_ALL` and
/// `LANGUAGE`, plus the native system locale when available. Duplicates are
/// removed after normalization while preserving preference order.
///
/// Example:
/// ```
/// let locales = @sys_locale.preferred()
/// let tags = @sys_locale.preferred_tags()
/// assert_eq(locales.length(), tags.length())
/// for i in 0..<locales.length() {
///   assert_eq(locales[i].tag, tags[i])
/// }
/// ```
pub fn preferred() -> Array[Locale] {
  locales_from_raw_candidates(locale_raw_candidates_internal())
}

///|
/// Returns the normalized tags for all preferred locales.
///
/// This is the tag-only form of `preferred()`, useful when consumers only need
/// canonical locale identifiers.
///
/// Example:
/// ```
/// let tags = @sys_locale.preferred_tags()
/// match @sys_locale.current_tag() {
///   Some(tag) => {
///     assert_true(tags.length() > 0)
///     assert_eq(tags[0], tag)
///   }
///   None => ()
/// }
/// ```
pub fn preferred_tags() -> Array[String] {
  let tags : Array[String] = []
  for locale in preferred() {
    tags.push(locale.tag)
  }
  tags
}

///|
/// Parses a raw locale string into a normalized `Locale`.
///
/// Common POSIX forms such as `en_US.UTF-8` are accepted and normalized to a
/// BCP 47 style tag like `en-US`. Empty input, malformed subtags, and fallback
/// locales such as `C` and `POSIX` return `None`.
///
/// Example:
/// ```
/// inspect(
///   @sys_locale.parse("zh_Hans_CN.UTF-8"),
///   content="Some({tag: \"zh-Hans-CN\", language: \"zh\", script: Some(\"Hans\"), region: Some(\"CN\")})",
/// )
/// inspect(@sys_locale.parse("C.UTF-8"), content="None")
/// ```
pub fn parse(raw : String) -> Locale? {
  parse_locale(raw)
}

///|
/// Returns the canonical locale tag for a raw locale string.
///
/// This is a convenience wrapper around `parse()` when only the normalized tag
/// string is needed.
///
/// Example:
/// ```
/// inspect(@sys_locale.canonicalize("en_US.UTF-8"), content="Some(\"en-US\")")
/// inspect(@sys_locale.canonicalize("fr_FR@euro"), content="Some(\"fr-FR\")")
/// ```
pub fn canonicalize(raw : String) -> String? {
  locale_tag(parse(raw))
}
