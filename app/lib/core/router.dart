import 'package:go_router/go_router.dart';

import '../presentation/screens/add_snapshot_screen.dart';
import '../presentation/screens/home_screen.dart';

/// Routes de l'app (§5.1 : go_router).
///
/// Deux écrans à ce stade. Le tableau de bord personnalisable (§3.3), la vue
/// détaillée (§3.4) et les graphiques (§3.5) viendront s'ajouter ici.
abstract final class Routes {
  static const home = '/';
  static const addSnapshot = '/ajouter';
}

/// Construit un routeur neuf.
///
/// Une fabrique plutôt qu'une constante globale : un `GoRouter` porte l'état
/// de navigation, et le partager entre plusieurs tests widget les rendrait
/// dépendants de leur ordre d'exécution.
GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'ajouter',
          builder: (context, state) => AddSnapshotScreen(
            // Le partage entrant (§3.1) déposera ici le texte reçu depuis
            // Ingress, pour arriver directement sur l'aperçu.
            initialText: state.extra as String?,
          ),
        ),
      ],
    ),
  ],
);

/// Instance utilisée par l'app.
final router = createRouter();
