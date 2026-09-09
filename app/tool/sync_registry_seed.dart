// Regenerates app/assets/counters_registry_seed.json from the source of truth,
// docs/registry/counters.json (spec §3.1.4, §7.4).
//
// Exactly one file is maintained by hand: the one under docs/. The bundled
// seed is only a fallback so the app works offline on first launch.
//
//   dart run tool/sync_registry_seed.dart            # regenerate the seed
//   dart run tool/sync_registry_seed.dart --check    # fail if out of sync
//
// Run automatically before every build in CI.

import 'dart:convert';
import 'dart:io';

const _source = '../docs/registry/counters.json';
const _seed = 'assets/counters_registry_seed.json';

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final source = File(_source);
  if (!source.existsSync()) {
    stderr.writeln('Not found: $_source — run this script from app/.');
    exit(1);
  }

  // Decode then re-encode rather than copying bytes: this validates the JSON
  // along the way and normalises the formatting.
  final decoded = jsonDecode(source.readAsStringSync());
  final rendered = '${const JsonEncoder.withIndent('  ').convert(decoded)}\n';

  final seed = File(_seed);
  final current = seed.existsSync() ? seed.readAsStringSync() : null;

  if (current == rendered) {
    stdout.writeln('Seed already up to date ($_seed).');
    return;
  }

  if (checkOnly) {
    stderr.writeln(
      'The bundled seed is out of sync with $_source.\n'
      'Run: dart run tool/sync_registry_seed.dart',
    );
    exit(1);
  }

  seed.parent.createSync(recursive: true);
  seed.writeAsStringSync(rendered);
  stdout.writeln('Seed regenerated: $_seed');
}
