import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/playful_ui.dart';
import '../widgets/round_ready_view.dart';

/// All the rules on one screen, over the game-night illustration.
///
/// The artwork is bright, so colours are fixed rather than theme-driven. The
/// steps sit above the characters in the art and the button over the table,
/// leaving the friends visible in between.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _steps = [
    ('👥', 'ADD PLAYERS', "Enter everyone's name."),
    ('🤫', 'REVEAL', 'Pass the phone around and secretly reveal your card.'),
    (
      '🗣️',
      'GIVE CLUES',
      'Everyone describes the secret word – without saying it.',
    ),
    ('🕵️', 'FIND THE IMPOSTER', 'Discuss and figure out who is bluffing.'),
    ('🔥', 'NEW ROUND', 'Start another round with one tap.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PlayfulColors.page,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              RoundReadyView.backgroundAsset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            // Lifts the top of the art so the title and steps read clearly.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x552B2656), Color(0x00FFFFFF)],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  // Keeps the layout phone-shaped on tablets.
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: RoundIconButton(
                                      icon: Icons.chevron_left_rounded,
                                      tooltip: 'Back',
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(36, 18, 36, 0),
                                    child: Center(
                                      child: BubbleTitle(
                                        top: 'HOW TO',
                                        bottom: 'PLAY',
                                        semanticsLabel: 'How to play',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const _StepsCard(steps: _steps),
                              // Room for the characters in the artwork.
                              const Spacer(),
                              const SizedBox(height: 32),
                              PillButton(
                                label: 'GOT IT!',
                                icon: Icons.check_rounded,
                                primary: true,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<(String, String, String)> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: PlayfulColors.ink.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEDE1CB)),
            _StepRow(
              number: i + 1,
              emoji: steps[i].$1,
              title: steps[i].$2,
              body: steps[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.emoji,
    required this.title,
    required this.body,
  });

  final int number;
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE8FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                Positioned(
                  left: -6,
                  top: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: PlayfulColors.primaryGradient,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: PlayfulColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: PlayfulColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
