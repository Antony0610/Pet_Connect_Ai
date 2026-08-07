import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed, read-only accessor over the loaded `.env` file.
///
/// `.env` is loaded once at startup by the bootstrapper via
/// `dotenv.load(...)`. NEVER read `dotenv.env` directly elsewhere — always go
/// through [Env] so keys are centralized and typo-safe.
///
/// This class holds NO secrets in source. Real values live only in the
/// developer's / CI's local `.env` (git-ignored). See `.env.example`.
abstract final class Env {
  const Env._();

  static String _get(String key, {String fallback = ''}) =>
      dotenv.maybeGet(key) ?? fallback;

  static bool _getBool(String key, {bool fallback = false}) {
    final raw = dotenv.maybeGet(key)?.toLowerCase().trim();
    if (raw == null || raw.isEmpty) return fallback;
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  // ── App / Flavor ───────────────────────────────────────────────
  static String get appEnv => _get('APP_ENV', fallback: 'dev');
  static String get appName => _get('APP_NAME', fallback: 'PetConnect AI');

  // ── Supabase ───────────────────────────────────────────────────
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // ── Google Maps ────────────────────────────────────────────────
  static String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');

  // ── AI (Gemini via Supabase Edge Function) ─────────────────────
  static String get aiEdgeFunctionUrl => _get('AI_EDGE_FUNCTION_URL');

  // ── Firebase Cloud Messaging ───────────────────────────────────
  static String get fcmSenderId => _get('FCM_SENDER_ID');

  // ── Smart Collar ───────────────────────────────────────────────
  static String get collarIngestUrl => _get('COLLAR_INGEST_URL');

  // ── n8n Automation ─────────────────────────────────────────────
  static String get n8nWebhookBaseUrl => _get('N8N_WEBHOOK_BASE_URL');

  // ── Feature Flags ──────────────────────────────────────────────
  static bool get featureSmartCollar =>
      _getBool('FEATURE_SMART_COLLAR', fallback: true);
  static bool get featureAiAssistant =>
      _getBool('FEATURE_AI_ASSISTANT', fallback: true);
}
