// ENCODING tests for the localisation resources (#70).
//
// A "Support the project" line shipped reading "Nothing is expected â.. but a
// coffee is always welcome": an em dash whose three UTF-8 bytes had each been
// read as Latin-1 and re-encoded, leaving an a-circumflex followed by two
// control characters that Android draws as tofu. Nothing in the pipeline
// noticed — the file was valid UTF-8, valid JSON, and the string was never
// compared against anything.
//
// So the check lives here. It runs on every `flutter test`, needs no CI
// wiring, and covers the whole localisation layer rather than the two strings
// that happened to be spotted by eye.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _l10nDirectory = 'lib/l10n';

/// Where mojibake was found: the file, the line, and the text around it.
class Sighting {
  const Sighting({required this.file, required this.line, required this.text});

  final String file;
  final int line;
  final String text;

  @override
  String toString() => '$file:$line — $text';
}

/// True for the C1 block, U+0080..U+009F.
///
/// These have no printable form and no business being in a user-facing
/// string. Every "smart" punctuation character — em dash, curly quotes,
/// ellipsis — begins E2 80 in UTF-8, so double-encoding any of them leaves one
/// of these behind. That makes a C1 control the single most reliable tell.
bool _isC1(int rune) => rune >= 0x80 && rune <= 0x9F;

/// True for the two mojibake heads, followed by a Latin-1 tail.
///
/// The other family: a double-encoded accented letter (é becomes two
/// characters starting U+00C3) or a non-breaking space (U+00C2) leaves no
/// control character behind, so the C1 rule alone would miss it. Neither of
/// those two characters occurs in French or English, let alone before one in
/// this range, so this cannot fire on real text.
bool _isMojibakeHead(int rune, int? next) =>
    (rune == 0xC3 || rune == 0xC2) &&
    next != null &&
    next >= 0x80 &&
    next <= 0xBF;

/// Prints a run of text with anything unprintable escaped, so the failure
/// message survives a terminal that would otherwise swallow it.
String readable(String text) => text.replaceAllMapped(
      RegExp(r'[\u0000-\u001f\u007f-\u009f]'),
      (m) => '\\u${m[0]!.runes.first.toRadixString(16).padLeft(4, '0')}',
    );

List<Sighting> _scan(File file) {
  final found = <Sighting>[];
  final lines = file.readAsLinesSync();

  for (var i = 0; i < lines.length; i++) {
    final runes = lines[i].runes.toList();
    for (var r = 0; r < runes.length; r++) {
      final next = r + 1 < runes.length ? runes[r + 1] : null;
      if (!_isC1(runes[r]) && !_isMojibakeHead(runes[r], next)) continue;

      final from = (r - 30).clamp(0, runes.length);
      final to = (r + 20).clamp(0, runes.length);
      found.add(Sighting(
        file: file.path,
        line: i + 1,
        text: readable(String.fromCharCodes(runes.sublist(from, to))),
      ));
      break; // One sighting per line is enough to point at it.
    }
  }
  return found;
}

void main() {
  final files = Directory(_l10nDirectory)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') || f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  group('the localisation resources are cleanly encoded (#70)', () {
    test('there is something to scan', () {
      // Guards the test below: an empty list would make it pass for the wrong
      // reason if the directory or its naming ever moved.
      expect(
        files.map((f) => f.path),
        containsAll([
          '$_l10nDirectory/app_en.arb',
          '$_l10nDirectory/app_fr.arb',
        ]),
      );
      expect(files.length, greaterThan(2));
    });

    test('no string carries double-encoded UTF-8', () {
      final sightings = [for (final file in files) ..._scan(file)];

      expect(
        sightings,
        isEmpty,
        reason: 'mojibake, most likely text pasted through a Latin-1 step:\n'
            '${sightings.join('\n')}',
      );
    });

    test('the em dashes that were mangled are real em dashes now', () {
      // The two strings from the bug report, pinned by value. The scan proves
      // the absence of a pattern; this proves the presence of the right one.
      final english = File('$_l10nDirectory/app_en.arb').readAsStringSync();
      expect(english, contains('Nothing is expected — but a coffee'));
      expect(english, contains('Only one snapshot so far — no progress'));
    });
  });
}
