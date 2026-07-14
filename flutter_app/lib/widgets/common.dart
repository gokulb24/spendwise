import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A titled Material 3 card used throughout the dashboard.
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const SectionCard(
      {super.key,
      required this.title,
      this.subtitle,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ],
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Small pill label (used for % in the budget table).
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );
}
