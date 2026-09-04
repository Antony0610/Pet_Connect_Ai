import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/edit_volunteer_profile_dialog.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/volunteer_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Volunteer & Field Rescue Responder Profile Screen.
/// Follows the unified centered profile standard matching Pet Owner profiles.
class VolunteerProfileScreen extends ConsumerStatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  ConsumerState<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends ConsumerState<VolunteerProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(UserProfile profile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final storageRepo = ref.read(storageRepositoryProvider);
      final uploadResult = await storageRepo.uploadUserAvatar(
        userId: profile.id,
        bytes: bytes,
        fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );

      await uploadResult.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Avatar upload failed: ${failure.message}')),
            );
          }
        },
        (newUrl) async {
          final updated = profile.copyWith(avatarUrl: newUrl);
          await ref.read(upsertUserProfileProvider)(updated);
          ref.invalidate(currentUserProfileProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Display picture updated successfully!')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _openEditDialog(UserProfile profile) async {
    await EditVolunteerProfileDialog.show(context, profile: profile);
    ref.invalidate(currentUserProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final missionsAsync = ref.watch(rescueMissionsProvider(null));
    final missions = missionsAsync.valueOrNull ?? [];
    final completedCount = missions
        .where((m) => m.status == 'completed' || m.status == 'resolved')
        .length;

    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final createdAt = profile?.createdAt ?? DateTime.now();
    final tenureDays = DateTime.now().difference(createdAt).inDays;
    final tenureString = tenureDays < 30
        ? '$tenureDays Days'
        : (tenureDays < 365
            ? '${(tenureDays / 30).floor()} Months'
            : '${(tenureDays / 365).toStringAsFixed(1)} Years');

    final onDuty = ref.watch(volunteerDutyStatusProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final orgName = prefs.getString('volunteer_org') ?? 'PetConnect Rapid Animal Rescue Corps';
    final sector = prefs.getString('volunteer_sector') ?? 'Central Command • Rapid Dispatch';
    final vehicle = prefs.getString('volunteer_vehicle') ?? 'SUV with Pet Crate & Partition';
    final equipment = prefs.getString('volunteer_equipment') ??
        'Pet First Aid Kit, Animal Carrier, Microchip Scanner, Safety Gloves, Slip Leash';
    final skills = prefs.getStringList('volunteer_skills') ??
        ['Animal First Aid', 'Search & Rescue', 'Emergency Transport', 'Trauma Care'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.rescueHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Responder Profile',
            onPressed: () {
              final name = profile?.fullName ?? 'Field Rescue Responder';
              final phone = profile?.phone ?? '';
              final city = profile?.city ?? '';
              ExternalActions.shareText(
                'Responder: $name\nAffiliation: $orgName\nSector: $sector ($city)\nContact: $phone\nField Status: ${onDuty ? "On-Duty" : "Standby"}\nActive on PetConnect AI Volunteer Network.',
                subject: '$name - Rescue Profile',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.rescueSettings),
            tooltip: 'Volunteer Settings',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load profile: $e')),
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('Profile not found. Please log in again.'));
          }

          final displayName = userProfile.fullName.isNotEmpty
              ? userProfile.fullName
              : (userProfile.email.isNotEmpty ? userProfile.email.split('@').first : 'Rescue Volunteer');
          final volId = userProfile.id.length >= 6 ? userProfile.id.substring(0, 6).toUpperCase() : 'VOL-01';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Centered Header Card ────────────────────────────
                    _buildCenteredProfileCard(
                      context,
                      theme,
                      colorScheme,
                      userProfile,
                      displayName,
                      volId,
                      onDuty,
                    ),

                    AppSpacing.vGapLg,

                    // ── Live Duty Status Switch Card ─────────────────────
                    _buildDutyStatusCard(theme, colorScheme, onDuty),

                    AppSpacing.vGapLg,

                    // ── Service Impact Metrics ───────────────────────────
                    _buildMetricsGrid(
                      theme,
                      colorScheme,
                      completedCount,
                      tenureString,
                      onDuty,
                    ),

                    AppSpacing.vGapLg,

                    // ── Operational Readiness & Equipment Card ───────────
                    _buildEquipmentCard(
                      theme,
                      colorScheme,
                      orgName: orgName,
                      sector: sector,
                      vehicle: vehicle,
                      equipment: equipment,
                      city: userProfile.city ?? '',
                      onEdit: () => _openEditDialog(userProfile),
                    ),

                    AppSpacing.vGapLg,

                    // ── Specialization Skills Badges ─────────────────────
                    _buildSkillsSection(theme, colorScheme, skills),

                    AppSpacing.vGapLg,

                    // ── Navigation & Tools ──────────────────────────────
                    _buildNavigationList(context, theme, colorScheme),

                    AppSpacing.vGapXl,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const VolunteerBottomNavBar(currentTab: VolunteerTab.profile),
    );
  }

  Widget _buildCenteredProfileCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UserProfile profile,
    String displayName,
    String volId,
    bool onDuty,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brSection,
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: AppSpacing.cardPaddingPremium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with tap-to-upload
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _uploadingAvatar ? null : () => _pickAndUploadAvatar(profile),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(imageUrl: profile.avatarUrl ?? '', size: 88),
                      if (_uploadingAvatar)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: AppIconSizes.xs),
                ),
              ],
            ),
            AppSpacing.vGapMd,

            // Full Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.verified, size: 18, color: colorScheme.primary),
              ],
            ),
            AppSpacing.vGapXs,

            // ID & Email
            Text(
              'Responder ID: PC-$volId • ${profile.email}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapXs,

            // Phone
            if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    profile.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_call, size: 13, color: colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'No phone number • Tap Edit to add',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
            ],

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: AppRadius.brPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Volunteer Rescue • Field Responder',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapMd,

            // Bio
            if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              AppSpacing.vGapMd,
            ],

            // Edit Profile Button
            OutlinedButton.icon(
              onPressed: () => _openEditDialog(profile),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Responder Profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyStatusCard(ThemeData theme, ColorScheme colorScheme, bool onDuty) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SwitchListTile(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onDuty ? AppColors.success : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              onDuty ? 'ON DUTY • ACTIVE FOR DISPATCH' : 'STANDBY • OFF DUTY',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: onDuty ? AppColors.success : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Text(
          onDuty
              ? 'Transmitting live responder coordinates to local SOS alerts'
              : 'Standby mode • Emergency push notifications paused',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        value: onDuty,
        activeThumbColor: AppColors.success,
        contentPadding: EdgeInsets.zero,
        onChanged: (val) {
          ref.read(volunteerDutyStatusProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildEquipmentCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String orgName,
    required String sector,
    required String vehicle,
    required String equipment,
    required String city,
    required VoidCallback onEdit,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Operational Readiness & Equipment',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20),
                tooltip: 'Edit Operations',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Organization
          Row(
            children: [
              Icon(Icons.business_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  orgName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: AppTypography.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Sector
          Row(
            children: [
              Icon(Icons.map_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  '$sector${city.isNotEmpty ? " • $city" : ""}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Vehicle
          Row(
            children: [
              Icon(Icons.directions_car_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Vehicle: $vehicle',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Equipment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_services_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Equipment: $equipment',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    int completedCount,
    String tenureString,
    bool onDuty,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(theme, colorScheme, value: '$completedCount', label: 'Rescues', icon: Icons.shield_outlined),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(theme, colorScheme, value: tenureString, label: 'Tenure', icon: Icons.schedule_outlined),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: onDuty ? 'Active' : 'Standby',
            label: 'Status',
            icon: onDuty ? Icons.radar : Icons.radio_button_unchecked,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, ColorScheme colorScheme, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialization Skills & Field Badges',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
        ),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    skill,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationList(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Preferences',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Volunteer Preferences & Radius',
          subtitle: 'Configure availability days and alert radius',
          icon: Icons.tune_outlined,
          onTap: () => context.push(RoutePaths.rescueSettings),
        ),
        AppSpacing.vGapLg,
        OutlinedButton.icon(
          icon: Icon(Icons.logout, color: colorScheme.error),
          label: Text('Sign Out of Rescue Portal', style: TextStyle(color: colorScheme.error)),
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
                content: const Text('Sign out of Volunteer & Rescue Portal?'),
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
              final container = ProviderScope.containerOf(context);
              await container.read(signOutProvider)(const NoParams());
              if (context.mounted) context.go(RoutePaths.login);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: AppTypography.bold),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
