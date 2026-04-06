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
/// Returns the highest-priority locale exposed by the current runtime.
///
/// The result is the first valid locale from `preferred()`, so it follows the
/// package's full discovery order: environment overrides such as `LC_ALL`,
/// `LC_MESSAGES`, `LANGUAGE`, and `LANG`, followed by the native system locale
/// when available.
///
/// The returned `Locale` is already normalized:
/// - separators use `-`
/// - language subtags are lowercase
/// - script subtags are title-cased
/// - region subtags are uppercase when alphabetic
///
/// # Returns
///
/// - `Some(locale)` when at least one preferred locale candidate can be parsed
/// - `None` when no candidate is available or every candidate is invalid
///
/// Example:
/// ```mbt check
/// test "current matches the first preferred locale" {
///   let current = @sys_locale.current()
///   let preferred = @sys_locale.preferred()
///   match current {
///     Some(locale) => {
///       assert_true(preferred.length() > 0)
///       assert_eq(preferred[0], locale)
///     }
///     None => assert_eq(preferred.length(), 0)
///   }
/// }
/// ```
pub fn current() -> Locale? {
  first_locale(preferred())
}

///|
/// Returns the normalized tag for the current locale.
///
/// This is the tag-only form of `current()`. Use it when callers only need the
/// canonical locale identifier and do not need the parsed `language`, `script`,
/// or `region` fields.
///
/// The returned tag uses the same normalization rules as `parse()`, such as
/// converting `en_US.UTF-8` into `en-US`.
///
/// # Returns
///
/// - `Some(tag)` when `current()` resolves to a valid locale
/// - `None` when no valid current locale can be discovered
///
/// Example:
/// ```mbt check
/// test "current_tag mirrors current" {
///   assert_eq(
///     @sys_locale.current_tag(),
///     match @sys_locale.current() {
///       Some(locale) => Some(locale.tag)
///       None => None
///     },
///   )
/// }
/// ```
pub fn current_tag() -> String? {
  locale_tag(current())
}

///|
/// Returns all preferred locales discovered from the current runtime.
///
/// Locale candidates are collected in this order:
/// - `LC_ALL`
/// - `LC_MESSAGES`
/// - `LANGUAGE`
/// - `LANG`
/// - the native system locale reported by the current platform
///
/// Each raw candidate is normalized before it is returned:
/// - whitespace is trimmed
/// - POSIX separators such as `_` are converted to `-`
/// - encoding, modifier, and quality suffixes after `.`, `@`, and `;` are removed
/// - duplicate locale tags are dropped while preserving first-seen order
///
/// # Returns
///
/// An array of normalized `Locale` values in preference order. The array may
/// be empty when no valid locale can be detected.
///
/// Example:
/// ```mbt check
/// test "preferred and preferred_tags stay aligned" {
///   let locales = @sys_locale.preferred()
///   let tags = @sys_locale.preferred_tags()
///   assert_eq(locales.length(), tags.length())
///   for i in 0..<locales.length() {
///     assert_eq(locales[i].tag, tags[i])
///   }
/// }
/// ```
pub fn preferred() -> Array[Locale] {
  locales_from_raw_candidates(locale_raw_candidates_internal())
}

///|
/// Returns the normalized tags for all preferred locales.
///
/// This is the tag-only form of `preferred()`. It keeps the same preference
/// order and deduplication rules, but returns only canonical locale tags
/// instead of full `Locale` records.
///
/// # Returns
///
/// An array of normalized locale tags, possibly empty when no valid locale can
/// be found.
///
/// Example:
/// ```mbt check
/// test "preferred_tags starts with current_tag when present" {
///   let tags = @sys_locale.preferred_tags()
///   match @sys_locale.current_tag() {
///     Some(tag) => {
///       assert_true(tags.length() > 0)
///       assert_eq(tags[0], tag)
///     }
///     None => ()
///   }
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
/// This parser accepts common POSIX-style locale strings such as
/// `en_US.UTF-8`, `zh_Hans_CN`, and `fr_FR@euro`, then normalizes them into a
/// BCP 47 style representation.
///
/// Normalization includes:
/// - trimming surrounding whitespace
/// - removing suffixes after `.`, `@`, and `;`
/// - converting `_` separators into `-`
/// - canonicalizing subtag casing
///
/// The parser rejects empty input, malformed subtags, and fallback locales
/// such as `C` and `POSIX`.
///
/// # Returns
///
/// - `Some(locale)` when the input can be normalized into a valid locale
/// - `None` when the input is empty, unsupported, or malformed
///
/// Example:
/// ```mbt check
/// test "parse normalizes locale strings" {
///   inspect(
///     @sys_locale.parse("zh_Hans_CN.UTF-8"),
///     content="Some({tag: \"zh-Hans-CN\", language: \"zh\", script: Some(\"Hans\"), region: Some(\"CN\")})",
///   )
///   inspect(@sys_locale.parse("C.UTF-8"), content="None")
/// }
/// ```
pub fn parse(raw : String) -> Locale? {
  parse_locale(raw)
}

///|
/// Returns the canonical locale tag for a raw locale string.
///
/// This convenience wrapper around `parse()` keeps only the normalized tag,
/// which is useful when callers do not need the structured `Locale` record.
///
/// It follows the same acceptance and rejection rules as `parse()`, so invalid
/// or unsupported locale strings still return `None`.
///
/// # Returns
///
/// - `Some(tag)` when `raw` can be normalized into a valid locale tag
/// - `None` when `raw` is empty, unsupported, or malformed
///
/// Example:
/// ```mbt check
/// test "canonicalize returns normalized tags" {
///   inspect(@sys_locale.canonicalize("en_US.UTF-8"), content="Some(\"en-US\")")
///   inspect(@sys_locale.canonicalize("fr_FR@euro"), content="Some(\"fr-FR\")")
/// }
/// ```
pub fn canonicalize(raw : String) -> String? {
  locale_tag(parse(raw))
}
