import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The metals, one per registry tier key (§3.6, #63).
///
/// Tuned by hand rather than taken from the colour scheme: these have to read
/// as bronze, silver, gold, platinum and onyx on both themes, and a generated
/// palette has no opinion about what silver looks like. Onyx is the exception
/// that proves the rule — as the top tier it fills solid, because a scheme
/// that made the prize the palest of the five would say the opposite of the
/// truth.
class MedalMetal {
  const MedalMetal({required this.rim, required this.solid});

  final Color rim;

  /// Filled edge to edge rather than tinted, with a light glyph on top.
  final bool solid;

  static const _light = {
    'bronze': MedalMetal(rim: Color(0xFFA0703F), solid: false),
    'silver': MedalMetal(rim: Color(0xFF8E979F), solid: false),
    'gold': MedalMetal(rim: Color(0xFFC69320), solid: false),
    'platinum': MedalMetal(rim: Color(0xFF3E9E97), solid: false),
    'onyx': MedalMetal(rim: Color(0xFF33383D), solid: true),
  };

  static const _dark = {
    'bronze': MedalMetal(rim: Color(0xFFC08B52), solid: false),
    'silver': MedalMetal(rim: Color(0xFFAAB4BC), solid: false),
    'gold': MedalMetal(rim: Color(0xFFDCA92C), solid: false),
    'platinum': MedalMetal(rim: Color(0xFF57BDB5), solid: false),
    'onyx': MedalMetal(rim: Color(0xFFC9CFD5), solid: true),
  };

  /// Null for a tier the registry names but this app has no metal for — the
  /// medal then draws in the unearned style rather than guessing a colour.
  static MedalMetal? of(String? tierName, Brightness brightness) =>
      tierName == null
      ? null
      : (brightness == Brightness.dark ? _dark : _light)[tierName];
}

/// The colours a medal is drawn with, for a surface that does not follow the
/// app theme.
///
/// The shareable card (§3.8) carries its own palette on purpose — an image
/// posted to Reddit should not come out washed out because its author happened
/// to be in light mode — so it cannot let the emblem read the theme the way
/// every other caller does.
class MedalPalette {
  const MedalPalette({
    required this.brightness,
    required this.unearned,
    required this.ink,
    required this.onSolid,
  });

  /// Which set of metals to take: they are tuned separately for a light and a
  /// dark ground.
  final Brightness brightness;

  /// The rim of a medal not reached yet.
  final Color unearned;

  /// The glyph, on a tinted medal.
  final Color ink;

  /// The glyph, on a solid one — onyx.
  final Color onSolid;
}

/// How a medal's rim is drawn — what kind of ladder it belongs to (#99).
///
/// The classification sits on the rim rather than in the glyph on purpose. At
/// list size the glyph has about seventeen pixels to say what a counter
/// measures; it has none to spare for saying what family the medal belongs to.
/// The rim is drawn once, outside the glyph's square, so a variant costs no
/// space at all and composes with every tier.
enum MedalRim {
  /// A badge that can always be earned: one unbroken ring.
  permanent,

  /// A ladder that stops being earnable — an anomaly medal. The ring breaks
  /// into four arcs. It says "this one closes" without symbolising anything,
  /// and at list size the eye still reads a ring.
  anomaly,

  /// The same broken ring, with a stud seated in the gap at twelve o'clock:
  /// the Global Op of a season's pair, as against its Season medal.
  anomalyGlobalOp,
}

/// The medal for a counter that has badge thresholds (#63).
///
/// Deliberately drawn rather than shipped as assets: seventeen shapes of
/// straight lines and circles cost less as paths than as a dependency, and
/// they inherit the theme instead of carrying baked-in colours.
///
/// Emblems of the project's own making. They say what the counter measures —
/// a route, a link, a place, a scan — and none of them derives from Niantic's
/// artwork, which is the whole reason this exists rather than a download.
class MedalIcon extends StatelessWidget {
  const MedalIcon({
    super.key,
    required this.counterKey,
    required this.tierName,
    this.size = 28,
    this.palette,
  });

  /// Registry key (`explorer`, `hacker`), not the export header.
  final String counterKey;

  /// Tier reached, or null when the first threshold is still ahead.
  final String? tierName;

  final double size;

  /// Colours to draw with. Null — the usual case — takes them from the theme,
  /// so the emblem follows the app the way everything else does.
  final MedalPalette? palette;

  /// Whether an emblem exists for this counter. A counter with thresholds but
  /// no drawing must not render a bare ring — better nothing at all.
  static bool existsFor(String counterKey) => _glyphs.containsKey(counterKey);

  /// How this counter's emblem is rimmed.
  ///
  /// Public for the same reason as [emblemKeys]: `medal_icon_test` checks it
  /// against the registry's own `ends_at`, which is the only thing keeping the
  /// drawing and the data from drifting apart.
  static MedalRim rimFor(String counterKey) =>
      _anomalyGlobalOpEmblems.contains(counterKey)
      ? MedalRim.anomalyGlobalOp
      : _anomalyEmblems.contains(counterKey)
      ? MedalRim.anomaly
      : MedalRim.permanent;

  /// Every counter an emblem is drawn for.
  ///
  /// Public so the coverage test can check this list against the registry in
  /// both directions, and so `tool/medal_sheet_test.dart` can draw the sheet
  /// without repeating it.
  static Iterable<String> get emblemKeys => _glyphs.keys;

  @override
  Widget build(BuildContext context) {
    final glyph = _glyphs[counterKey];
    if (glyph == null) return SizedBox.square(dimension: size);

    final theme = Theme.of(context);
    final colours =
        palette ??
        MedalPalette(
          brightness: theme.brightness,
          // Unearned: the medal exists, the agent is not there yet.
          unearned: theme.colorScheme.outlineVariant,
          ink: theme.colorScheme.onSurface,
          onSolid: theme.colorScheme.surface,
        );

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedalPainter(
          glyph: glyph,
          rim: rimFor(counterKey),
          metal: MedalMetal.of(tierName, colours.brightness),
          unearned: colours.unearned,
          ink: colours.ink,
          onSolid: colours.onSolid,
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({
    required this.glyph,
    required this.rim,
    required this.metal,
    required this.unearned,
    required this.ink,
    required this.onSolid,
  });

  final void Function(Canvas, Paint fill, Paint stroke) glyph;
  final MedalRim rim;
  final MedalMetal? metal;
  final Color unearned;
  final Color ink;
  final Color onSolid;

  /// Everything is drawn in a 24-unit square and scaled, so one set of
  /// coordinates serves every size.
  static const _grid = 24.0;
  static const _radius = 10.1;

  /// One ring, or four arcs and possibly a stud — see [MedalRim].
  ///
  /// The gaps are narrow on purpose: wide enough that the ring reads as broken
  /// at twenty-eight pixels, narrow enough that it still reads as a ring. The
  /// Global Op stud gets a wider gap to sit in, because at list size a smaller
  /// one disappeared into the rim entirely.
  void _drawRim(Canvas canvas, Offset centre, Color colour) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (rim == MedalRim.permanent) {
      canvas.drawCircle(centre, _radius, paint);
      return;
    }

    const gap = 0.30; // radians
    const quarter = math.pi / 2;
    final top = rim == MedalRim.anomalyGlobalOp ? 0.62 : gap;
    for (var k = 0; k < 4; k++) {
      // Arc k starts at twelve o'clock plus k quarter-turns, so the gap at the
      // top is the one opening arc 0 and the one closing arc 3.
      final opening = k == 0 ? top : gap;
      final closing = k == 3 ? top : gap;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: _radius),
        -quarter + opening / 2 + k * quarter,
        quarter - opening / 2 - closing / 2,
        false,
        paint,
      );
    }

    if (rim == MedalRim.anomalyGlobalOp) {
      canvas.drawCircle(
        centre.translate(0, -_radius),
        2.3,
        Paint()
          ..color = colour
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.save();
    canvas.scale(scale);

    final rimColour = metal?.rim ?? unearned;
    const centre = Offset(12, 12);

    if (metal != null) {
      canvas.drawCircle(
        centre,
        _radius,
        Paint()
          ..color = metal!.solid ? rimColour : rimColour.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
    }
    _drawRim(canvas, centre, rimColour);

    final colour = metal == null
        ? unearned
        : metal!.solid
        ? onSolid
        : ink;
    final fill = Paint()
      ..color = colour
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // The glyphs are drawn for a 24-unit square too, then shrunk to sit
    // inside the rim.
    canvas.translate(12, 12);
    canvas.scale(0.60);
    canvas.translate(-12, -12);
    glyph(canvas, fill, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.glyph != glyph ||
      old.rim != rim ||
      old.metal?.rim != metal?.rim ||
      old.ink != ink ||
      old.unearned != unearned ||
      old.onSolid != onSolid;
}

// --- The emblems -----------------------------------------------------------
//
// One entry per counter the registry gives thresholds to. Keep this map and
// the registry in step: `medal_icon_test.dart` fails when a tiered counter has
// no emblem here.

void _line(Canvas c, Paint p, double x1, double y1, double x2, double y2) =>
    c.drawLine(Offset(x1, y1), Offset(x2, y2), p);

void _dot(Canvas c, Paint p, double x, double y, double r) =>
    c.drawCircle(Offset(x, y), r, p);

void _ring(Canvas c, Paint p, double x, double y, double r) =>
    c.drawCircle(Offset(x, y), r, p);

void _roundRect(Canvas c, Paint p, Rect rect, double radius) =>
    c.drawRRect(RRect.fromRectXY(rect, radius, radius), p);

/// Dashes a straight run, since Flutter has no dash support on Paint.
void _dashed(
  Canvas c,
  Paint p,
  double x,
  double y1,
  double y2, {
  double dash = 1.5,
  double gap = 2.0,
}) {
  var y = y1;
  while (y < y2) {
    final end = (y + dash).clamp(y1, y2);
    c.drawLine(Offset(x, y), Offset(x, end), p);
    y = end + gap;
  }
}

/// The four corner brackets of a capture frame, shared by the two scan
/// medals: what differs between them is what the frame holds.
void _scanFrame(Canvas c, Paint stroke) {
  for (final path in [
    Path()
      ..moveTo(5, 9.4)
      ..lineTo(5, 5)
      ..lineTo(9.4, 5),
    Path()
      ..moveTo(14.6, 5)
      ..lineTo(19, 5)
      ..lineTo(19, 9.4),
    Path()
      ..moveTo(19, 14.6)
      ..lineTo(19, 19)
      ..lineTo(14.6, 19),
    Path()
      ..moveTo(9.4, 19)
      ..lineTo(5, 19)
      ..lineTo(5, 14.6),
  ]) {
    c.drawPath(path, stroke);
  }
}

/// A map pin, the mark of a place. Filled when it sits inside something else.
void _pin(Canvas c, Paint p, {required bool filled}) {
  final path = Path()
    ..moveTo(12, filled ? 7.6 : 3.8)
    ..cubicTo(
      filled ? 10.1 : 8.1,
      filled ? 7.6 : 3.8,
      filled ? 8.6 : 5,
      filled ? 9.1 : 6.9,
      filled ? 8.6 : 5,
      filled ? 11 : 10.8,
    )
    ..cubicTo(
      filled ? 8.6 : 5,
      filled ? 13.4 : 15.6,
      12,
      filled ? 16.6 : 20.6,
      12,
      filled ? 16.6 : 20.6,
    )
    ..cubicTo(
      12,
      filled ? 16.6 : 20.6,
      filled ? 15.4 : 19,
      filled ? 13.4 : 15.6,
      filled ? 15.4 : 19,
      filled ? 11 : 10.8,
    )
    ..cubicTo(
      filled ? 15.4 : 19,
      filled ? 9.1 : 6.9,
      filled ? 13.9 : 15.9,
      filled ? 7.6 : 3.8,
      12,
      filled ? 7.6 : 3.8,
    )
    ..close();
  c.drawPath(path, p);
}

/// The emblems drawn with a broken rim, and which of those carry the Global Op
/// stud (#99).
///
/// Declared here rather than read from the registry: the rim is part of the
/// drawing, and this widget has no registry to consult. What keeps the two
/// honest is `medal_icon_test`, which checks these sets against the counters
/// the registry dates — in both directions, so an emblem rimmed as seasonal
/// without a dated ladder fails just as loudly as the reverse.
const _anomalyGlobalOpEmblems = {
  'orion_link_and_field_points',
  'apollo_mod_battle_points',
};

const _anomalyEmblems = {'orion_tokens', 'apollo_tokens', 'cygnus_tokens'};

/// Orion: a coin struck with the belt. Worn by both of its medals (#123).
void _orionMotif(Canvas c, Paint fill, Paint stroke) {
  _ring(c, stroke..strokeWidth = 2.2, 12, 12, 7.4);
  _dot(c, fill, 8.5, 15.5, 1.8);
  _dot(c, fill, 12, 12, 1.8);
  _dot(c, fill, 15.5, 8.5, 1.8);
}

/// Apollo: the same coin, struck with the ascent. Worn by both of its medals.
void _apolloMotif(Canvas c, Paint fill, Paint stroke) {
  _ring(c, stroke..strokeWidth = 2.2, 12, 12, 7.4);
  c.drawPath(
    Path()
      ..moveTo(8.6, 14.2)
      ..lineTo(12, 9.4)
      ..lineTo(15.4, 14.2),
    stroke..strokeWidth = 2.3,
  );
}

final _glyphs = <String, void Function(Canvas, Paint, Paint)>{
  // Distance covered: a winding road. No end dots — those belong to the link,
  // and at list size a line between two dots was the same drawing.
  'trekker': (c, fill, stroke) => c.drawPath(
    Path()
      ..moveTo(5.4, 19.6)
      ..cubicTo(12, 19.6, 6, 13.4, 12, 12)
      ..cubicTo(18, 10.6, 12, 4.4, 18.6, 4.4),
    stroke..strokeWidth = 2.4,
  ),

  // A hack: something taken out of a portal.
  'hacker': (c, fill, stroke) {
    _roundRect(c, stroke, const Rect.fromLTWH(4.4, 6.6, 8.4, 10.8), 1.6);
    c.drawPath(
      Path()
        ..moveTo(11.4, 12)
        ..lineTo(19.6, 12),
      stroke,
    );
    c.drawPath(
      Path()
        ..moveTo(16.6, 8.9)
        ..lineTo(19.9, 12)
        ..lineTo(16.6, 15.1),
      stroke,
    );
  },

  // Mind units taken: a centre, and the zone it commands.
  //
  // The key is a badge name and badge names lie: Illuminator counts mind
  // units, not fields (#129). What a glyph says comes from the counter's
  // export header, never from its key.
  'illuminator': (c, fill, stroke) {
    _dot(c, fill, 12, 12, 2.9);
    c.drawArc(
      Rect.fromCircle(center: const Offset(12, 12), radius: 7.6),
      -0.9,
      1.8,
      false,
      stroke..strokeWidth = 2.2,
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(12, 12), radius: 7.6),
      2.24,
      1.8,
      false,
      stroke,
    );
  },

  // Deploying: pieces set around a centre.
  'builder': (c, fill, stroke) {
    _dot(c, fill, 12, 12, 2.9);
    for (final o in [
      const Offset(12, 4.6),
      const Offset(12, 19.4),
      const Offset(4.6, 12),
      const Offset(19.4, 12),
    ]) {
      _ring(c, stroke..strokeWidth = 2.1, o.dx, o.dy, 2.2);
    }
  },

  // A link: two nodes, one span.
  'connector': (c, fill, stroke) {
    _line(c, stroke..strokeWidth = 2.2, 6.6, 17.4, 17.4, 6.6);
    _dot(c, fill, 5.6, 18.4, 2.6);
    _dot(c, fill, 18.4, 5.6, 2.6);
  },

  // A mod: a part seated in its housing.
  'engineer': (c, fill, stroke) {
    _roundRect(c, stroke, const Rect.fromLTWH(4.6, 4.6, 14.8, 14.8), 2.6);
    _roundRect(c, fill, const Rect.fromLTWH(9.2, 9.2, 5.6, 5.6), 1.2);
  },

  // Portals visited: a place reached.
  'explorer': (c, fill, stroke) {
    _pin(c, stroke, filled: false);
    _dot(c, fill, 12, 10.7, 2.5);
  },

  // Taking a portal: a flag raised.
  'liberator': (c, fill, stroke) {
    _line(c, stroke, 6.6, 20, 6.6, 4.4);
    c.drawPath(
      Path()
        ..moveTo(6.6, 5)
        ..lineTo(18.4, 5)
        ..lineTo(15.4, 9.1)
        ..lineTo(18.4, 13.2)
        ..lineTo(6.6, 13.2)
        ..close(),
      fill,
    );
  },

  // Hacking by drone: rotors, and a beam onto the portal below.
  'maverick': (c, fill, stroke) {
    _line(c, stroke..strokeWidth = 2.1, 4.8, 6.2, 19.2, 6.2);
    _dot(c, fill, 4.8, 6.2, 1.9);
    _dot(c, fill, 19.2, 6.2, 1.9);
    _line(c, stroke, 12, 6.2, 12, 9);
    _roundRect(c, fill, const Rect.fromLTWH(9, 8.8, 6, 4.2), 1.5);
    _dashed(c, stroke..strokeWidth = 2, 12, 14.6, 17);
    _ring(c, stroke..strokeWidth = 2.1, 12, 19.6, 2.3);
  },

  // A field: three nodes, joined. Mind Controller counts control fields,
  // whatever its name suggests (#129).
  'mind_controller': (c, fill, stroke) {
    c.drawPath(
      Path()
        ..moveTo(12, 5.2)
        ..lineTo(18.8, 17.2)
        ..lineTo(5.2, 17.2)
        ..close(),
      stroke,
    );
    _dot(c, fill, 12, 5.2, 2.2);
    _dot(c, fill, 18.8, 17.2, 2.2);
    _dot(c, fill, 5.2, 17.2, 2.2);
  },

  // Getting there first: a marker, and rays.
  'pioneer': (c, fill, stroke) {
    _dot(c, fill, 12, 12, 3.4);
    stroke.strokeWidth = 2.1;
    _line(c, stroke, 12, 3.4, 12, 6.2);
    _line(c, stroke, 12, 17.8, 12, 20.6);
    _line(c, stroke, 3.4, 12, 6.2, 12);
    _line(c, stroke, 17.8, 12, 20.6, 12);
    _line(c, stroke, 6.2, 6.2, 8.2, 8.2);
    _line(c, stroke, 15.8, 15.8, 17.8, 17.8);
    _line(c, stroke, 17.8, 6.2, 15.8, 8.2);
    _line(c, stroke, 8.2, 15.8, 6.2, 17.8);
  },

  // Resonators destroyed: a deployed piece struck out.
  'purifier': (c, fill, stroke) {
    _roundRect(
      c,
      stroke..strokeWidth = 2.2,
      const Rect.fromLTWH(5.4, 5.4, 13.2, 13.2),
      2.4,
    );
    _line(c, stroke..strokeWidth = 2.4, 8.8, 8.8, 15.2, 15.2);
    _line(c, stroke, 15.2, 8.8, 8.8, 15.2);
  },

  // Recharging: energy put back.
  'recharger': (c, fill, stroke) {
    c.drawArc(
      Rect.fromCircle(center: const Offset(12, 12), radius: 7.4),
      -1.57,
      4.9,
      false,
      stroke..strokeWidth = 2.2,
    );
    _line(c, stroke, 19.4, 12, 19.4, 6.4);
    _line(c, stroke, 19.4, 12, 14.2, 12);
    _dot(c, fill, 12, 12, 2.4);
  },

  // Scans uploaded: the framing of a capture, and the sweep across it.
  'scout': (c, fill, stroke) {
    _scanFrame(c, stroke..strokeWidth = 2.1);
    _line(c, stroke..strokeWidth = 2.3, 8, 12, 16, 12);
  },

  // Unique portals scanned: the same frame, holding a place rather than a
  // sweep — the difference between the two scan medals is what is counted.
  'scout_controller': (c, fill, stroke) {
    _scanFrame(c, stroke..strokeWidth = 2.1);
    _pin(c, fill, filled: true);
  },

  // An operation carried out: a task struck off.
  'specops': (c, fill, stroke) {
    _roundRect(
      c,
      stroke..strokeWidth = 2.2,
      const Rect.fromLTWH(4.4, 4.4, 15.2, 15.2),
      2.8,
    );
    c.drawPath(
      Path()
        ..moveTo(8, 12.2)
        ..lineTo(11, 15.2)
        ..lineTo(16.2, 8.8),
      stroke..strokeWidth = 2.3,
    );
  },

  // --- the anomaly ladders (#99, #123) -------------------------------------
  //
  // A season's medals share one motif, because they are the ones that end up
  // side by side: the counters of a season sit consecutively in the events
  // category, while medals of different seasons never meet. What each medal
  // measures is not drawn at all — the rim says which of its season's medals
  // this is, and the label beside it says the rest.
  //
  // So the coin is no longer a mark of "Season medal". It is simply part of
  // what Orion and Apollo look like, and Cygnus does without one.
  'orion_link_and_field_points': _orionMotif,
  'orion_tokens': _orionMotif,

  'apollo_mod_battle_points': _apolloMotif,
  'apollo_tokens': _apolloMotif,

  // Cygnus: the swan itself — two strokes of wing, and the neck rising to a
  // beak. Its Global Ops have no counter to sit beside yet; when one appears,
  // it takes this motif too.
  'cygnus_tokens': (c, fill, stroke) {
    stroke.strokeWidth = 2.2;
    _line(c, stroke, 5.4, 18.6, 11.4, 11.4);
    _line(c, stroke, 8.6, 19, 14.6, 11.8);
    c.drawPath(
      Path()
        ..moveTo(13.6, 19.2)
        ..cubicTo(12.4, 10.4, 17.6, 7.8, 19.2, 10.6)
        ..lineTo(21, 9.4),
      stroke,
    );
  },

  // A glyph traced: one stroke across its nodes.
  'translator': (c, fill, stroke) {
    c.drawPath(
      Path()
        ..moveTo(6, 8)
        ..lineTo(18, 8)
        ..lineTo(6, 16)
        ..lineTo(18, 16),
      stroke..strokeWidth = 2.2,
    );
    _dot(c, fill, 6, 8, 2.3);
    _dot(c, fill, 18, 16, 2.3);
  },
};
