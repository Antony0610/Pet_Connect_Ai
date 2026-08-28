import 'package:flutter/material.dart';

/// Centralized bilingual string dictionary supporting real-time English and Malayalam.
class AppStrings {
  const AppStrings._();

  static bool isMalayalam(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ml';
  }

  // ── Settings Strings ──────────────────────────────────────────────
  static String appSettings(BuildContext context) =>
      isMalayalam(context) ? 'ആപ്പ് ക്രമീകരണങ്ങൾ' : 'App Settings';

  static String appearanceTheme(BuildContext context) =>
      isMalayalam(context) ? 'തീം & രൂപഭംഗി' : 'Appearance & Theme';

  static String themeMode(BuildContext context) =>
      isMalayalam(context) ? 'തീം മോഡ്' : 'Theme Mode';

  static String system(BuildContext context) =>
      isMalayalam(context) ? 'സിസ്റ്റം' : 'System';

  static String light(BuildContext context) =>
      isMalayalam(context) ? 'ലൈറ്റ്' : 'Light';

  static String dark(BuildContext context) =>
      isMalayalam(context) ? 'ഡാർക്ക്' : 'Dark';

  static String accentPalette(BuildContext context) =>
      isMalayalam(context) ? 'വർണ്ണ പാലറ്റ്' : 'Accent Color Palette';

  static String languageUnits(BuildContext context) =>
      isMalayalam(context) ? 'ഭാഷ & അളവുകൾ' : 'Language & Units';

  static String appLanguage(BuildContext context) =>
      isMalayalam(context) ? 'ആപ്പ് ഭാഷ' : 'App Language';

  static String measurementUnits(BuildContext context) =>
      isMalayalam(context) ? 'അളവു യൂണിറ്റുകൾ' : 'Measurement Units';

  static String notificationsAlerts(BuildContext context) =>
      isMalayalam(context) ? 'അറിയിപ്പുകൾ & അലേർട്ടുകൾ' : 'Notifications & Alert Settings';

  static String criticalHealthAlerts(BuildContext context) =>
      isMalayalam(context) ? 'അടിയന്തര ആരോഗ്യ അലേർട്ടുകൾ' : 'Critical Health Alerts';

  static String criticalHealthAlertsSub(BuildContext context) =>
      isMalayalam(context)
          ? 'അസാധാരണ ലക്ഷണങ്ങൾ കണ്ടെത്തുമ്പോൾ ഉടൻ മുന്നറിയിപ്പ്'
          : 'Immediate alert when abnormal vital signs are detected';

  static String collarGeofenceAlerts(BuildContext context) =>
      isMalayalam(context) ? 'സ്മാർട്ട് കോളർ & ജിയോഫെൻസ്' : 'Smart Collar & Geofence';

  static String collarGeofenceAlertsSub(BuildContext context) =>
      isMalayalam(context)
          ? 'സുരക്ഷിത മേഖല വിട്ടുപോകുമ്പോഴും താപനില കൂടുമ്പോഴും അറിയിപ്പ്'
          : 'Safe zone exits, high temp and low battery telemetry';

  static String medicationReminders(BuildContext context) =>
      isMalayalam(context) ? 'മരുന്ന് & വാക്സിൻ ഓർമ്മപ്പെടുത്തലുകൾ' : 'Medication & Vaccine Reminders';

  static String medicationRemindersSub(BuildContext context) =>
      isMalayalam(context)
          ? 'കൃത്യസമയത്തുള്ള മരുന്ന് ഡോസുകളും ക്ലിനിക്ക് സന്ദർശനങ്ങളും'
          : 'Scheduled dose alarms and clinic checkup alerts';

  static String communityActivity(BuildContext context) =>
      isMalayalam(context) ? 'കമ്മ്യൂണിറ്റി പ്രവർത്തനങ്ങൾ' : 'Community Social Activity';

  static String communityActivitySub(BuildContext context) =>
      isMalayalam(context)
          ? 'ലൈക്കുകൾ, കമന്റുകൾ, സമീപത്തുള്ള ഇവന്റുകൾ'
          : 'Comments, likes and nearby meetup invites';

  static String securityStorage(BuildContext context) =>
      isMalayalam(context) ? 'സുരക്ഷ & സംഭരണം' : 'Security & Storage';

  static String biometricsLock(BuildContext context) =>
      isMalayalam(context) ? 'ബയോമെട്രിക് / പിൻ ലോക്ക്' : 'Biometric / PIN Lock';

  static String biometricsLockSub(BuildContext context) =>
      isMalayalam(context)
          ? 'ആപ്പ് തുറക്കുമ്പോൾ ഫിംഗർപ്രിന്റ് / ഫെയ്സ് ലോക്ക് ആവശ്യപ്പെടുക'
          : 'Require biometric authentication on app launch';

