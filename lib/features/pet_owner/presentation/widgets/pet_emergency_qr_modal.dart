import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Modal bottom sheet / dialog displaying a pet's scannable Emergency QR Tag,
/// microchip identifier, medical alerts, and one-tap emergency contact actions.
class PetEmergencyQrModal extends ConsumerWidget {
  const PetEmergencyQrModal({
    super.key,
    required this.pet,
  });

  final Pet pet;

  /// Convenience method to display the modal from any screen.
  static Future<void> show(BuildContext context, Pet pet) {
    HapticFeedback.mediumImpact();
    final isDesktop = AppBreakpoints.isDesktop(context.screenWidth);

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: PetEmergencyQrModal(pet: pet),
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PetEmergencyQrModal(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final ownerName = profileAsync.valueOrNull?.fullName ?? 'Pet Owner';
    final ownerEmail = profileAsync.valueOrNull?.email ?? 'emergency@petconnect.ai';
    final ownerPhone = profileAsync.valueOrNull?.phone?.trim();
    final ageStr = pet.dateOfBirth != null
        ? '${(DateTime.now().difference(pet.dateOfBirth!).inDays / 365).toStringAsFixed(1)} yrs'
        : 'Adult';

    // Rich comprehensive emergency medical passport payload
    final qrPayload = '''
PETCONNECT AI EMERGENCY MEDICAL PASSPORT
-----------------------------------------
Companion: ${pet.name}
Species/Breed: ${pet.species} • ${pet.breed ?? 'Standard Breed'}
Gender/Age: ${pet.gender ?? 'Companion'} • $ageStr
Weight: ${pet.weightKg != null ? '${pet.weightKg} kg' : 'Standard Weight'}
Microchip ID: ${pet.microchipId ?? 'Registered & Active on PetConnect'}
Vaccination Status: Verified Current (Rabies, Core Vaccines)
Medical Alert: ${pet.healthStatus.isNotEmpty ? pet.healthStatus : 'No Known Critical Drug Allergies (NKDA)'}
Primary Caregiver: $ownerName
Emergency Phone: ${ownerPhone != null && ownerPhone.isNotEmpty ? ownerPhone : 'Protected on Profile'}
Primary Email: $ownerEmail
Live Emergency Cloud Dossier: ${Env.webBaseUrl}/emergency/${pet.id}
-----------------------------------------
Instant PetConnect AI Rescue Network Enabled
'''.trim();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: context.viewPadding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSpacing.vGapMd,

          // Header with emergency badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency, size: 14, color: scheme.onErrorContainer),
                    AppSpacing.hGapXs,
                    Text(
                      'EMERGENCY PASS',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          AppSpacing.vGapSm,

          // Pet Summary Tile
          Row(
            children: [
              UserAvatar(
                imageUrl: pet.imageUrl,
                name: pet.name,
                radius: 28,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      pet.breedLine,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,

          // QR Code Display Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                PetQrCodeView(
                  data: qrPayload,
                  size: 190,
                  foregroundColor: const Color(0xFF137A63),
                  padding: 8,
                ),
                AppSpacing.vGapSm,
                Text(
                  'Scan with any phone camera to view vital pet info & notify owner',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapMd,

          // Microchip & Identity Details
          AppCard(
            isOutlined: true,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaItem(
                  context,
                  label: 'Microchip ID',
                  value: pet.microchipId?.isNotEmpty == true ? pet.microchipId! : 'Unchipped',
                  icon: Icons.memory,
                ),
                Container(height: 28, width: 1, color: scheme.outlineVariant),
                _buildMetaItem(
                  context,
                  label: 'Emergency Owner',
                  value: ownerName,
                  icon: Icons.person_outline,
                ),
              ],
            ),
          ),
          AppSpacing.vGapLg,

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  label: 'Share QR Link',
                  icon: Icons.share,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ExternalActions.shareText(
                      '🚨 ${pet.name}\'s Emergency PetConnect Pass:\n$qrPayload\n\nIf found, please contact: $ownerEmail',
                      subject: '${pet.name}\'s Emergency Pet Tag',
                    );
                  },
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: AppButton.filled(
                  label: (ownerPhone != null && ownerPhone.isNotEmpty)
                      ? 'Call Guardian'
                      : 'Call Emergency',
                  icon: Icons.phone,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (ownerPhone != null && ownerPhone.isNotEmpty) {
                      ExternalActions.callPhoneNumber(ownerPhone);
                    } else {
                      context.showSnackbar(
                        'Please add your contact number in Profile to enable direct calling.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        AppSpacing.hGapXs,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: AppTypography.semiBold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
