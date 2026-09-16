// Renders the badge emblems (#63) to a contact sheet, light and dark, at both
// the size they appear at in the counter list and four times that.
//
//     cd app && flutter test tool/medal_sheet_test.dart
//
// The sheet lands in `build/design/` and is not committed: the emblems live in
// `lib/presentation/widgets/medal_icon.dart` and nowhere else, so a picture in
// the repository could only ever go stale behind them. Regenerate it when
// adding or reworking an emblem — the list size is where two silhouettes that
// looked distinct at 72 px turn out to be the same drawing.
//
// A test file rather than a script because a CustomPainter needs a Flutter
// engine to paint into, and `flutter test` is the only way to get one without
// a device. It sits under `tool/` so a bare `flutter test`, which walks `test/`
// alone, leaves it out of CI.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fieldtally/presentation/widgets/medal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every tier, plus the unearned case that opens each row.
const _tiers = <String?>[null, 'bronze', 'silver', 'gold', 'platinum', 'onyx'];

const _outDir = 'build/design';

Future<void> _sheet(WidgetTester tester, Brightness brightness) async {
  final keys = MedalIcon.emblemKeys.toList()..sort();
  final boundary = GlobalKey();

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      home: RepaintBoundary(
        key: boundary,
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final key in keys)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            key,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        for (final tier in _tiers) ...[
                          MedalIcon(counterKey: key, tierName: tier),
                          const SizedBox(width: 8),
                          MedalIcon(counterKey: key, tierName: tier, size: 64),
                          const SizedBox(width: 18),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await render.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  // Without this the next toImage in the same test never completes.
  image.dispose();

  Directory(_outDir).createSync(recursive: true);
  final file = File('$_outDir/medals-${brightness.name}.png');
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote ${file.absolute.path}');
}

void main() {
  testWidgets(
    'contact sheet',
    (tester) async {
      // Sized from the emblem count rather than pinned, so that drawing the
      // next one does not silently overflow the sheet by a row. It did: adding
      // the eighteenth pushed a fixed 1500 over by 28 pixels, and the striped
      // overflow band lands on the very thing the sheet exists to judge.
      tester.view.physicalSize = Size(
        1000,
        240 + MedalIcon.emblemKeys.length * 76,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final brightness in Brightness.values) {
        await _sheet(tester, brightness);
      }
    },
    // `flutter test` renders in software, and a sheet this size takes
    // minutes rather than seconds under it. Generous on purpose: the default
    // ten minutes is not always enough for the two of them.
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
