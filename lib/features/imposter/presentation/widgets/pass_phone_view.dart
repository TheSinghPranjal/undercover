import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import 'game_button.dart';

/// "Pass the phone to …" – shows nothing secret.
class PassPhoneView extends StatelessWidget {
  const PassPhoneView({
    super.key,
    required this.player,
    required this.isFirst,
    required this.onReady,
    this.title,
    this.message,
    this.emoji = '📱',
    this.animate = true,
  });

  final Player player;
  final bool isFirst;
  final VoidCallback onReady;
  final String? title;
  final String? message;
  final String emoji;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Bouncing(
                      animate: animate,
                      child: Text(emoji, style: const TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title ??
                          (isFirst ? 'GIVE THE PHONE TO' : 'PASS THE PHONE TO'),
                      textAlign: TextAlign.center,
                      style: text.labelLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PlayerAvatar(name: player.name, seed: player.id, size: 72),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(
                        player.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.displayMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message ??
                          'Only ${player.name} should look at this screen 👀',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GameButton(
            label: "I'M READY",
            icon: Icons.visibility_rounded,
            onPressed: onReady,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _Bouncing extends StatefulWidget {
  const _Bouncing({required this.child, required this.animate});

  final Widget child;
  final bool animate;

  @override
  State<_Bouncing> createState() => _BouncingState();
}

class _BouncingState extends State<_Bouncing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate && !_c.isAnimating) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
      child: Transform.rotate(angle: 0.08 * (_c.value - 0.5), child: child),
    ),
    child: ExcludeSemantics(child: widget.child),
  );
}
