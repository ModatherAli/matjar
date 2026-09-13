import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../features/admin/admin_home_screen.dart";
import "../features/admin/admin_products_screen.dart";
import "../features/admin/admin_users_screen.dart";
import "../features/auth/login_screen.dart";
import "../features/auth/register_screen.dart";
import "../features/auth/session.dart";
import "../features/catalog/product_detail_screen.dart";
import "../features/catalog/shop_screen.dart";
import "../features/home/home_screen.dart";
import "../features/profile/profile_screen.dart";
import "../features/shop/cart_screen.dart";
import "../features/shop/checkout_screen.dart";
import "../features/shop/order_detail_screen.dart";
import "../features/shop/orders_screen.dart";
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MatjarShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/home",
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/shop",
                builder: (context, state) => ShopScreen(
                  initialCategory:
                      state.uri.queryParameters["category"]?.isNotEmpty == true
                          ? state.uri.queryParameters["category"]
                          : null,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/cart",
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/orders",
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/profile",
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: "/product/:slug",
        builder: (context, state) =>
            ProductDetailScreen(slug: state.pathParameters["slug"]!),
      ),
      GoRoute(
        path: "/checkout",
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: "/orders/:id",
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters["id"]!),
      ),
      GoRoute(
        path: "/admin",
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: "/admin/products",
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: "/admin/categories",
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: "/admin/orders",
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: "/admin/users",
        builder: (context, state) => const AdminUsersScreen(),
      ),
    ],
  );
});

/// Bottom-navigation shell: 5 tabs with independent back stacks.
class MatjarShell extends StatelessWidget {
  const MatjarShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home, "Home"),
    (Icons.storefront_outlined, Icons.storefront, "Shop"),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, "Bag"),
    (Icons.receipt_long_outlined, Icons.receipt_long, "Orders"),
    (Icons.person_outline, Icons.person, "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: [
          for (final (icon, activeIcon, label) in _tabs)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(activeIcon),
              label: label,
            ),
        ],
      ),
    );
  }
}