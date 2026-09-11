import 'package:flutter/material.dart';

/// Enlightened green and Resistance blue (§3.9).
///
/// Chosen to stay legible on both a light and a dark surface rather than to
/// match the game's own neon exactly: these end up behind text, and the pure
/// in-game green fails contrast on white.
const enlightenedColour = Color(0xFF2FBF71);
const resistanceColour = Color(0xFF3E8FE0);

/// The colour of a faction as the export spells it, or null when the app does
/// not recognise it.
///
/// Null rather than a default, so each caller picks its own fallback — and so
/// an unknown faction is never quietly painted as one of the two. Fan-made
/// exports have carried invented factions before.
Color? factionColour(String faction) => switch (faction.trim().toLowerCase()) {
      'enlightened' => enlightenedColour,
      'resistance' => resistanceColour,
      _ => null,
    };
