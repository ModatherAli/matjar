import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "admin_repository.dart";

/// Admin home: dashboard metrics + links to management screens.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Atelier"),
        leading: IconButton(
          tooltip: "Back",
          onPressed: () => context.go("/home"),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _Stat(label: "Revenue", value: formatMoney(data.revenue)),
                _Stat(label: "Orders", value: "${data.totalOrders}"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: "Products", value: "${data.totalProducts}"),
                _Stat(label: "Users", value: "${data.totalUsers}"),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ORDERS BY STATUS",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: MatjarColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (data.ordersByStatus.isEmpty)
                      const Text("No orders yet.")
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in data.ordersByStatus.entries)
                            Chip(
                              label: Text(
                                "${entry.key.toLowerCase()} · ${entry.value}",
                              ),
                              side: const BorderSide(color: MatjarColors.gold),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(eyebrow: "Manage", title: "The Atelier"),
            const SizedBox(height: 12),
            _NavCard(
              icon: Icons.inventory_2_outlined,
              title: "Products",
              subtitle: "Create, edit, images, stock",
              onTap: () => context.push("/admin/products"),
            ),
            _NavCard(
              icon: Icons.category_outlined,
              title: "Categories",
              subtitle: "Organize the collection",
              onTap: () => context.push("/admin/categories"),
            ),
            _NavCard(
              icon: Icons.receipt_long_outlined,
              title: "Orders",
              subtitle: "Fulfill and track orders",
              onTap: () => context.push("/admin/orders"),
            ),
            _NavCard(
              icon: Icons.people_outline,
              title: "Users",
              subtitle: "Roles and account status",
              onTap: () => context.push("/admin/users"),
            ),
            const SizedBox(height: 24),
            SectionHeader(eyebrow: "Attention", title: "Low stock"),
            const SizedBox(height: 8),
            if (data.lowStock.isEmpty)
              const Text("Nothing running low.")
            else
              for (final item in data.lowStock)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(
                    Icons.warning_amber_outlined,
                    color: MatjarColors.goldDeep,
                  ),
                  title: Text(item.title),
                  subtitle: Text("SKU ${item.sku}"),
                  trailing: Text("${item.stockQty} left"),
                ),
            const SizedBox(height: 24),
            SectionHeader(eyebrow: "Latest", title: "Recent orders"),
            const SizedBox(height: 8),
            if (data.recentOrders.isEmpty)
              const Text("No orders yet.")
            else
              for (final order in data.recentOrders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    "#${order.id.substring(0, 8)} · "
                    "${order.userName ?? order.userEmail ?? "guest"}",
                  ),
                  subtitle:
                      Text(DateFormat.yMMMd().format(order.createdAt)),
                  trailing: Text(
                    formatMoney(order.total),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: MatjarColors.gold),
        title: Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}