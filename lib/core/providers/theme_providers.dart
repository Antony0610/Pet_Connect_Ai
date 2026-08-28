import 'package:flutter/material.dart';
import 'package:petconnect_ai/core/providers/settings_providers.dart';

export 'package:petconnect_ai/core/providers/settings_providers.dart'
    show AppAccentPalette, AppLanguage, appThemeModeProvider, accentPaletteProvider, localeProvider;

/// The active [ThemeMode] for `MaterialApp.themeMode` (persisted in SharedPreferences).
final themeModeProvider = appThemeModeProvider;

