import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import 'parse_exception.dart';

/// Parser de l'export de stats d'Ingress Prime (§3.1.1).
///
/// L'export est un texte tabulé avec une ligne d'en-têtes explicite. Le point
/// central de ce parser, et la raison pour laquelle le format est jugé
/// exploitable malgré son absence de documentation officielle :
/// **chaque colonne est retrouvée par son nom, jamais par sa position.**
/// Un mapping positionnel casserait dès que Niantic ajoute, retire ou
/// réordonne une colonne — ce qui arrive à chaque saison d'anomalie.
///
/// Corollaire assumé : tout ce qui n'est pas une colonne de métadonnée connue
/// est un compteur, y compris un nom jamais vu. C'est le §3.1.2 : le registre
/// est piloté par les données, pas par une liste codée en dur.
class IngressTsvParser {
  const IngressTsvParser();

  /// Noms acceptés pour chaque colonne de métadonnée.
  ///
  /// Ingress suffixe certains en-têtes du format attendu (`Date (yyyy-mm-dd)`).
  /// On compare sur une forme normalisée — minuscules, parenthèses retirées —
  /// pour ne pas casser si ce suffixe change ou disparaît, sans pour autant
  /// tomber dans une reconnaissance approximative.
  static const _timeSpanNames = {'time span'};
  static const _agentNameNames = {'agent name'};
  static const _factionNames = {'agent faction'};
  static const _dateNames = {'date'};
  static const _timeNames = {'time'};
  static const _levelNames = {'level'};

  static const _metadataNames = {
    ..._timeSpanNames,
    ..._agentNameNames,
    ..._factionNames,
    ..._dateNames,
    ..._timeNames,
  };

  /// Parse un export complet et renvoie un relevé par ligne de données.
  ///
  /// Un export Ingress n'en contient qu'une, mais rien n'impose cette limite
  /// et la traiter comme un cas général coûte moins cher que de la supposer.
  List<StatSnapshot> parse(String raw) {
    final lines = _splitLines(raw);
    if (lines.isEmpty) {
      throw const ExportParseException(
        "Le texte collé est vide — rien à importer.",
      );
    }
    if (lines.length < 2) {
      throw const ExportParseException(
        "L'export ne contient qu'une ligne d'en-têtes, sans aucune valeur. "
        "Vérifie que tu as bien copié le texte entier depuis Ingress.",
      );
    }

    final headers = _parseHeaders(lines.first);
    return [
      for (var i = 1; i < lines.length; i++) _parseRow(headers, lines[i], i),
    ];
  }

  /// Raccourci pour le cas courant : un export, un relevé.
  StatSnapshot parseSingle(String raw) {
    final snapshots = parse(raw);
    if (snapshots.length > 1) {
      throw ExportParseException(
        "L'export contient ${snapshots.length} relevés alors qu'un seul est "
        "attendu ici.",
      );
    }
    return snapshots.first;
  }

  List<String> _splitLines(String raw) {
    // On retire le BOM éventuel : un copier-coller depuis certaines apps le
    // laisse traîner, et il se collerait au premier en-tête.
    final cleaned = raw.replaceFirst('﻿', '');
    return cleaned
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  List<String> _parseHeaders(String line) {
    final headers = line.split('\t').map((h) => h.trim()).toList();

    if (headers.length < 2) {
      throw const ExportParseException(
        "Ce texte ne ressemble pas à un export Ingress : aucune colonne tabulée "
        "n'a été trouvée. Utilise le bouton de partage d'Ingress plutôt qu'une "
        "copie manuelle depuis l'écran.",
      );
    }

    final blank = headers.indexWhere((h) => h.isEmpty);
    if (blank >= 0) {
      throw ExportParseException(
        "L'export contient une colonne sans nom (position ${blank + 1}), ce qui "
        "rend l'association des valeurs ambiguë.",
      );
    }

    // Des en-têtes en doublon rendraient le mapping par nom indéterminé : on
    // ne peut pas choisir à la place de l'utilisateur quelle colonne gagne.
    final seen = <String>{};
    for (final header in headers) {
      if (!seen.add(header)) {
        throw ExportParseException(
          "L'export contient deux colonnes nommées « $header ». Impossible de "
          "savoir laquelle utiliser.",
          column: header,
        );
      }
    }

    return headers;
  }

  StatSnapshot _parseRow(List<String> headers, String line, int lineNumber) {
    final values = line.split('\t').map((v) => v.trim()).toList();

    if (values.length != headers.length) {
      throw ExportParseException(
        "Ligne $lineNumber : ${values.length} valeurs pour ${headers.length} "
        "colonnes. Le texte a probablement été tronqué à la copie.",
      );
    }

    final byName = <String, String>{
      for (var i = 0; i < headers.length; i++) _normalize(headers[i]): values[i],
    };

    final timeSpan = _require(byName, _timeSpanNames, 'Time Span');
    final agentName = _require(byName, _agentNameNames, 'Agent Name');
    final faction = _require(byName, _factionNames, 'Agent Faction');
    final date = _require(byName, _dateNames, 'Date');
    final time = _require(byName, _timeNames, 'Time');
    final level = _require(byName, _levelNames, 'Level');

    // Tout ce qui n'est pas une métadonnée est un compteur — y compris `Level`,
    // qui sert à la fois de métadonnée du relevé (§3.1.1) et de valeur suivie
    // dans le temps (Annexe A).
    final counters = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (_metadataNames.contains(_normalize(header))) continue;
      counters[header] = _parseInt(values[i], header);
    }

    return StatSnapshot(
      timeSpan: TimeSpan.parse(timeSpan),
      agentName: agentName,
      faction: faction,
      recordedAt: _parseDateTime(date, time),
      level: _parseInt(level, 'Level'),
      counters: counters,
    );
  }

