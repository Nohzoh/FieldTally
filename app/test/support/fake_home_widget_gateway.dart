import 'package:fieldtally/data/widgets/home_widget_gateway.dart';

/// Stands in for the platform channel behind the home screen widget (#154).
///
/// Records what was written rather than asserting on it: what matters about
/// the coordinator is which fields end up holding what, and every test wants
/// to check a different subset.
class FakeHomeWidgetGateway implements HomeWidgetGateway {
  final written = <String, String?>{};
  int refreshes = 0;

  @override
  Future<void> write(String key, String? value) async {
    written[key] = value;
  }

  @override
  Future<void> refresh() async => refreshes++;
}
