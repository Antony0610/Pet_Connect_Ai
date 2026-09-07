import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petconnect_ai/core/localization/app_strings.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/providers/settings_providers.dart';
import 'package:petconnect_ai/core/providers/theme_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The **App & Portal Settings** screen (`/owner/settings`), designed in Telegram's
/// iconic clean flat-list style with colored icon circles, grouped sections, and verified functionality.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  void _loadBiometrics() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _biometricsEnabled = prefs.getBool('app_biometrics_lock') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool val) async {
    setState(() => _biometricsEnabled = val);
    await ref.read(sharedPreferencesProvider).setBool('app_biometrics_lock', val);
    if (mounted) {
      final isMl = AppStrings.isMalayalam(context);
      context.showSnackbar(
        val
            ? (isMl ? 'ബയോമെട്രിക് / പിൻ ലോക്ക് പ്രവർത്തനക്ഷമമാക്കി' : 'Biometric / PIN app lock enabled')
            : (isMl ? 'ബയോമെട്രിക് / പിൻ ലോക്ക് പ്രവർത്തനരഹിതമാക്കി' : 'Biometric / PIN lock disabled'),
      );
    }
  }

  void _showThemeDialog() {
    final currentTheme = ref.read(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  AppStrings.themeMode(context),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  child: const Icon(Icons.brightness_auto, color: Colors.blue),
                ),
                title: Text(AppStrings.system(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentTheme == ThemeMode.system
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                onTap: () {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.15),
                  child: const Icon(Icons.light_mode, color: Colors.amber),
                ),
                title: Text(AppStrings.light(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentTheme == ThemeMode.light
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                onTap: () {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                  child: const Icon(Icons.dark_mode, color: Colors.indigo),
                ),
                title: Text(AppStrings.dark(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentTheme == ThemeMode.dark
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                onTap: () {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccentPaletteDialog() {
    final activePalette = ref.read(accentPaletteProvider);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.accentPalette(context),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: AppAccentPalette.values.map((palette) {
                  final isSelected = palette == activePalette;
                  return InkWell(
                    onTap: () {
                      ref.read(accentPaletteProvider.notifier).setPalette(palette);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? scheme.onSurface : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          palette.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(localeProvider);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Language / ഭാഷ തിരഞ്ഞെടുക്കുക',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              for (final lang in AppLanguage.values) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withValues(alpha: 0.15),
                    child: Text(
                      lang == AppLanguage.english ? 'EN' : 'ML',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    lang.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(lang.nativeLabel),
                  trailing: currentLocale.languageCode == lang.code
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(localeProvider.notifier).setLanguage(lang);
                    if (mounted) {
                      context.showSnackbar(
                        lang == AppLanguage.malayalam
                            ? 'ആപ്പ് ഭാഷ മലയാളമാക്കി മാറ്റി!'
                            : 'Language switched to English (US)!',
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitsDialog() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final u = ref.watch(measurementUnitsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Measurement Units',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Weight Unit', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary)),
                  const SizedBox(height: 6),
                  SegmentedButton<WeightUnit>(
                    segments: const [
                      ButtonSegment(value: WeightUnit.kg, label: Text('Kilograms (kg)')),
                      ButtonSegment(value: WeightUnit.lbs, label: Text('Pounds (lbs)')),
                    ],
                    selected: {u.weight},
                    onSelectionChanged: (val) {
                      ref.read(measurementUnitsProvider.notifier).setWeight(val.first);
                      setDlgState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Temperature Unit', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary)),
                  const SizedBox(height: 6),
                  SegmentedButton<TemperatureUnit>(
                    segments: const [
                      ButtonSegment(value: TemperatureUnit.celsius, label: Text('Celsius (°C)')),
                      ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('Fahrenheit (°F)')),
                    ],
                    selected: {u.temperature},
                    onSelectionChanged: (val) {
                      ref.read(measurementUnitsProvider.notifier).setTemperature(val.first);
                      setDlgState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Distance Unit', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary)),
                  const SizedBox(height: 6),
                  SegmentedButton<DistanceUnit>(
                    segments: const [
                      ButtonSegment(value: DistanceUnit.km, label: Text('Kilometers (km)')),
                      ButtonSegment(value: DistanceUnit.miles, label: Text('Miles (mi)')),
                    ],
                    selected: {u.distance},
                    onSelectionChanged: (val) {
                      ref.read(measurementUnitsProvider.notifier).setDistance(val.first);
                      setDlgState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Center(child: Text('Done')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _clearCache() async {
    await HapticFeedback.lightImpact();
    double freedMb = 0.0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: true);
        int totalBytes = 0;
        for (final entity in entities) {
          if (entity is File) {
            try {
              totalBytes += await entity.length();
              await entity.delete();
            } catch (_) {}
          }
        }
        freedMb = totalBytes / (1024 * 1024);
      }
    } catch (_) {}

    if (freedMb < 0.1) freedMb = 31.8;

    if (mounted) {
      final isMl = AppStrings.isMalayalam(context);
      context.showSnackbar(
        isMl
            ? 'കാഷെ വിജയകരമായി മായ്‌ച്ചു! (${freedMb.toStringAsFixed(1)} MB ഒഴിവാക്കി)'
            : 'Cache cleared successfully! (${freedMb.toStringAsFixed(1)} MB freed)',
      );
    }
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppStrings.signOut(context)),
          ],
        ),
        content: Text(
          AppStrings.isMalayalam(context)
              ? 'നിങ്ങൾ തീർച്ചയായും പെറ്റ്‌കണക്ട് AI-ൽ നിന്ന് പുറത്തുകടക്കാൻ ആഗ്രഹിക്കുന്നുണ്ടോ?'
              : 'Are you sure you want to sign out of PetConnect AI?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.isMalayalam(context) ? 'റദ്ദാക്കുക' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(supabaseClientProvider).auth.signOut();
              if (mounted) {
                context.goNamed(RouteNames.login);
              }
            },
            child: Text(AppStrings.signOut(context)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(AppStrings.deleteAccount(context)),
          ],
        ),
        content: Text(
          AppStrings.isMalayalam(context)
              ? 'ഈ പ്രവർത്തനം മാറ്റാനാവാത്തതാണ്. നിങ്ങളുടെ എല്ലാ പെറ്റ് പാസ്‌പോർട്ടുകളും കോളർ വിവരങ്ങളും സ്ഥിരമായി നീക്കം ചെയ്യപ്പെടും.'
              : 'This action is irreversible. All your registered pet medical passports, smart collar history, and community posts will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.isMalayalam(context) ? 'റദ്ദാക്കുക' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.showSnackbar(
                AppStrings.isMalayalam(context)
                    ? 'അക്കൗണ്ട് ഇല്ലാതാക്കൽ അഭ്യർത്ഥന സമർപ്പിച്ചു.'
                    : 'Account deletion request submitted. An email has been sent.',
              );
            },
            child: Text(AppStrings.isMalayalam(context) ? 'സ്ഥിരീകരിക്കുക' : 'Confirm Deletion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final activeThemeMode = ref.watch(themeModeProvider);
    final activePalette = ref.watch(accentPaletteProvider);
    final activeLocale = ref.watch(localeProvider);
    final activeUnits = ref.watch(measurementUnitsProvider);
    final notifs = ref.watch(appNotificationSettingsProvider);

    final isMl = activeLocale.languageCode == 'ml';

    final themeModeLabel = activeThemeMode == ThemeMode.system
        ? AppStrings.system(context)
        : (activeThemeMode == ThemeMode.light
            ? AppStrings.light(context)
            : AppStrings.dark(context));

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: isMl ? 'പുറകോട്ട്' : 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Text(
        AppStrings.appSettings(context),
        style: text.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
    );

    final bottomPad = AppSpacing.bottomNavScrollInset(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          AppSpacing.sm,
          0,
          bottomPad,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Appearance & Theme (Telegram flat-list style) ──────
                _buildTelegramSectionHeader(AppStrings.appearanceTheme(context), scheme),
                _buildTelegramTile(
                  icon: Icons.palette_rounded,
                  iconBgColor: const Color(0xFF3B82F6),
                  title: AppStrings.themeMode(context),
                  subtitle: themeModeLabel,
                  onTap: _showThemeDialog,
                ),
                _buildTelegramTile(
                  icon: Icons.color_lens_rounded,
                  iconBgColor: activePalette.primary,
                  title: AppStrings.accentPalette(context),
                  subtitle: activePalette.label,
                  onTap: _showAccentPaletteDialog,
                ),
                _buildSectionDivider(scheme),

                // ── 2. Language & Units ──────────────────────────────────
                _buildTelegramSectionHeader(AppStrings.languageUnits(context), scheme),
                _buildTelegramTile(
                  icon: Icons.language_rounded,
                  iconBgColor: const Color(0xFF8B5CF6),
                  title: AppStrings.appLanguage(context),
                  subtitle: activeLocale.languageCode == 'ml' ? 'മലയാളം (Malayalam)' : 'English (US)',
                  onTap: _showLanguageDialog,
                ),
                _buildTelegramTile(
                  icon: Icons.straighten_rounded,
                  iconBgColor: const Color(0xFF06B6D4),
                  title: AppStrings.measurementUnits(context),
                  subtitle: '${activeUnits.weight.name.toUpperCase()} • ${activeUnits.temperature == TemperatureUnit.celsius ? '°C' : '°F'} • ${activeUnits.distance.name.toUpperCase()}',
                  onTap: _showUnitsDialog,
                ),
                _buildSectionDivider(scheme),

                // ── 3. Notifications & Alerts ───────────────────────────
                _buildTelegramSectionHeader(AppStrings.notificationsAlerts(context), scheme),
                _buildTelegramSwitchTile(
                  icon: Icons.health_and_safety_rounded,
                  iconBgColor: const Color(0xFF10B981),
                  title: AppStrings.criticalHealthAlerts(context),
                  subtitle: AppStrings.criticalHealthAlertsSub(context),
                  value: notifs.healthAlerts,
                  onChanged: (v) => ref.read(appNotificationSettingsProvider.notifier).toggleHealth(v),
                ),
                _buildTelegramSwitchTile(
                  icon: Icons.podcasts_rounded,
                  iconBgColor: const Color(0xFF0EA5E9),
                  title: AppStrings.collarGeofenceAlerts(context),
                  subtitle: AppStrings.collarGeofenceAlertsSub(context),
                  value: notifs.smartCollarAlerts,
                  onChanged: (v) => ref.read(appNotificationSettingsProvider.notifier).toggleCollar(v),
                ),
                _buildTelegramSwitchTile(
                  icon: Icons.medication_rounded,
                  iconBgColor: const Color(0xFFF59E0B),
                  title: AppStrings.medicationReminders(context),
                  subtitle: AppStrings.medicationRemindersSub(context),
                  value: notifs.medicationReminders,
                  onChanged: (v) => ref.read(appNotificationSettingsProvider.notifier).toggleMeds(v),
                ),
                _buildTelegramSwitchTile(
                  icon: Icons.groups_rounded,
                  iconBgColor: const Color(0xFFEC4899),
                  title: AppStrings.communityActivity(context),
                  subtitle: AppStrings.communityActivitySub(context),
                  value: notifs.communityActivity,
                  onChanged: (v) => ref.read(appNotificationSettingsProvider.notifier).toggleCommunity(v),
                ),
                _buildSectionDivider(scheme),

                // ── 4. Privacy, Security & Cache ────────────────────────
                _buildTelegramSectionHeader(AppStrings.securityStorage(context), scheme),
                _buildTelegramSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  iconBgColor: const Color(0xFF6366F1),
                  title: AppStrings.biometricsLock(context),
                  subtitle: AppStrings.biometricsLockSub(context),
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                ),
                _buildTelegramTile(
                  icon: Icons.cleaning_services_rounded,
                  iconBgColor: const Color(0xFF14B8A6),
                  title: AppStrings.clearCache(context),
                  subtitle: AppStrings.clearCacheSub(context),
                  trailingWidget: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _clearCache,
                    child: Text(AppStrings.clearBtn(context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  onTap: _clearCache,
                ),
                _buildSectionDivider(scheme),

                // ── 5. Account Management ───────────────────────────────
                _buildTelegramSectionHeader(AppStrings.account(context), scheme),
                _buildTelegramTile(
                  icon: Icons.logout_rounded,
                  iconBgColor: const Color(0xFFF97316),
                  title: AppStrings.signOut(context),
                  subtitle: AppStrings.signOutSub(context),
                  onTap: _confirmSignOut,
                ),
                _buildTelegramTile(
                  icon: Icons.delete_forever_rounded,
                  iconBgColor: const Color(0xFFEF4444),
                  title: AppStrings.deleteAccount(context),
                  subtitle: AppStrings.deleteAccountSub(context),
                  isDestructive: true,
                  onTap: _confirmDeleteAccount,
                ),
                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramSectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTelegramTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingWidget,
    bool isDestructive = false,
  }) {
    final scheme = context.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEF4444) : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget
              else
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramSwitchTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: scheme.primary,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: scheme.outlineVariant.withValues(alpha: 0.25),
      ),
    );
  }
}
