import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/imposter/presentation/providers/providers.dart';
import '../features/imposter/presentation/screens/splash_screen.dart';
import 'theme/app_theme.dart';

class FindTheImposterApp extends ConsumerWidget {
  const FindTheImposterApp({super.key, this.home = const SplashScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Find the Imposter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: home,
    );
  }
}
