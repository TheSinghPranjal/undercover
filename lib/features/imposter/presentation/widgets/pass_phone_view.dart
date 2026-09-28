import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import 'playful_ui.dart';

/// "Pass the phone to …" – shows nothing secret.
///
/// The suspects from the home art peek over the name card. Drawn over the
/// lavender [PlayfulBackground] (see the round flow screen), so it always
/// uses the light palette.
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

  static const suspectsAsset = 'assets/images/pass_phone_suspects.webp';
  static const _suspectsAspect = 941 / 396;

  final Player player;
  final bool isFirst;
  final VoidCallback onReady;
  final String? title;
  final String? message;
  final String emoji;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Center(
        child: ConstrainedBox(
          // Keeps the layout phone-shaped on tablets.
          constraints: const BoxConstraints(maxWidth: 560),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      // The art bleeds into the side gutters.
                      Transform.scale(
                        scale: 1.12,
                        child: const AspectRatio(
                          aspectRatio: _suspectsAspect,
                          child: ExcludeSemantics(
                            child: Image(
                              image: AssetImage(suspectsAsset),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Pull the card up over the faded bottom of the art so
                      // the suspects peek over it.
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: _NameCard(
                          player: player,
                          emoji: emoji,
                          animate: animate,
                          title:
                              title ??
                              (isFirst
                                  ? 'GIVE THE PHONE TO'
                                  : 'PASS THE PHONE TO'),
                          message:
                              message ??
                              'Only ${player.name} should look at this screen 👀',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Sparks(
                            color: PlayfulColors.yellow,
                            mirrored: true,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PillButton(
                              label: "I'M READY",
                              icon: Icons.visibility_rounded,
                              primary: true,
                              onPressed: onReady,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Sparks(color: PlayfulColors.yellow),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({
    required this.player,
    required this.emoji,
    required this.animate,
    required this.title,
    required this.message,
  });

  final Player player;
  final String emoji;
  final bool animate;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: PlayfulColors.accent.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _Bouncing(
            animate: animate,
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: PlayfulColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(name: player.name, seed: player.id, size: 56),
              const SizedBox(width: 14),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    player.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: PlayfulColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: PlayfulColors.muted,
              ),
            ),
          ),
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
      offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
      child: Transform.rotate(angle: 0.08 * (_c.value - 0.5), child: child),
    ),
    child: ExcludeSemantics(child: widget.child),
  );
}
