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
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/edit_vet_profile_dialog.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
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
                _buildProfileBanner(context, theme, colorScheme, ref),

                AppSpacing.vGapLg,

                // ── Operating Hours & Location ───────────────────────
                _buildHoursLocationCard(theme, colorScheme, ref),

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
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.profile),
    );
  }

  Widget _buildProfileBanner(BuildContext context, ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
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
          Stack(
            children: [
              UserAvatar(
                imageUrl: userProfile?.avatarUrl ?? '',
                size: 76,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: colorScheme.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _openEditVetProfileDialog(context, ref, userProfile),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                  onPressed: () => _openEditVetProfileDialog(context, ref, userProfile),
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
    BuildContext context,
    WidgetRef ref,
    UserProfile? currentProfile,
  ) async {
    if (currentProfile == null) return;
    final clinics = ref.read(vetClinicsProvider).valueOrNull ?? [];
    final clinic = clinics.isNotEmpty ? clinics.first : null;
    await EditVetProfileDialog.show(context, profile: currentProfile, initialClinic: clinic);
  }

  Widget _buildHoursLocationCard(ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinic = clinics.isNotEmpty ? clinics.first : null;
    final address = clinic?.address ?? '123 Wellness Way, Suite 400 • Medical Sector 4';
    final phone = clinic?.phone ?? '+91 98450 12345';

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
                  address,
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
                Icons.phone_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Contact: $phone • Emergency On-Call Active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
