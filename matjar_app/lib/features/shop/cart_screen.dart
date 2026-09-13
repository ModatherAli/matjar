import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "cart_repository.dart";

/// Shopping bag: quantity steppers, remove, clear and checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _mutate(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(cartProvider);
    } catch (e) {
      if (context.mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Bag"),
        actions: [
          cartAsync.maybeWhen(
            data: (cart) => cart.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: "Clear bag",
                    onPressed: () => _mutate(
                      context,
                      ref,
                      () => ref.read(cartRepositoryProvider).clearCart(),
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return EmptyView(
              icon: Icons.shopping_bag_outlined,
              message: "Your bag is empty.",
              action: FilledButton(
                onPressed: () => context.go("/shop"),
                child: const Text("Browse the collection"),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final item in cart.items)
                      _CartRow(
                        item: item,
                        onRemove: () => _mutate(
                          context,
                          ref,
                          () =>
                              ref.read(cartRepositoryProvider).removeItem(item.id),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Subtotal",
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        PriceText(cart.subtotal),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${cart.itemCount} item(s) · complimentary shipping",
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => context.push("/checkout"),
                      child: const Text("Proceed to Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  Future<void> _updateQty(BuildContext context, WidgetRef ref, int qty) async {
    try {
      await ref.read(cartRepositoryProvider).updateItem(item.id, qty);
      ref.invalidate(cartProvider);
    } catch (e) {
      if (context.mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = item.product;
    final unavailable = !product.isActive || product.stockQty <= 0;
    final overStock = item.quantity > product.stockQty;
    final dark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? MatjarColors.onyx : MatjarColors.sand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                product.title.isNotEmpty
                    ? product.title.substring(0, 1).toUpperCase()
                    : "M",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (unavailable || overStock)
                    Text(
                      unavailable
                          ? "This piece is no longer available."
                          : "Only ${product.stockQty} in stock.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else
                    Text(
                      "${formatMoney(product.price)} each",
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: MatjarColors.gold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed:
                                  item.quantity > 1 && !unavailable && !overStock
                                      ? () =>
                                          _updateQty(context, ref, item.quantity - 1)
                                      : null,
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text("${item.quantity}"),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed:
                                  !unavailable && item.quantity < product.stockQty
                                      ? () =>
                                          _updateQty(context, ref, item.quantity + 1)
                                      : null,
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatMoney(item.lineTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: MatjarColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: "Remove",
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}