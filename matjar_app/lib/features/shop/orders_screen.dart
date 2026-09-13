import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "order_repository.dart";

const _orderFilters = [
  ("ALL", "All"),
  ("PENDING", "Pending"),
  ("PAID", "Paid"),
  ("SHIPPED", "Shipped"),
  ("DELIVERED", "Delivered"),
  ("CANCELLED", "Cancelled"),
];

/// Order history with status filter chips.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _status = "ALL";

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider(_status));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final (value, label) in _orderFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _status == value,
                      onSelected: (_) => setState(() => _status = value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(ordersProvider(_status)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: "No orders yet.",
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    final order = page.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => context.push("/orders/${order.id}"),
                        title: Row(
                          children: [
                            Text(
                              "#${order.id.substring(0, 8)}",
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            _StatusPill(status: order.status),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "${DateFormat.yMMMd().format(order.createdAt)} · "
                            "${order.items.length} item(s)",
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        trailing: Text(
                          formatMoney(order.total),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: MatjarColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      "PENDING" => MatjarColors.goldDeep,
      "PAID" => MatjarColors.emerald,
      "SHIPPED" => MatjarColors.emerald,
      "DELIVERED" => MatjarColors.emerald,
      "CANCELLED" => MatjarColors.danger,
      _ => MatjarColors.goldDeep,
    };
    final label = switch (status) {
      "PENDING" => "Pending",
      "PAID" => "Paid",
      "SHIPPED" => "Shipped",
      "DELIVERED" => "Delivered",
      "CANCELLED" => "Cancelled",
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}