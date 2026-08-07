import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/core_providers.dart';
import 'core/providers/theme_providers.dart';
import 'core/theme/theme.dart';
import 'router/app_router.dart';

/// Root widget.
///
/// Consumes the router and theme from the provider graph. The bootstrapper
/// overrides [appConfigProvider] and [supabaseClientProvider] at the root
/// [ProviderScope] before [runApp], so everything downstream can read them.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
