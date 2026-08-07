import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';
import 'core/utils/logger.dart';

/// Initializes all app dependencies and runs the widget tree.
///
/// Called once from `main()`. Loads `.env`, validates config, initializes
/// Supabase, and mounts the root [ProviderScope] with overrides for the
/// concrete [AppConfig] and [SupabaseClient] so the DI graph can resolve them.
///
/// If anything fails during bootstrap (missing keys, Supabase init error),
/// the app displays a full-screen error rather than proceeding.
Future<void> bootstrap() async {
  // ── Flutter binding ────────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Error handling (pre-runApp) ────────────────────────────────
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());
  };

  // ── Load .env ──────────────────────────────────────────────────
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    _showFatalError('Failed to load .env file. Did you copy .env.example?');
    return;
  }

  // ── Assemble config ────────────────────────────────────────────
  final config = AppConfig.fromEnv();
  final logger = AppLogger(isDebuggable: config.isDebuggable);

  // Validate required keys
  if (!config.hasValidSupabaseConfig) {
    _showFatalError(
      'Missing required environment variables:\n'
      '${config.missingRequiredKeys.join(', ')}\n\n'
      'Check your .env file.',
    );
    return;
  }

  logger.info('🚀 Bootstrapping ${config.appName} (${config.flavor.name})');

  // ── Initialize Supabase ────────────────────────────────────────
  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      // The project's .env supplies a legacy anon key (JWT format). Migrating
      // to `publishableKey` requires rotating to the new `sb_publishable_…`
      // key format first; tracked for a later backend task.
      // ignore: deprecated_member_use
      anonKey: config.supabaseAnonKey,
      debug: config.isDebuggable,
    );
    logger.info('✓ Supabase initialized');
  } catch (e, stack) {
    logger.error('✗ Supabase initialization failed', e, stack);
    _showFatalError('Failed to connect to backend.\n\n$e');
    return;
  }

  // ── Local key/value storage ────────────────────────────────────
  final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    logger.info('✓ SharedPreferences ready');
  } catch (e, stack) {
    logger.error('✗ SharedPreferences initialization failed', e, stack);
    _showFatalError('Failed to initialize local storage.\n\n$e');
    return;
  }

  // ── Run app ────────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        // Override the stub providers with the real initialized instances.
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

/// Displays a full-screen error when bootstrap fails.
void _showFatalError(String message) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
                const SizedBox(height: 24),
                Text(
                  'Startup Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
