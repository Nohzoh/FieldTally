import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';

/// Work kicked off once when the app starts.
///
/// Currently one task: refreshing the counter registry from GitHub Pages
/// (§3.1.4). It is deliberately fire-and-forget — nothing on screen waits for
/// it, and it fails silently, because a background refresh of counter labels
/// is not worth delaying a frame or showing an error over.
class StartupTasks extends ConsumerStatefulWidget {
  const StartupTasks({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupTasks> createState() => _StartupTasksState();
}

class _StartupTasksState extends ConsumerState<StartupTasks> {
  @override
  void initState() {
    super.initState();
    // After the first frame: the registry the app starts with is the local
    // one, and swapping it mid-build would be a wasted rebuild at best.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(counterRegistryProvider.notifier).refreshFromNetwork(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
