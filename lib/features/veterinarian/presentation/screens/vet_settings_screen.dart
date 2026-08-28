import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Veterinarian Settings Screen.
///
/// Comprehensive practice and practitioner configuration:
/// clinic operational hours, consultation fee, emergency telemetry alerts,
/// and digital prescription auto-signature.
class VetSettingsScreen extends StatefulWidget {
  const VetSettingsScreen({super.key});

  @override
  State<VetSettingsScreen> createState() => _VetSettingsScreenState();
}

class _VetSettingsScreenState extends State<VetSettingsScreen> {
  final _clinicNameController = TextEditingController(text: 'Oakwood Veterinary Centre');
  final _consultationFeeController = TextEditingController(text: '800.00');
  bool _acceptEmergencyCases = true;
  bool _telehealthEnabled = true;
  bool _smsAlerts = true;
  bool _autoPrescriptionSync = true;

  final Map<String, bool> _clinicDays = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': true,
    'Sun': false,
  };

  @override
  void dispose() {
    _clinicNameController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice & Vet Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Clinic Practice Info ─────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_hospital, color: colorScheme.primary, size: 22),
                          AppSpacing.hGapSm,
                          Text(
                            'Practice Details & Consultation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      TextField(
                        controller: _clinicNameController,
                        decoration: const InputDecoration(
                          labelText: 'Clinic / Hospital Name',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      AppSpacing.vGapMd,
                      TextField(
                        controller: _consultationFeeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Standard Consultation Rate (₹ INR)',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.vGapLg,

                // ── Working Days & Availability ──────────────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: colorScheme.primary, size: 22),
                          AppSpacing.hGapSm,
                          Text(
                            'Clinic Operational Days',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Wrap(
                        spacing: 8,
                        children: _clinicDays.keys.map((day) {
                          final active = _clinicDays[day]!;
                          return FilterChip(
                            label: Text(day),
                            selected: active,
                            onSelected: (val) => setState(() => _clinicDays[day] = val),
                            selectedColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: active ? colorScheme.primary : colorScheme.onSurface,
                              fontWeight: active ? AppTypography.bold : AppTypography.regular,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                AppSpacing.vGapLg,

                // ── Telehealth & Emergency Preferences ───────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emergency_outlined, color: colorScheme.primary, size: 22),
                          AppSpacing.hGapSm,
                          Text(
                            'Clinical Services & Emergency',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      SwitchListTile(
                        title: const Text('Accept Emergency Critical Alerts'),
                        subtitle: const Text('Direct dispatch alerts from smart collars in vital stress'),
                        value: _acceptEmergencyCases,
                        onChanged: (val) => setState(() => _acceptEmergencyCases = val),
                      ),
                      SwitchListTile(
                        title: const Text('Telehealth Video Consultations'),
                        subtitle: const Text('Allow remote pet triage sessions on appointment queue'),
                        value: _telehealthEnabled,
                        onChanged: (val) => setState(() => _telehealthEnabled = val),
                      ),
                      SwitchListTile(
                        title: const Text('Automated Rx Cloud Sync'),
                        subtitle: const Text('Sync digital prescriptions directly to partner pet pharmacies'),
                        value: _autoPrescriptionSync,
                        onChanged: (val) => setState(() => _autoPrescriptionSync = val),
                      ),
                      SwitchListTile(
                        title: const Text('SMS Urgent Case Notifications'),
                        subtitle: const Text('Receive text alerts for incoming acute cases'),
                        value: _smsAlerts,
                        onChanged: (val) => setState(() => _smsAlerts = val),
                      ),
                    ],
                  ),
                ),

                AppSpacing.vGapXl,

                // ── Save Settings Button ─────────────────────────────
                AppButton(
                  text: 'Save Practice Preferences',
                  icon: Icons.save,
                  isFullWidth: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veterinary clinic settings saved successfully!'),
                      ),
                    );
                  },
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 48,
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
