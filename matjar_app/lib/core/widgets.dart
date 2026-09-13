import "package:flutter/material.dart";
import "package:shimmer/shimmer.dart";

import "theme.dart";

/// Eyebrow label + serif title block used across screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
  });

  final String eyebrow;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Gold hairline divider used as a luxury accent.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key, this.width = 56});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: MatjarColors.gold,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Friendly empty state with icon + message.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MatjarColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(icon, size: 36, color: MatjarColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.error_outline,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: const Text("Retry")),
    );
  }
}

/// Shimmer placeholder grid while content loads.
class LoadingGrid extends StatelessWidget {
  const LoadingGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.withValues(alpha: 0.25),
          highlightColor: Colors.grey.withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}

/// Gold price label used on product cards and detail pages.
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.fontSize = 18});

  final double amount;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      "\$${amount.toStringAsFixed(2)}",
      style: theme.textTheme.titleLarge?.copyWith(
        color: MatjarColors.gold,
        fontWeight: FontWeight.w800,
        fontSize: fontSize,
      ),
    );
  }
}

/// Shows a floating error message.
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}




