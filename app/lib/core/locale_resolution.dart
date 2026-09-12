import 'package:flutter/widgets.dart';

/// The language the app shows for a given device locale (§3.10).
///
/// Extracted from the widget tree so the fallback is stated once and can be
/// tested: a phone set to a language the app does not have gets English rather
/// than whatever happens to sit first in the supported list. English is the
/// source language here, and the wider audience of the two.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  const fallback = Locale('en');
  if (device == null) return fallback;

  return supported.firstWhere(
    (locale) => locale.languageCode == device.languageCode,
    orElse: () => fallback,
  );
}
