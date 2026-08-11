import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/config/flavor.dart';

/// Immutable, validated application configuration assembled from [Env].
///
/// Built once at startup ([AppConfig.fromEnv]) and exposed through Riverpod
/// (`appConfigProvider`). Widgets and services read strongly-typed fields
/// here instead of touching `.env` / [Env] directly.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleMapsApiKey,
    required this.aiEdgeFunctionUrl,
    required this.fcmSenderId,
    required this.collarIngestUrl,
    required this.n8nWebhookBaseUrl,
    required this.featureSmartCollar,
    required this.featureAiAssistant,
  });

  /// Assembles config from the loaded environment.
  factory AppConfig.fromEnv() => AppConfig(
    flavor: Flavor.fromName(Env.appEnv),
    appName: Env.appName,
    supabaseUrl: Env.supabaseUrl,
    supabaseAnonKey: Env.supabaseAnonKey,
    googleMapsApiKey: Env.googleMapsApiKey,
    aiEdgeFunctionUrl: Env.aiEdgeFunctionUrl,
    fcmSenderId: Env.fcmSenderId,
    collarIngestUrl: Env.collarIngestUrl,
    n8nWebhookBaseUrl: Env.n8nWebhookBaseUrl,
    featureSmartCollar: Env.featureSmartCollar,
    featureAiAssistant: Env.featureAiAssistant,
  );

  final Flavor flavor;
  final String appName;

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleMapsApiKey;
  final String aiEdgeFunctionUrl;
  final String fcmSenderId;
  final String collarIngestUrl;
  final String n8nWebhookBaseUrl;

  final bool featureSmartCollar;
  final bool featureAiAssistant;

  bool get isDebuggable => flavor.isDebuggable;

  /// Whether the minimum config required to boot is present.
  bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fields that must be present for the app to function, with human-readable
  /// names — used by the bootstrapper to fail fast with a clear message.
  List<String> get missingRequiredKeys => <String>[
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
  ];
}
