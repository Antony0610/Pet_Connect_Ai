import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petconnect_ai/core/config/app_config.dart';
import 'package:petconnect_ai/core/network/dio_client.dart';
import 'package:petconnect_ai/core/network/network_info.dart';
import 'package:petconnect_ai/core/utils/logger.dart';

/// Core dependency-injection providers.
///
/// PetConnect AI uses **Riverpod as its DI container** (no `get_it`). These
/// are the app-wide singletons every feature builds on. Feature-level state
/// providers use `@riverpod` codegen; these foundational singletons are plain
/// providers so they compile without a build step and read clearly.
///
/// [appConfigProvider] and [supabaseClientProvider] are declared here but
/// **overridden** at the root `ProviderScope` in `bootstrap.dart` with the
/// concrete instances created during startup.

/// Overridden in `bootstrap.dart` with the config loaded from `.env`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in the root ProviderScope',
  ),
);

/// The app's [SharedPreferences] instance for simple local key/value state
/// (e.g. the onboarding-seen flag). Resolved once in `bootstrap.dart` and
/// **overridden** at the root `ProviderScope`, so reads are synchronous
/// everywhere downstream.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in the root ProviderScope',
  ),
);

/// App-wide logger, verbosity keyed to the active flavor.
final loggerProvider = Provider<AppLogger>(
  (ref) => AppLogger(isDebuggable: ref.watch(appConfigProvider).isDebuggable),
);

/// The `connectivity_plus` singleton.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Connectivity abstraction used by repositories.
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);

/// Reactive connectivity stream (`true` == connected).
final connectivityStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(networkInfoProvider).onConnectivityChanged,
);

/// Configured Dio client for non-Supabase HTTP (Edge Functions, n8n, etc.).
final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    logger: ref.watch(loggerProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

/// The initialized [SupabaseClient].
///
/// `Supabase.initialize(...)` runs once in `bootstrap.dart`; this exposes the
/// resulting client to the provider graph. Overridden at the root scope after
/// initialization completes.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Auth state changes emitted by Supabase (sign-in / sign-out / refresh).
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);
