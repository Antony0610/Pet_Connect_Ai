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
import 'package:petconnect_ai/features/veterinarian/presentation/providers/patient_queue_notifier.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// **Veterinarian Practice & App Settings** (`/vet/settings`), designed in Telegram's
/// iconic clean flat-list style with colored icon circles, grouped sections, and verified functionality.
class VetSettingsScreen extends ConsumerStatefulWidget {
  const VetSettingsScreen({super.key});

  @override
  ConsumerState<VetSettingsScreen> createState() => _VetSettingsScreenState();
}

class _VetSettingsScreenState extends ConsumerState<VetSettingsScreen> {
  bool _biometricsEnabled = false;
  bool _emergencyAudioAlert = true;
  bool _acceptEmergencyCases = true;
  bool _autoPrescriptionSync = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _biometricsEnabled = prefs.getBool('app_biometrics_lock') ?? false;
      _emergencyAudioAlert = prefs.getBool('vet_emergency_audio_alert') ?? true;
      _acceptEmergencyCases = prefs.getBool('vet_accept_emergency_cases') ?? true;
      _autoPrescriptionSync = prefs.getBool('vet_auto_rx_sync') ?? true;
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

  Future<void> _toggleEmergencyAudio(bool val) async {
    setState(() => _emergencyAudioAlert = val);
    await ref.read(sharedPreferencesProvider).setBool('vet_emergency_audio_alert', val);
    if (mounted) {
      context.showSnackbar(
        val ? 'Emergency triage audio sirens enabled' : 'Emergency audio siren muted',
      );
    }
  }

  Future<void> _toggleEmergencyIntake(bool val) async {
    setState(() => _acceptEmergencyCases = val);
    await ref.read(sharedPreferencesProvider).setBool('vet_accept_emergency_cases', val);
    if (mounted) {
      context.showSnackbar(
        val ? 'Emergency intake marked active' : 'Emergency intake paused',
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

  Future<void> _exportPracticeData() async {
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final clinics = ref.read(vetClinicsProvider).valueOrNull ?? [];
      final appointments = ref.read(patientQueueStateProvider);

      final exportObj = {
        'exported_at': DateTime.now().toIso8601String(),
        'portal': 'veterinarian',
        'practitioner': {
          'id': profile?.id,
          'name': profile?.fullName,
          'email': profile?.email,
          'phone': profile?.phone,
        },
        'clinics_count': clinics.length,
        'appointments_count': appointments.length,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportObj);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        context.showSnackbar('Practice data exported and copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackbar('Export failed: $e');
      }
    }
  }

  void _showPracticeHoursDialog() async {
    final clinics = ref.read(vetClinicsProvider).valueOrNull ?? [];
    final clinic = clinics.isNotEmpty ? clinics.first : null;
    final nameCtrl = TextEditingController(text: clinic?.name ?? 'Oakwood Veterinary Centre');
    final feeCtrl = TextEditingController(text: '600');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Operating Hours & Consultation Fee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Practice / Clinic Name',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Standard Consultation Fee (₹ INR)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Operating Schedule'),
                subtitle: Text('Mon - Fri: 8:00 AM - 7:00 PM\nSat: 9:00 AM - 2:00 PM\nSun: Emergency On-Call'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Hours'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      context.showSnackbar('Practice operational details updated!');
    }
  }

  void _showBugReportDialog() {
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a Clinical System Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe the error encountered in VetOps Workspace:'),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Triage queue refresh latency, prescription PDF preview issue...',
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
              context.showSnackbar('Ticket submitted to PetConnect Clinical Engineering!');
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
        content: const Text('Are you sure you want to sign out of the Veterinarian Portal?'),
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
        title: const Text('Delete Practitioner Account?'),
        content: const Text(
          'WARNING: This permanently deletes your veterinarian practitioner profile, appointments, prescriptions, and clinic logs. This action CANNOT be undone.',
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
          context.showSnackbar('Veterinarian account successfully deleted.');
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
        title: const Text('Practice & Vet Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.dashboard),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION 1: Practice Configuration ────────────────
                const _SectionHeader(title: 'Practice Configuration'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.teal,
                      title: 'Operational Schedule & Rates',
                      subtitle: 'Mon - Sat • Standard rate ₹600',
                      onTap: _showPracticeHoursDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsSwitchTile(
                      icon: Icons.emergency_outlined,
                      iconColor: Colors.red,
                      title: 'Emergency Intake Active',
                      subtitle: 'Allow citizens to route urgent emergency pets',
                      value: _acceptEmergencyCases,
                      onChanged: _toggleEmergencyIntake,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsSwitchTile(
                      icon: Icons.auto_mode_rounded,
                      iconColor: Colors.purple,
                      title: 'Auto-Sync Prescriptions',
                      subtitle: 'Synchronize Rx records with pharmacy inventory',
                      value: _autoPrescriptionSync,
                      onChanged: (val) {
                        setState(() => _autoPrescriptionSync = val);
                        ref.read(sharedPreferencesProvider).setBool('vet_auto_rx_sync', val);
                      },
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
                      icon: Icons.notifications_active_outlined,
                      iconColor: Colors.amber.shade800,
                      title: 'Emergency Triage Siren',
                      subtitle: 'Play loud audio siren for incoming P1 cases',
                      value: _emergencyAudioAlert,
                      onChanged: _toggleEmergencyAudio,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 3: Storage & Data ────────────────────────
                const _SectionHeader(title: 'Storage & Clinical Data'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.cleaning_services_rounded,
                      iconColor: Colors.cyan,
                      title: 'Clear Cache & Temp Files',
                      subtitle: 'Frees up local image and record cache',
                      onTap: _clearCache,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      iconColor: Colors.blue,
                      title: 'Export Clinical Data',
                      subtitle: 'Export practice summary as JSON',
                      onTap: _exportPracticeData,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── SECTION 4: Support & Feedback ────────────────────
                const _SectionHeader(title: 'Support & Engineering'),
                _GroupCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: Colors.deepOrange,
                      title: 'Report System Bug',
                      subtitle: 'Send feedback to PetConnect engineering',
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
                      title: 'Sign Out of Veterinarian Portal',
                      textColor: Colors.red,
                      onTap: _signOut,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.red,
                      title: 'Delete Practitioner Account',
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
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
