import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../providers/providers.dart';
import '../widgets/app_logo.dart';
import '../widgets/game_button.dart';
import 'home_screen.dart';

/// Short logo reveal while the word pack loads and validates.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 1300),
  });

  final Duration minimumDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await Future.wait([
        Future<void>.delayed(widget.minimumDuration),
        ref.read(wordRepositoryProvider.future),
      ]);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _retry() {
    ref.invalidate(wordRepositoryProvider);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Center(
              child: _error != null
                  ? _ErrorState(error: _error!, onRetry: _retry)
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) => Opacity(
                        opacity: t.clamp(0, 1),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * t,
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(size: 140),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'FIND THE',
                            style: text.labelLarge?.copyWith(letterSpacing: 6),
                          ),
                          Text('IMPOSTER', style: text.displayMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Someone knows less than they think.',
                            textAlign: TextAlign.center,
                            style: text.bodyLarge?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('😵', style: TextStyle(fontSize: 64)),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Something went wrong loading the word pack.',
          textAlign: TextAlign.center,
          style: text.titleLarge,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text('$error', style: text.bodySmall),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        GameButton(label: 'TRY AGAIN', onPressed: onRetry),
      ],
    );
  }
}
