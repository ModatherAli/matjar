import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../auth/session.dart";

/// Temporary landing screen. The full storefront arrives in the next phase.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MATJAR"),
        actions: [
          IconButton(
            tooltip: "Log out",
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(sessionProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                "WELCOME BACK",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const GoldDivider(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(user.role),
                    side: const BorderSide(color: MatjarColors.gold),
                  ),
                  Chip(label: Text(user.email)),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "The boutique opens soon",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Home, catalog, cart, orders and the admin "
                        "atelier are being crafted in the next phases.",
                      ),
                    ],
                  ),
                ),
              ),
              if (user.isAdmin) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push("/admin"),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text("Open Admin Atelier"),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

