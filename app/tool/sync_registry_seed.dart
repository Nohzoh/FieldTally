// Régénère app/assets/counters_registry_seed.json à partir de la source de
// vérité docs/registry/counters.json (spec §3.1.4, §7.4).
//
// Il ne doit exister qu'UN SEUL fichier maintenu à la main : celui de docs/.
// Le seed embarqué n'est qu'une copie de secours pour le fonctionnement
// hors-ligne au premier lancement.
//
//   dart run tool/sync_registry_seed.dart            # régénère le seed
//   dart run tool/sync_registry_seed.dart --check    # échoue si désynchronisé
//
// Lancé automatiquement avant chaque build en CI.

import 'dart:convert';
import 'dart:io';

const _source = '../docs/registry/counters.json';
const _seed = 'assets/counters_registry_seed.json';

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final source = File(_source);
  if (!source.existsSync()) {
    stderr.writeln(
      'Introuvable : $_source — ce script doit être lancé depuis app/.',
    );
    exit(1);
  }

  // On repasse par un décodage/encodage plutôt qu'une copie brute : ça valide
  // au passage que le JSON est syntaxiquement correct et normalise le format.
  final decoded = jsonDecode(source.readAsStringSync());
  final rendered = '${const JsonEncoder.withIndent('  ').convert(decoded)}\n';

  final seed = File(_seed);
  final current = seed.existsSync() ? seed.readAsStringSync() : null;

  if (current == rendered) {
    stdout.writeln('Seed déjà à jour ($_seed).');
    return;
  }

  if (checkOnly) {
    stderr.writeln(
      'Le seed embarqué est désynchronisé de $_source.\n'
      'Lance : dart run tool/sync_registry_seed.dart',
    );
    exit(1);
  }

  seed.parent.createSync(recursive: true);
  seed.writeAsStringSync(rendered);
  stdout.writeln('Seed régénéré : $_seed');
}
