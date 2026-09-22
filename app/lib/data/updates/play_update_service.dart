import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// What Play is holding for this install, if anything (#195).
enum PlayUpdate {
  /// Nothing to offer — including every case where Play cannot answer, which
  /// amounts to the same thing from inside the app.
  none,

  /// A newer version exists and may be fetched in the background.
  available,

  /// A newer version is already on the device, waiting only for a restart. A
  /// download accepted on an earlier launch and never installed lands here.
  downloaded,
}

/// Offers the newer version Play already knows about (#195).
///
/// FieldTally is installed from the Play Store (#198), which does update it on
/// its own — eventually, overnight, on wifi, invisibly. This exists for the
/// gap that leaves: someone opening the app today can be running a build Play
/// has not got round to replacing, with no way of knowing.
///
/// **The flexible flow, never the immediate one.** A new version is worth
/// offering and never worth holding someone's stats behind. Play draws the
/// consent sheet itself, in the system's own language, and downloads in the
/// background while the app carries on; the only thing the app has to say is
/// the line offering the restart at the end, because installing is the one
/// step Android will not take unasked.
///
/// Every failure is swallowed and invisible, exactly like the counter
/// registry's: an app that cannot reach Play behaves as if there were no newer
/// version. That is not only politeness — none of this can be exercised
/// outside an install Play itself made, so it has to be built to be harmless
/// when it does nothing at all.
class PlayUpdateService {
  const PlayUpdateService();

  /// Asks Play what it has, without asking the person anything.
  Future<PlayUpdate> check() async {
    if (defaultTargetPlatform != TargetPlatform.android) return PlayUpdate.none;

    try {
      final info = await InAppUpdate.checkForUpdate();

      // Checked before availability: a download that completed on an earlier
      // launch leaves an update in progress, not one available, and the only
      // thing left to do with it is install it.
      if (info.installStatus == InstallStatus.downloaded) {
        return PlayUpdate.downloaded;
      }

      return info.updateAvailability == UpdateAvailability.updateAvailable &&
              info.flexibleUpdateAllowed
          ? PlayUpdate.available
          : PlayUpdate.none;
    } catch (_) {
      // No Play services, no network, a build installed some other way, a
      // Play Store too old to answer. None of it is worth a word on screen.
      return PlayUpdate.none;
    }
  }

  /// Asks, then downloads. True once the file is on the device.
  ///
  /// Play's own sheet is the asking. A dialog of the app's own in front of it
  /// would be the same question twice, in two designs, in possibly two
  /// languages.
  Future<bool> download() async {
    try {
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } catch (_) {
      // Declined, cancelled, or a download that failed. All three mean the
      // same thing here: carry on with the version that is running.
      return false;
    }
  }

  /// Installs what was downloaded. Android restarts the app itself.
  Future<void> install() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      // Nothing left to offer. Play installs it on its own terms later, which
      // is what would have happened anyway.
    }
  }
}
