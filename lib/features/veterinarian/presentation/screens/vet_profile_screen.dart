import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Veterinarian Practitioner & Clinic Profile Screen (Stitch ID: `c883012ed473494bb6e61222ffe0e472`).
class VetProfileScreen extends ConsumerWidget {
  const VetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Vet Settings',
            onPressed: () => context.push(RoutePaths.vetSettings),
          ),
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
                _buildProfileBanner(theme, colorScheme, ref),

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

                AppSpacing.vGapLg,

                // ── Sign Out Card ───────────────────────────────────
                OutlinedButton.icon(
                  icon: Icon(Icons.logout, color: colorScheme.error),
                  label: Text('Sign Out of Veterinarian Portal', style: TextStyle(color: colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Sign out of Veterinarian Portal?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(signOutProvider)(const NoParams());
                      if (context.mounted) context.go(RoutePaths.login);
                    }
                  },
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final doctorName = (userProfile != null && userProfile.fullName.isNotEmpty)
        ? (userProfile.fullName.startsWith('Dr.') ? userProfile.fullName : 'Dr. ${userProfile.fullName}')
        : (userProfile != null && userProfile.email.isNotEmpty ? 'Dr. ${userProfile.email.split('@').first}' : 'Dr. Practitioner');
    final clinicName = (userProfile != null && userProfile.fullName.isNotEmpty)
        ? '${userProfile.fullName} Veterinary Practice'
        : 'PetConnect Certified Veterinary Clinic';

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
                        clinicName,
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
                  '$doctorName, DVM • Licensed Veterinary Practitioner',
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
                      '5.0 (Active Practicing)',
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
                AppSpacing.vGapSm,
                OutlinedButton.icon(
                  onPressed: () => _openEditVetProfileDialog(theme, ref, userProfile),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Practitioner Profile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditVetProfileDialog(
    ThemeData theme,
    WidgetRef ref,
    UserProfile? currentProfile,
  ) async {
    final nameCtrl = TextEditingController(text: currentProfile?.fullName ?? '');

    final saved = await showDialog<bool>(
      context: ref.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Practitioner Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Doctor Full Name',
                  hintText: 'e.g. Dr. Sarah Jenkins',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
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
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty && currentProfile != null) {
      final updated = currentProfile.copyWith(
        fullName: nameCtrl.text.trim(),
      );
      await ref.read(upsertUserProfileProvider)(updated);
      ref.invalidate(currentUserProfileProvider);
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Profile updated for ${nameCtrl.text.trim()}!'),
          ),
        );
      }
    }
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
