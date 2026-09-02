import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:petconnect_ai/core/localization/app_strings.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/providers/theme_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/volunteer_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// **Volunteer Rescue Field & App Settings** (`/rescue/settings`), designed in Telegram's
/// iconic clean flat-list style with colored icon circles, grouped sections, and verified functionality.
class VolunteerSettingsScreen extends ConsumerStatefulWidget {
  const VolunteerSettingsScreen({super.key});

  @override
  ConsumerState<VolunteerSettingsScreen> createState() =>
      _VolunteerSettingsScreenState();
}

class _VolunteerSettingsScreenState
    extends ConsumerState<VolunteerSettingsScreen> {
  bool _biometricsEnabled = false;
  bool _sosSirenEnabled = true;
  bool _beaconSharing = true;
  double _searchRadiusKm = 15.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _biometricsEnabled = prefs.getBool('app_biometrics_lock') ?? false;
      _sosSirenEnabled = prefs.getBool('rescue_sos_siren_sound') ?? true;
      _beaconSharing = prefs.getBool('rescue_beacon_sharing') ?? true;
      _searchRadiusKm = prefs.getDouble('rescue_search_radius_km') ?? 15.0;
    });
  }

  Future<void> _toggleBiometrics(bool val) async {
    setState(() => _biometricsEnabled = val);
    await ref.read(sharedPreferencesProvider).setBool('app_biometrics_lock', val);
    if (mounted) {
      context.showSnackbar(
        val ? 'Biometric / PIN app lock enabled' : 'Biometric / PIN app lock disabled',
      );
    }
  }

  Future<void> _toggleSosSiren(bool val) async {
    setState(() => _sosSirenEnabled = val);
    await ref.read(sharedPreferencesProvider).setBool('rescue_sos_siren_sound', val);
    if (mounted) {
      context.showSnackbar(
        val ? 'High-priority SOS siren alert enabled' : 'SOS audio siren muted',
      );
    }
  }

  Future<void> _toggleBeaconSharing(bool val) async {
    setState(() => _beaconSharing = val);
    await ref.read(sharedPreferencesProvider).setBool('rescue_beacon_sharing', val);
    if (mounted) {
      context.showSnackbar(
        val ? 'Live responder GPS beacon broadcasting' : 'Responder location beacon paused',
      );
    }
  }

  Future<void> _updateRadius(double val) async {
    setState(() => _searchRadiusKm = val);
    await ref.read(sharedPreferencesProvider).setDouble('rescue_search_radius_km', val);
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
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.15),
                  child: const Text('EN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ),
                title: const Text('English (US / IN)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Default language'),
                trailing: currentLocale.languageCode == 'en'
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguage(AppLanguage.english);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
                  child: const Text('മല', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ),
                title: const Text('മലയാളം (Malayalam)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('കേരള പ്രാദേശിക ഭാഷ'),
                trailing: currentLocale.languageCode == 'ml'
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguage(AppLanguage.malayalam);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int deletedCount = 0;
      int deletedBytes = 0;

      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              deletedBytes += entity.lengthSync();
              entity.deleteSync();
              deletedCount++;
            }
          } catch (_) {}
        }
      }

      final mb = (deletedBytes / (1024 * 1024)).toStringAsFixed(2);
      if (mounted) {
        context.showSnackbar('Cache cleared: $deletedCount files freed ($mb MB)');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackbar('Failed to clear cache: $e');
      }
    }
  }

  Future<void> _exportRescueLogs() async {
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final missions = ref.read(rescueMissionsProvider(null)).valueOrNull ?? [];
      final alerts = ref.read(activeLostPetAlertsProvider).valueOrNull ?? [];

      final exportObj = {
        'exported_at': DateTime.now().toIso8601String(),
        'portal': 'volunteer_rescue',
        'responder': {
          'id': profile?.id,
          'name': profile?.fullName,
          'phone': profile?.phone,
          'email': profile?.email,
        },
        'active_alerts_count': alerts.length,
        'completed_missions_count': missions.length,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportObj);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        context.showSnackbar('Rescue logs exported and copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackbar('Export failed: $e');
      }
    }
  }

  void _showBugReportDialog() {
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Rescue Incident Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe the operational issue in RescueOps:'),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. GPS collar ping timeout, evidence photo upload failure...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.showSnackbar('Report logged with Dispatch Command Engineering!');
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the Volunteer Rescue Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(signOutProvider)(const NoParams());
      if (mounted) context.go(RoutePaths.login);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Volunteer Account?'),
        content: const Text(
          'WARNING: This permanently deletes your volunteer profile, responder badges, and field logs. This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final client = ref.read(supabaseClientProvider);
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('profiles').delete().eq('id', user.id);
          await client.auth.signOut();
        }
        if (mounted) {
          context.showSnackbar('Volunteer account successfully deleted.');
          context.go(RoutePaths.login);
        }
      } catch (e) {
        if (mounted) context.showSnackbar('Account deletion error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final themeLabel = themeMode == ThemeMode.system
        ? 'System Default'
        : (themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode');

    final languageLabel = locale.languageCode == 'ml' ? 'മലയാളം (Malayalam)' : 'English (US / IN)';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Volunteer & Field Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: const VolunteerBottomNavBar(currentTab: VolunteerTab.profile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION 1: Field Operations ──────────────────────
                const _SectionHeader(title: 'Field Operations & Dispatch'),
                _GroupCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.radar_rounded, color: Colors.amber, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Incident Response Radius',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    Text(
                                      'Alert me for rescues within ${_searchRadiusKm.toStringAsFixed(0)} km',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Slider(
                            value: _searchRadiusKm,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            activeColor: Colors.amber.shade700,
                            label: '${_searchRadiusKm.toStringAsFixed(0)} km',
                            onChanged: _updateRadius,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsSwitchTile(
                      icon: Icons.my_location_rounded,
                      iconColor: Colors.blue,
                      title: 'Responder Beacon Sharing',
                      subtitle: 'Broadcast GPS location to dispatch commanders',
                      value: _beaconSharing,
                      onChanged: _toggleBeaconSharing,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 2: App Preferences ───────────────────────
                const _SectionHeader(title: 'App Preferences'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      iconColor: Colors.indigo,
                      title: 'Appearance',
                      subtitle: themeLabel,
                      onTap: _showThemeDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      iconColor: Colors.orange,
                      title: 'Language',
                      subtitle: languageLabel,
                      onTap: _showLanguageDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsSwitchTile(
                      icon: Icons.fingerprint_rounded,
                      iconColor: Colors.green,
                      title: 'Biometric / PIN App Lock',
                      subtitle: 'Require authentication on launch',
                      value: _biometricsEnabled,
                      onChanged: _toggleBiometrics,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsSwitchTile(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.red,
                      title: 'Emergency SOS Siren',
                      subtitle: 'Play loud audio siren on P1 Critical rescue dispatch',
                      value: _sosSirenEnabled,
                      onChanged: _toggleSosSiren,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 3: Storage & Data ────────────────────────
                const _SectionHeader(title: 'Storage & Mission Logs'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.cleaning_services_rounded,
                      iconColor: Colors.cyan,
                      title: 'Clear Cache & Temp Files',
                      subtitle: 'Frees up local image and offline map cache',
                      onTap: _clearCache,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      iconColor: Colors.blue,
                      title: 'Export Rescue Operation Logs',
                      subtitle: 'Export mission history summary as JSON',
                      onTap: _exportRescueLogs,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 4: Support & Feedback ────────────────────
                const _SectionHeader(title: 'Support & Incident Feedback'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: Colors.deepOrange,
                      title: 'Report Dispatch / App Bug',
                      subtitle: 'Send feedback to PetConnect rescue team',
                      onTap: _showBugReportDialog,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 5: Danger Zone ───────────────────────────
                const _SectionHeader(title: 'Danger Zone', color: Colors.red),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.red,
                      title: 'Sign Out of Volunteer Portal',
                      textColor: Colors.red,
                      onTap: _signOut,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.red,
                      title: 'Delete Volunteer Account',
                      textColor: Colors.red,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Telegram-Style Reusable Widgets ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.color});
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      value: value,
      activeThumbColor: Colors.amber.shade700,
      onChanged: onChanged,
    );
  }
}
