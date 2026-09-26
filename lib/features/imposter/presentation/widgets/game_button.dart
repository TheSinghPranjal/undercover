import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../providers/providers.dart';

enum GameButtonVariant {
  primary,
  secondary,
  ghost,

  /// Glowing violet gradient, for the one big call to action over artwork.
  hero,
}

/// Big, chunky, squishy button used for every main action.
class GameButton extends ConsumerStatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GameButtonVariant variant;
  final bool expand;

  @override
  ConsumerState<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends ConsumerState<GameButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onPressed != null && _pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    ref.read(soundProvider).tap();
    ref.read(hapticsProvider).selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final enabled = widget.onPressed != null;
    final onTap = enabled ? _handleTap : null;
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.button);
    const minSize = Size(64, 58);
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 22),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final Widget button = switch (widget.variant) {
      GameButtonVariant.primary => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
          elevation: enabled ? 3 : 0,
          shadowColor: scheme.primary.withValues(alpha: 0.5),
        ),
        child: label,
      ),
      GameButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.primary, width: 2),
        ),
        child: label,
      ),
      GameButtonVariant.hero => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8F63FF), AppColors.violet, Color(0xFF6A3DF0)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: enabled ? AppShadows.glow(AppColors.violet) : null,
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 62),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: text.labelLarge?.copyWith(
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          child: label,
        ),
      ),
      GameButtonVariant.ghost => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelMedium,
        ),
        child: label,
      ),
    };

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