  /// Minuscules, espaces normalisés, et suffixe de format entre parenthèses
  /// retiré : `Date (yyyy-mm-dd)` devient `date`.
  String _normalize(String header) => header
      .replaceAll(RegExp(r'\([^)]*\)'), '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  String _require(Map<String, String> byName, Set<String> names, String label) {
    for (final name in names) {
      final value = byName[name];
      if (value != null) return value;
    }
    throw ExportParseException(
      "La colonne « $label » est absente de l'export. Le format d'Ingress a "
      "peut-être changé — signale-le avec un extrait anonymisé.",
      column: label,
    );
  }

  /// Séparateurs de milliers rencontrés selon la langue et la région du
  /// téléphone (§6) : espace fine ou insécable, virgule, point, apostrophe.
  ///
  /// Les compteurs Ingress sont tous entiers, donc aucun de ces caractères ne
  /// peut être une virgule décimale : les retirer est sans ambiguïté. Ce qui
  /// reste doit être exclusivement des chiffres, sans quoi on refuse plutôt
  /// que de deviner.
  static final _separators = RegExp(r"[\s,.  ']");
  static final _integer = RegExp(r'^-?\d+$');

  int _parseInt(String raw, String column) {
    final stripped = raw.replaceAll(_separators, '');

    if (stripped.isEmpty) {
      throw ExportParseException(
        "La colonne « $column » est vide.",
        column: column,
        rawValue: raw,
      );
    }
    if (!_integer.hasMatch(stripped)) {
      throw ExportParseException(
        "La colonne « $column » ne contient pas un nombre entier.",
        column: column,
        rawValue: raw,
      );
    }

    final parsed = int.tryParse(stripped);
    if (parsed == null) {
      // Dépassement de capacité : un entier Dart natif tient sur 64 bits, donc
      // ça suppose une valeur absurde, pas un vrai compteur.
      throw ExportParseException(
        "La valeur de « $column » est hors des limites acceptables.",
        column: column,
        rawValue: raw,
      );
    }
    return parsed;
  }

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  DateTime _parseDateTime(String date, String time) {
    final dateMatch = _datePattern.firstMatch(date);
    if (dateMatch == null) {
      throw ExportParseException(
        "La date « $date » n'est pas au format attendu (aaaa-mm-jj).",
        column: 'Date',
        rawValue: date,
      );
    }

    // L'heure est optionnelle sur le chemin CSV de migration (Annexe B), où
    // elle vaut minuit par défaut. On applique la même tolérance ici.
    final timeMatch = time.isEmpty ? null : _timePattern.firstMatch(time);
    if (time.isNotEmpty && timeMatch == null) {
      throw ExportParseException(
        "L'heure « $time » n'est pas au format attendu (hh:mm:ss).",
        column: 'Time',
        rawValue: time,
      );
    }

    final parsed = DateTime(
      int.parse(dateMatch.group(1)!),
      int.parse(dateMatch.group(2)!),
      int.parse(dateMatch.group(3)!),
      timeMatch == null ? 0 : int.parse(timeMatch.group(1)!),
      timeMatch == null ? 0 : int.parse(timeMatch.group(2)!),
      timeMatch?.group(3) == null ? 0 : int.parse(timeMatch!.group(3)!),
    );

    // DateTime normalise silencieusement les dates impossibles (le 32 janvier
    // devient le 1er février). On refuse plutôt que d'enregistrer une date que
    // l'utilisateur n'a pas saisie.
    if (parsed.month != int.parse(dateMatch.group(2)!) ||
        parsed.day != int.parse(dateMatch.group(3)!)) {
      throw ExportParseException(
        "La date « $date » n'existe pas.",
        column: 'Date',
        rawValue: date,
      );
    }

    return parsed;
  }
}
