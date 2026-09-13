import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../features/auth/login_screen.dart";
import "../features/auth/register_screen.dart";
import "../features/auth/session.dart";
import "../features/home/admin_placeholder_screen.dart";
import "../features/home/home_screen.dart";
import "network.dart";

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  ref.watch(sessionSignalProvider);

  const authLocations = ["/login", "/register"];

  return GoRouter(
    initialLocation: "/home",
    redirect: (context, state) {
      if (session.isLoading) {
        return null;
      }
      final user = session.value;
      final location = state.matchedLocation;

      if (user == null) {
        return authLocations.contains(location) ? null : "/login";
      }
      if (authLocations.contains(location)) {
        return "/home";
      }
      if (location.startsWith("/admin") && !user.isAdmin) {
        return "/home";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/register",
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: "/admin",
        builder: (context, state) => const AdminPlaceholderScreen(),
      ),
    ],
  );
});


