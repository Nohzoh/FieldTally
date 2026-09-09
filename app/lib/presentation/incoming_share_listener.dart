import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router.dart';
import 'providers/providers.dart';

/// Sends text shared from another app straight to the preview screen (§3.1).
///
/// Wraps the app rather than living inside a screen: a share can arrive at any
/// moment, including while the user is somewhere else entirely, and it has to
/// be handled even when the app was launched *by* that share.
class IncomingShareListener extends ConsumerStatefulWidget {
  const IncomingShareListener({
    super.key,
    required this.router,
    required this.child,
  });

  /// Navigation happens through the router directly: a share may land before
  /// any screen has a usable context.
  final GoRouter router;

  final Widget child;

  @override
  ConsumerState<IncomingShareListener> createState() =>
      _IncomingShareListenerState();
}

class _IncomingShareListenerState extends ConsumerState<IncomingShareListener> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    final source = ref.read(incomingShareProvider);

    _subscription = source.textStream().listen(_open);

    // A share that launched the app is delivered separately from the stream.
    unawaited(source.initialText().then((text) {
      if (text == null) return;
      _open(text);
      // Mark it consumed, otherwise returning to the app later replays the
      // same share and offers to import a snapshot already dealt with.
      source.reset();
    }));
  }

  void _open(String text) {
    if (!mounted) return;
    widget.router.go(Routes.addSnapshot, extra: text);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