  static String clearCache(BuildContext context) =>
      isMalayalam(context) ? 'ലോക്കൽ കാഷെ മായ്‌ക്കുക' : 'Clear Local Cache';

  static String clearCacheSub(BuildContext context) =>
      isMalayalam(context)
          ? 'താൽക്കാലിക മാപ്പുകളും ഫോട്ടോകളും ഒഴിവാക്കി മെമ്മറി ഫ്രീ ചെയ്യുക'
          : 'Free up temporary offline maps, photos & telemetry data';

  static String clearBtn(BuildContext context) =>
      isMalayalam(context) ? 'മായ്ക്കുക' : 'Clear';

  static String account(BuildContext context) =>
      isMalayalam(context) ? 'അക്കൗണ്ട്' : 'Account';

  static String signOut(BuildContext context) =>
      isMalayalam(context) ? 'പുറത്തുകടക്കുക' : 'Sign Out';

  static String signOutSub(BuildContext context) =>
      isMalayalam(context)
          ? 'നിങ്ങളുടെ ലോഗിൻ സെഷൻ അവസാനിപ്പിക്കുക'
          : 'Securely log out of your session';

  static String deleteAccount(BuildContext context) =>
      isMalayalam(context) ? 'അക്കൗണ്ട് ഇല്ലാതാക്കുക' : 'Delete Account';

  static String deleteAccountSub(BuildContext context) =>
      isMalayalam(context)
          ? 'എല്ലാ വളർത്തുമൃഗങ്ങളുടെ വിവരങ്ങളും സ്ഥിരമായി നീക്കം ചെയ്യുക'
          : 'Permanently remove your account & all pet records';

  // ── Community Hub Strings ─────────────────────────────────────────
  static String communityHub(BuildContext context) =>
      isMalayalam(context) ? 'കമ്മ്യൂണിറ്റി ഹബ്' : 'Community Hub';

  static String discover(BuildContext context) =>
      isMalayalam(context) ? 'കണ്ടെത്തുക' : 'Discover';

  static String createPost(BuildContext context) =>
      isMalayalam(context) ? 'പോസ്റ്റ് ചെയ്യുക' : 'Create Post';

  static String local(BuildContext context) =>
      isMalayalam(context) ? 'സമീപസ്ഥലം' : 'Local';

  static String lostAndFound(BuildContext context) =>
      isMalayalam(context) ? 'നഷ്ടപ്പെട്ടവ & കണ്ടെത്തിയവ' : 'Lost & Found';

  static String adoption(BuildContext context) =>
      isMalayalam(context) ? 'ദത്തെടുക്കൽ' : 'Adoption';

  static String events(BuildContext context) =>
      isMalayalam(context) ? 'ഇവന്റുകൾ' : 'Events';

  static String allPosts(BuildContext context) =>
      isMalayalam(context) ? 'എല്ലാം' : 'All';

  static String photoMoments(BuildContext context) =>
      isMalayalam(context) ? 'ഫോട്ടോകൾ 📸' : 'Photos 📸';

  static String petHealthCategory(BuildContext context) =>
      isMalayalam(context) ? 'ആരോഗ്യം 🩺' : 'Health 🩺';

  static String questionsCategory(BuildContext context) =>
      isMalayalam(context) ? 'ചോദ്യങ്ങൾ ❓' : 'Questions ❓';

  // ── Smart Collar Strings ──────────────────────────────────────────
  static String smartCollar(BuildContext context) =>
      isMalayalam(context) ? 'സ്മാർട്ട് കോളർ' : 'Smart Collar';

  static String safeZones(BuildContext context) =>
      isMalayalam(context) ? 'സുരക്ഷിത മേഖലകൾ' : 'Safe Zones';

  static String addSafeZone(BuildContext context) =>
      isMalayalam(context) ? 'പുതിയ മേഖല ചേർക്കുക' : 'Add Safe Zone';

  static String liveTelemetry(BuildContext context) =>
      isMalayalam(context) ? 'തത്സമയ ലൊക്കേഷൻ വിവരങ്ങൾ' : 'Live GPS Telemetry';

  static String emergencySiren(BuildContext context) =>
      isMalayalam(context) ? 'എമർജൻസി സൈറൺ' : 'Emergency Siren on Breach';

  // ── AI Assistant Strings ──────────────────────────────────────────
  static String aiAssistant(BuildContext context) =>
      isMalayalam(context) ? 'AI വെറ്ററിനറി അസിസ്റ്റന്റ്' : 'AI Companion Assistant';

  static String askAiAnything(BuildContext context) =>
      isMalayalam(context)
          ? 'നിങ്ങളുടെ പെറ്റിന്റെ ആരോഗ്യത്തെക്കുറിച്ചോ പെരുമാറ്റത്തെക്കുറിച്ചോ ചോദിക്കൂ...'
          : 'Ask anything about pet care, symptoms, diet or training...';
}
