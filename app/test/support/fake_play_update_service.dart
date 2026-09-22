import 'package:fieldtally/data/updates/play_update_service.dart';

/// Stands in for Play's in-app update API (#195).
///
/// There is no other way to exercise any of this: the real plugin answers
/// only inside an install Play itself made, so an emulator, a local build and
/// every test see the same nothing. What the app owes its own tests is
/// therefore the wiring — that a downloaded update reaches a banner, and that
/// pressing it asks for the install — not Play's behaviour, which is Play's.
class FakePlayUpdateService implements PlayUpdateService {
  /// What Play is holding. Nothing, like a device already on the newest
  /// version, until a test says otherwise.
  PlayUpdate state = PlayUpdate.none;

  /// Whether the download goes through. False stands in for the sheet being
  /// dismissed as much as for a download that failed — the app cannot tell
  /// those apart, and treats them the same.
  bool downloadSucceeds = true;

  int downloads = 0;
  int installs = 0;

  @override
  Future<PlayUpdate> check() async => state;

  @override
  Future<bool> download() async {
    downloads++;
    return downloadSucceeds;
  }

  @override
  Future<void> install() async => installs++;
}
