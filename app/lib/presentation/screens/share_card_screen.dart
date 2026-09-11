import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router.dart';
import '../../domain/counter_series.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/share_card.dart';

/// Preview and share of the stats card (§3.8).
///
/// A preview rather than a one-tap export: the image leaves the app for a
/// public place, and an agent should see exactly what it says before it does.
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({super.key});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  /// Captured well above screen density so the PNG survives being opened on a
  /// desktop, where a 360pt-wide image would look like a thumbnail.
  static const _pixelRatio = 3.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final card = ref.watch(shareCardProvider);
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final range = ref.watch(shareCardRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareCardTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: card.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => data == null
            ? _Empty(
                title: l10n.shareCardEmptyTitle,
                detail: l10n.shareCardEmptyDetail,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  SegmentedButton<ChartRange>(
                    segments: [
                      ButtonSegment(
                        value: ChartRange.week,
                        label: Text(l10n.rangeWeek),
                      ),
                      ButtonSegment(
                        value: ChartRange.month,
                        label: Text(l10n.rangeMonth),
                      ),
                      ButtonSegment(
                        value: ChartRange.all,
                        label: Text(l10n.rangeAll),
                      ),
                    ],
                    selected: {range},
                    onSelectionChanged: (selection) => ref
                        .read(shareCardRangeProvider.notifier)
                        .set(selection.first),
                  ),
                  const SizedBox(height: 20),
                  // The boundary keeps its own 360pt layout whatever the phone
                  // is, so the captured image is the same shape everywhere;
                  // the FittedBox only scales what is displayed.
                  FittedBox(
                    child: RepaintBoundary(
                      key: _boundary,
                      child: ShareCard(
                        data: data,
                        registry: registry,
                        language: language,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.ios_share),
                    label: Text(l10n.shareCardShare),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _sharing = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.shareCardFailed)),
        );
        return;
      }

      // A real file rather than raw bytes, for the same reason the CSV export
      // writes one: share_plus names data-backed files after a UUID, and the
      // agent would post "de7-11f1-….png".
      final directory = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${directory.path}/fieldtally-$stamp.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          subject: l10n.shareCardSubject,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List?> _capture() async {
    final object = _boundary.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;

    final image = await object.toImage(pixelRatio: _pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ios_share,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
