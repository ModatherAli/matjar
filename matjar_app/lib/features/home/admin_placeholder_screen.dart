import "package:flutter/material.dart";

import "../../core/widgets.dart";

/// Placeholder for the admin atelier (dashboard + management).
class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Atelier")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            eyebrow: "Restricted",
            title: "Admin Atelier",
          ),
          const SizedBox(height: 12),
          const GoldDivider(),
          const SizedBox(height: 16),
          Text(
            "Dashboard statistics, product and category management, "
            "order fulfillment and user administration will live here.",
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

