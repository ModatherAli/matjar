import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../auth/session.dart";
import "../shop/cart_repository.dart";
import "../catalog/catalog_repository.dart";
import "../catalog/product_card.dart";

/// Storefront landing: hero, category rail and new arrivals.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    final categories = ref.watch(categoriesProvider);
    final arrivals = ref.watch(productsProvider(const ProductQuery(limit: 4)));
    final theme = Theme.of(context);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MATJAR"),
        actions: [
          IconButton(
            tooltip: "Search",
            onPressed: () => context.go("/shop"),
            icon: const Icon(Icons.search),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: "Cart",
              onPressed: () => context.go("/cart"),
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text("$cartCount"),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    user?.name ?? "Matjar",
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    "Curated pieces, delivered with care.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go("/shop"),
                    child: const Text("Shop the collection"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SectionHeader(
            eyebrow: "Explore",
            title: "Categories",
            action: TextButton(
              onPressed: () => context.go("/shop"),
              child: const Text("See all"),
            ),
          ),
          const SizedBox(height: 16),
          categories.when(
            loading: () => const LoadingGrid(itemCount: 2),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(categoriesProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Text("No categories yet.");
              }
              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = list[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          context.go(
                            Uri(
                              path: "/shop",
                              queryParameters: {"category": category.slug},
                            ).toString(),
                          );
                        },
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                "${category.productCount} pieces",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: MatjarColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SectionHeader(eyebrow: "Just in", title: "New Arrivals"),
          const SizedBox(height: 16),
          arrivals.when(
            loading: () => const LoadingGrid(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(
                productsProvider(const ProductQuery(limit: 4)),
              ),
            ),
            data: (page) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemCount: page.items.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: page.items[index]),
            ),
          ),
          if (user?.isAdmin ?? false) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push("/admin"),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text("Open Admin Atelier"),
            ),
          ],
        ],
      ),
    );
  }
}