import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's selected [ThemeMode].
///
/// Defaults to [ThemeMode.system]. Persistence (writing the choice to local
/// storage and restoring it on launch) is intentionally left as a TODO for
/// the settings feature — the notifier's API won't change when it's added.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;

  void toggle() {
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
  }
}

/// The active [ThemeMode] for `MaterialApp.themeMode`.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
