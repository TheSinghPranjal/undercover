import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../widgets/game_button.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.of(context).pop();
    } else {
      _controller.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOW TO PLAY'),
        actions: [
          if (!last)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('SKIP'),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, i) {
                      final (emoji, title, body) = _pages[i];
                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                '${i + 1}. $title',
                                textAlign: TextAlign.center,
                                style: text.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Semantics(
                  label: 'Page ${_page + 1} of ${_pages.length}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: AppDurations.fast,
                          margin: const EdgeInsets.all(4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.pill,
                            color: i == _page
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GameButton(label: last ? 'GOT IT!' : 'NEXT', onPressed: _next),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
