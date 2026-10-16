import 'package:flutter/material.dart';

import '../main.dart';

/// Shared section header: small gold-accented title with an optional
/// trailing action (e.g. "Browse All" / "View All"). Keeps the home
/// dashboard and other lists visually consistent.
class NurSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const NurSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.auto_awesome,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Nur.s20, Nur.s16, Nur.s20, Nur.s8),
      child: Row(
        children: [
          Icon(icon, size: Nur.s16, color: cs.primary),
          const SizedBox(width: Nur.s8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: cs.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: Nur.s8, vertical: Nur.s4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
