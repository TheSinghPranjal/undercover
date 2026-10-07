import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// Rounded surface card with an optional small caps heading.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, required this.child, this.padding});

  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: scheme.primary),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.soft(scheme.primary),
          ),
          child: Material(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
