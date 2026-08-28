import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/providers/theme_providers.dart';
import 'package:petconnect_ai/core/theme/theme.dart';
import 'package:petconnect_ai/l10n/app_localizations.dart';
import 'package:petconnect_ai/router/app_router.dart';

/// Root widget.
///
/// Consumes the router, locale, and theme from the provider graph. The bootstrapper
/// overrides [appConfigProvider] and [supabaseClientProvider] at the root
/// [ProviderScope] before [runApp], so everything downstream can read them.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentPaletteProvider);
    final locale = ref.watch(localeProvider);
    final config = ref.watch(appConfigProvider);

    final lightTheme = AppTheme.lightWithAccent(accent.primary, accent.container);
    final darkTheme = AppTheme.darkWithAccent(accent.primary, accent.container);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

