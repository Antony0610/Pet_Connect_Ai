import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Veterinarian Practitioner & Clinic Profile Screen (Stitch ID: `c883012ed473494bb6e61222ffe0e472`).
///
/// Public practitioner profile and clinic details screen. Displays doctor credentials,
/// specialization badges, operating hours, service capabilities, and appointment booking actions.
class VetProfileScreen extends StatelessWidget {
  const VetProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian & Clinic Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing Vet Profile link...')),
              );
            },
            tooltip: 'Share Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Clinic Identity Banner ───────────────────────────
                _buildProfileBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Operating Hours & Location ───────────────────────
                _buildHoursLocationCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Services & Specializations ───────────────────────
                _buildServicesGrid(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Action Buttons ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Book Consultation',
                        icon: Icons.calendar_month,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Opening Consultation Scheduler...',
                              ),
                            ),
                          );
                        },
                        backgroundColor: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                        height: 48,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Contact Clinic'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calling Clinic Line...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.local_hospital,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Oakridge Veterinary Clinic',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    const AppChip(
                      label: 'OPEN NOW',
                      backgroundColor: AppColors.success,
                      textColor: AppColors.white,
                    ),
                  ],
                ),
                Text(
                  'Dr. Emily Watson, DVM • Senior Veterinary Surgeon',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (128 reviews)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.verified, color: colorScheme.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Medical Board',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursLocationCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  '123 Wellness Way, Suite 400 • Medical Sector 4',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Operating Hours: Mon-Fri: 8:00 AM - 6:00 PM • Sat: 9:00 AM - 1:00 PM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(ThemeData theme, ColorScheme colorScheme) {
    final services = [
      {'title': 'General Surgery', 'icon': Icons.medical_services_outlined},
      {'title': 'Diagnostic Ultrasound', 'icon': Icons.monitor_heart_outlined},
      {'title': 'AI Triage & Telehealth', 'icon': Icons.psychology_outlined},
      {'title': 'Emergency Operations', 'icon': Icons.emergency_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Specializations & Services',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: services.length,
          itemBuilder: (ctx, idx) {
            final s = services[idx];
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      s['title'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
