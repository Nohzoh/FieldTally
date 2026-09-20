import 'package:fieldtally/data/widgets/home_widget_gateway.dart';

/// Stands in for the platform channel behind the home screen widget (#154).
///
/// Records what was written rather than asserting on it: what matters about
/// the coordinator is which fields end up holding what, and every test wants
/// to check a different subset.
class FakeHomeWidgetGateway implements HomeWidgetGateway {
  final written = <String, String?>{};
  int refreshes = 0;

  /// Set by a test to stand in for whatever the launcher currently has
  /// placed (#181). Empty until told otherwise, same as a fresh install.
  List<int> ids = const [];

  /// `appWidgetId`s [finishConfiguring] was called with, in order.
  final finishedConfiguring = <int>[];

  /// `exportHeader`s [requestPinWidget] was called with, in order.
  final pinRequests = <String>[];

  /// Set by a test to stand in for a launcher that cannot pin widgets this
  /// way (#181).
  bool pinWidgetSupported = true;

  @override
  Future<void> write(String key, String? value) async {
    written[key] = value;
  }

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<List<int>> instanceIds() async => ids;

  @override
  Future<void> finishConfiguring(int appWidgetId) async {
    finishedConfiguring.add(appWidgetId);
  }

  @override
  Future<bool> requestPinWidget(String exportHeader) async {
    pinRequests.add(exportHeader);
    return pinWidgetSupported;
  }
}
