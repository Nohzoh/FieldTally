import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Text shared into the app from another one — in practice, Ingress (§3.1).
///
/// Declared as an interface rather than calling the plugin directly so the
/// wiring can be exercised without a platform channel: nothing in a widget
/// test can produce a real Android share.
abstract interface class IncomingShareSource {
  /// Text the app was launched with, when it was started *by* a share.
  /// Null when it was opened normally.
  Future<String?> initialText();

  /// Text shared while the app is already running.
  Stream<String> textStream();

  /// Tells the platform the initial share has been consumed.
  ///
  /// Without this, coming back to the app later replays the same share and
  /// would offer to import a snapshot that was already handled.
  void reset();
}

/// Implementation backed by the `receive_sharing_intent` plugin.
///
/// The plugin covers Android and iOS with the same API, so wiring it now does
/// not have to be redone when iOS becomes a target (§5.1).
class PluginIncomingShareSource implements IncomingShareSource {
  const PluginIncomingShareSource();

  @override
  Future<String?> initialText() async =>
      extractText(await ReceiveSharingIntent.instance.getInitialMedia());

  @override
  Stream<String> textStream() => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(extractText)
      .where((text) => text != null)
      .cast<String>();

  @override
  void reset() => ReceiveSharingIntent.instance.reset();

  /// Ingress shares a single block of plain text. Anything else — an image, a
  /// file — is not something this app can read, so it is ignored rather than
  /// dropped onto the parser to fail there.
  @visibleForTesting
  static String? extractText(List<SharedMediaFile> media) {
    for (final item in media) {
      if (item.type == SharedMediaType.text && item.path.trim().isNotEmpty) {
        return item.path;
      }
    }
    return null;
  }
}
