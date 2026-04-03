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
fn first_locale(locales : Array[Locale]) -> Locale? {
  if locales.length() == 0 {
    None
  } else {
    Some(locales[0])
  }
}

///|
fn locale_tag(locale : Locale?) -> String? {
  match locale {
    Some(locale) => Some(locale.tag)
    None => None
  }
}

///|
/// Returns the current locale, if the platform exposes one.
pub fn current() -> Locale? {
  first_locale(preferred())
}

///|
/// Returns the normalized tag for the current locale.
pub fn current_tag() -> String? {
  locale_tag(current())
}

///|
/// Returns all preferred locales discovered from the current runtime.
///
/// Duplicates are removed after normalization, while preserving the original
/// preference order.
pub fn preferred() -> Array[Locale] {
  locales_from_raw_candidates(locale_raw_candidates_internal())
}

///|
/// Returns the normalized tags for all preferred locales.
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
/// BCP 47 style tag like `en-US`.
pub fn parse(raw : String) -> Locale? {
  parse_locale(raw)
}

///|
/// Returns the canonical locale tag for a raw locale string.
pub fn canonicalize(raw : String) -> String? {
  locale_tag(parse(raw))
}
