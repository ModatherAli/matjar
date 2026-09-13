import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";

import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../admin/admin_repository.dart";
import "../auth/session.dart";
import "order_repository.dart";

/// Order detail. Users can cancel PENDING orders; admins can move orders
/// forward through the fulfillment lifecycle.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    final user = ref.watch(sessionProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Order")),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderProvider(orderId)),
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  "#${order.id.substring(0, 8)}",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _DetailStatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMMd().add_jm().format(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SectionHeader(eyebrow: "Pieces", title: "Items"),
            const SizedBox(height: 8),
            for (final item in order.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(
                  "${item.quantity} × ${formatMoney(item.priceAtPurchase)}",
                ),
                trailing: Text(
                  formatMoney(item.lineTotal),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            const Divider(),
            _row(theme, "Subtotal", formatMoney(order.subtotal)),
            _row(theme, "Shipping", formatMoney(order.shippingCost)),
            const Divider(),
            Row(
              children: [
                Text(
                  "Total",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                PriceText(order.total, fontSize: 20),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(eyebrow: "Delivery", title: "Shipping address"),
            const SizedBox(height: 8),
            Text(
              "${order.shippingAddress.recipientName == null ? "" : "${order.shippingAddress.recipientName}\n"}"
              "${order.shippingAddress.singleLine}\n"
              "Label: ${order.shippingAddress.label}\n"
              "Payment: ${order.paymentStatus}",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (user != null && !user.isAdmin && order.canCancel)
              OutlinedButton(
                onPressed: () => _cancel(context, ref),
                child: const Text("Cancel order"),
              ),
            if (user != null && user.isAdmin && order.status != "CANCELLED")
              _AdminStatusControls(order: order),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel order"),
        content: const Text("Cancel this pending order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep it"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cancel order"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(orderRepositoryProvider).cancel(orderId);
      ref.invalidate(orderProvider(orderId));
      ref.invalidate(ordersProvider("ALL"));
      if (context.mounted) {
        showError(context, "Order cancelled.");
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, e.toString());
      }
    }
  }
}

class _DetailStatusPill extends StatelessWidget {
  const _DetailStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      "PAID" || "SHIPPED" || "DELIVERED" => MatjarColors.emerald,
      "CANCELLED" => MatjarColors.danger,
      _ => MatjarColors.goldDeep,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toLowerCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminStatusControls extends ConsumerWidget {
  const _AdminStatusControls({required this.order});

  final Order order;

  static const _next = {
    "PENDING": ["PAID", "CANCELLED"],
    "PAID": ["SHIPPED", "CANCELLED"],
    "SHIPPED": ["DELIVERED"],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final options = _next[order.status] ?? const <String>[];
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "ADMIN · UPDATE STATUS",
          style: theme.textTheme.labelSmall?.copyWith(
            color: MatjarColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            for (final status in options)
              OutlinedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(adminRepositoryProvider)
                        .updateOrderStatus(order.id, status);
                    ref.invalidate(orderProvider(order.id));
                    ref.invalidate(adminOrdersProvider("ALL"));
                    if (context.mounted) {
                      showError(context, "Order marked $status.");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showError(context, e.toString());
                    }
                  }
                },
                child: Text(status.toLowerCase()),
              ),
          ],
        ),
      ],
    );
  }
}