import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/config.dart";
import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../../features/auth/session.dart";
import "../shop/cart_repository.dart";
import "catalog_repository.dart";
import "review_repository.dart";

/// Product page: gallery, quantity, add to cart and reviews.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _adding = false;

  Future<void> _addToCart(Product product) async {
    setState(() => _adding = true);
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(product.id, _qty);
      ref.invalidate(cartProvider);
      if (mounted) {
        showError(context, "Added to your bag.");
        setState(() => _qty = 1);
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.slug));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("")),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productProvider(widget.slug)),
        ),
        data: (product) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            _Gallery(images: product.images, title: product.title),
            const SizedBox(height: 20),
            if (product.categoryName != null)
              Text(
                product.categoryName!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              product.title,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (product.ratingCount != null && product.ratingCount! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: MatjarColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    "${product.ratingAverage?.toStringAsFixed(1)} · ${product.ratingCount} reviews",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                PriceText(product.price, fontSize: 26),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 12),
                  Text(
                    formatMoney(product.compareAtPrice!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PillBadge(
                    label: "Save ${product.discountPercent}%",
                    color: MatjarColors.emerald,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (!product.inStock)
              const _PillBadge(label: "Sold out", color: MatjarColors.danger)
            else if (product.isLowStock)
              _PillBadge(
                label: "Only ${product.stockQty} left",
                color: MatjarColors.goldDeep,
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                _QtyStepper(
                  qty: _qty,
                  max: product.inStock ? product.stockQty : 1,
                  onChanged: (value) => setState(() => _qty = value),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        product.inStock && !_adding ? () => _addToCart(product) : null,
                    child: _adding
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text("Add to Bag"),
                  ),
                ),
              ],
            ),
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionHeader(eyebrow: "The piece", title: "Description"),
              const SizedBox(height: 12),
              Text(product.description!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 32),
            _Reviews(product: product),
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.title});

  final List<ProductImage> images;
  final String title;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fallback = Container(
      height: 320,
      decoration: BoxDecoration(
        color: dark ? MatjarColors.onyx : MatjarColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          widget.title.isNotEmpty ? widget.title.substring(0, 1).toUpperCase() : "M",
          style: theme.textTheme.displayLarge?.copyWith(
            color: MatjarColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (widget.images.isEmpty) {
      return fallback;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(widget.images[index].url),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: MatjarColors.sand),
                errorWidget: (context, url, error) => fallback,
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.images.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? MatjarColors.gold
                        : MatjarColors.gold.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.max, required this.onChanged});

  final int qty;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MatjarColors.gold),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text("$qty"),
          IconButton(
            onPressed: qty < max ? () => onChanged(qty + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.product});

  final Product product;

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref, {
    Review? existing,
  }) async {
    final rating = ValueNotifier<int>(existing?.rating ?? 5);
    final comment = TextEditingController(text: existing?.comment);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? "Write a review" : "Edit review"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: rating,
              builder: (context, value, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => rating.value = i,
                      icon: Icon(
                        i <= value ? Icons.star : Icons.star_border,
                        color: MatjarColors.gold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Share your thoughts (optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(existing == null ? "Publish" : "Update"),
          ),
        ],
      ),
    );
    if (saved != true || !context.mounted) {
      return;
    }
    final repo = ref.read(reviewRepositoryProvider);
    try {
      if (existing == null) {
        await repo.create(
          product.id,
          rating: rating.value,
          comment: comment.text.trim(),
        );
      } else {
        await repo.update(
          product.id,
          rating: rating.value,
          comment: comment.text.trim(),
        );
      }
      ref.invalidate(reviewsProvider(product.id));
      ref.invalidate(productProvider(product.slug));
      if (context.mounted) {
        showError(context, "Thank you for your review.");
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _deleteOwn(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete review"),
        content: const Text("Remove your review for this piece?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(reviewRepositoryProvider).delete(product.id);
      ref.invalidate(reviewsProvider(product.id));
      ref.invalidate(productProvider(product.slug));
    } catch (e) {
      if (context.mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider(product.id));
    final user = ref.watch(sessionProvider).value;
    final theme = Theme.of(context);

    return Column(
      children: [
        SectionHeader(
          eyebrow: "Verdicts",
          title: "Reviews",
          action: TextButton(
            onPressed: () => _openDialog(context, ref),
            child: const Text("Write a review"),
          ),
        ),
        const SizedBox(height: 16),
        reviews.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(reviewsProvider(product.id)),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const EmptyView(
                icon: Icons.rate_review_outlined,
                message: "No reviews yet. Be the first to share your verdict.",
              );
            }
            return Column(
              children: [
                for (final review in page.items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review.userName,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (review.userId == user?.id) ...[
                                IconButton(
                                  tooltip: "Edit your review",
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _openDialog(
                                    context,
                                    ref,
                                    existing: review,
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                ),
                                IconButton(
                                  tooltip: "Delete your review",
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _deleteOwn(context, ref),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(
                                  i <= review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: MatjarColors.gold,
                                ),
                            ],
                          ),
                          if (review.comment != null &&
                              review.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(review.comment!),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}