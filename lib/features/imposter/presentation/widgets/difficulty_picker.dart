import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/enums/difficulty.dart';
import 'labels.dart';

/// Three big selectable difficulty cards.
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final d in Difficulty.values) ...[
              if (d != Difficulty.values.first)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: d == value,
                  label: '${d.label} difficulty',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onChanged(d),
                    child: AnimatedContainer(
                      duration: AppDurations.medium,
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: d == value
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: AppRadius.button,
                        border: Border.all(
                          color: d == value
                              ? scheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      transform: Matrix4.diagonal3Values(
                        d == value ? 1.0 : 0.96,
                        d == value ? 1.0 : 0.96,
                        1,
                      ),
                      transformAlignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(d.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: AppSpacing.xs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              d.label,
                              style: text.titleSmall?.copyWith(
                                color: d == value
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                          if (d == value)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: scheme.onPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: AppDurations.fast,
          child: Text(
            value.blurb,
            key: ValueKey(value),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
