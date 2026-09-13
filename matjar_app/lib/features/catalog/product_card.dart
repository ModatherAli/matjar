import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../core/config.dart";
import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";

/// Luxury product card. Seed data has no images, so the empty state is an
/// intentional gold-on-charcoal monogram tile.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});

  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final image = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: product.coverImage == null
            ? Container(
                color: dark ? MatjarColors.onyx : MatjarColors.sand,
                child: Center(
                  child: Text(
                    product.title.isNotEmpty
                        ? product.title.substring(0, 1).toUpperCase()
                        : "M",
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: MatjarColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(product.coverImage!),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: MatjarColors.sand),
                errorWidget: (context, url, error) => Container(
                  color: dark ? MatjarColors.onyx : MatjarColors.sand,
                  child: const Icon(Icons.image_outlined,
                      color: MatjarColors.gold),
                ),
              ),
      ),
    );

    final badges = <Widget>[];
    if (product.hasDiscount) {
      badges.add(_Pill(label: "-${product.discountPercent}%"));
    }
    if (!product.inStock) {
      badges.add(const _Pill(label: "Sold out"));
    } else if (product.isLowStock) {
      badges.add(_Pill(label: "Only ${product.stockQty} left"));
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push("/product/${product.slug}"),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Positioned.fill(child: image),
                  if (badges.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: badges,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: MatjarColors.gold,
                          fontSize: 9,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PriceText(product.price, fontSize: 15),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatMoney(product.compareAtPrice!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MatjarColors.charcoal.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: MatjarColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}