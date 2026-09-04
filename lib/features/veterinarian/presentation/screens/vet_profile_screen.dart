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
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/edit_vet_profile_dialog.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Veterinarian Practitioner & Clinic Profile Screen.
/// Follows the unified centered profile standard matching Pet Owner profiles.
class VetProfileScreen extends ConsumerStatefulWidget {
  const VetProfileScreen({super.key});

  @override
  ConsumerState<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends ConsumerState<VetProfileScreen> {
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

  void _openEditDialog(UserProfile profile, VetClinic? clinic) async {
    await EditVetProfileDialog.show(context, profile: profile, initialClinic: clinic);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(vetClinicsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinic = clinics.isNotEmpty ? clinics.first : null;
    final prefs = ref.watch(sharedPreferencesProvider);

    final operatingHours = prefs.getString('vet_operating_hours') ??
        'Mon-Fri: 8:00 AM - 6:00 PM • Sat: 9:00 AM - 1:00 PM';
    final specializationsRaw = prefs.getString('vet_specializations') ??
        'General Surgery, Diagnostic Ultrasound, AI Triage & Telehealth, Emergency Operations';
    final consultationFee = prefs.getString('vet_consultation_fee') ?? '500';

    final specializationsList = specializationsRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Profile',
            onPressed: () {
              final profile = profileAsync.valueOrNull;
              final docName = profile?.fullName.isNotEmpty == true
                  ? (profile!.fullName.startsWith('Dr.') ? profile.fullName : 'Dr. ${profile.fullName}')
                  : 'Veterinary Practitioner';
              final cName = clinic?.name ?? '$docName Practice';
              final phone = clinic?.phone ?? profile?.phone ?? '';
              final address = clinic?.address ?? profile?.city ?? '';
              ExternalActions.shareText(
                '$docName\n$cName\n📍 $address\n📞 $phone\nConsultations available on PetConnect AI.',
                subject: '$docName - Clinical Profile',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Vet Settings',
            onPressed: () => context.push(RoutePaths.vetSettings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found. Please log in again.'));
          }

          final docName = profile.fullName.isNotEmpty
              ? (profile.fullName.startsWith('Dr.') ? profile.fullName : 'Dr. ${profile.fullName}')
              : 'Dr. Practitioner';
          final clinicName = clinic?.name ?? (profile.fullName.isNotEmpty ? '${profile.fullName} Veterinary Practice' : 'PetConnect Certified Clinic');
          final licenseNumber = clinic?.licenseNumber ?? 'VET-${profile.id.length >= 6 ? profile.id.substring(0, 6).toUpperCase() : "REG-01"}';
          final address = clinic?.address ?? (profile.city?.isNotEmpty == true ? profile.city! : 'Clinical Practice Facility');
          final phone = clinic?.phone ?? profile.phone ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Centered Profile Header Card ────────────────────
                    _buildCenteredProfileCard(context, theme, colorScheme, profile, docName, clinic),

                    AppSpacing.vGapLg,

                    // ── Practice & Facility Details Card ─────────────────
                    _buildPracticeDetailsCard(
                      theme,
                      colorScheme,
                      clinicName: clinicName,
                      licenseNumber: licenseNumber,
                      address: address,
                      phone: phone,
                      operatingHours: operatingHours,
                      consultationFee: consultationFee,
                      onEdit: () => _openEditDialog(profile, clinic),
                    ),

                    AppSpacing.vGapLg,

                    // ── Services & Specializations ───────────────────────
                    _buildServicesSection(theme, colorScheme, specializationsList),

                    AppSpacing.vGapLg,

                    // ── Action Buttons ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Book Consultation',
                            icon: Icons.calendar_month,
                            onPressed: () => context.push(RoutePaths.vetAppointmentSchedule),
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
                            onPressed: () async {
                              if (phone.isNotEmpty) {
                                await ExternalActions.callPhone(phone);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please add a phone number in Edit Practice Profile.')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.vGapLg,

                    // ── Sign Out Button ─────────────────────────────────
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
          );
        },
      ),
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.profile),
    );
  }

  Widget _buildCenteredProfileCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UserProfile profile,
    String docName,
    VetClinic? clinic,
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

            // Doctor Name
            Text(
              docName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            AppSpacing.vGapXs,

            // Email
            Text(
              profile.email,
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
                  Icon(Icons.verified, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Veterinarian • VCI Verified Practitioner',
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
              onPressed: () => _openEditDialog(profile, clinic),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Practitioner Profile'),
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

  Widget _buildPracticeDetailsCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String clinicName,
    required String licenseNumber,
    required String address,
    required String phone,
    required String operatingHours,
    required String consultationFee,
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
                'Clinical Practice Facility',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20),
                tooltip: 'Edit Practice Info',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Clinic Name
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  clinicName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: AppTypography.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text(
                  'OPEN NOW',
                  style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // License
          Row(
            children: [
              Icon(Icons.badge_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Text(
                'License: $licenseNumber',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 20),

          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  address.isNotEmpty ? address : 'Clinic Address (Tap edit to specify)',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Operating Hours
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Hours: $operatingHours',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Consultation Fee
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Standard Consultation: ₹$consultationFee',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> specializations,
  ) {
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specializations.map((spec) {
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
                  Icon(Icons.medical_services_outlined, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    spec,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
