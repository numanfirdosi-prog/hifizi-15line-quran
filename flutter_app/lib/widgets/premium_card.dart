import 'package:flutter/material.dart';

/// Shared premium card: theme surface, generous radius, and a subtle
/// translucent border (gold on the dark Night Slate theme, deep green on
/// the light themes) for a consistent premium look everywhere.
///
/// Set [goldAccent] for cards that carry the most important content
/// (Last Read, Ayah of the Day); otherwise the neutral green border is used.
class NurCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final bool goldAccent;
  final VoidCallback? onTap;

  const NurCard({
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.goldAccent = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = goldAccent
        ? cs.primary.withValues(alpha: 0.45)
        : isDark
            ? cs.primary.withValues(alpha: 0.20)
            : cs.outline.withValues(alpha: 0.55);
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: goldAccent ? 1.25 : 1),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
