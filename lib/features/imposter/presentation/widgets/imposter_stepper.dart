import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// − n + control for the imposter count.
class ImposterStepper extends StatelessWidget {
  const ImposterStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button(IconData icon, String label, int? next) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton.filledTonal(
        onPressed: next == null ? null : () => onChanged(next),
        icon: Icon(icon),
        iconSize: 26,
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          Icons.remove_rounded,
          'Fewer imposters',
          value > 1 ? value - 1 : null,
        ),
        SizedBox(
          width: 64,
          child: Semantics(
            label: '$value imposter${value == 1 ? '' : 's'}',
            excludeSemantics: true,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: scheme.primary),
              ),
            ),
          ),
        ),
        button(
          Icons.add_rounded,
          'More imposters',
          value < max ? value + 1 : null,
        ),
      ],
    );
  }
}
