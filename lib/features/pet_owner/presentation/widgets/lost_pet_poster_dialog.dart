import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:share_plus/share_plus.dart';

/// Modal dialog that generates a high-visibility, official "LOST PET" poster
/// complete with pet details, last known location, reward badge, and emergency QR code.
class LostPetPosterDialog extends ConsumerWidget {
  const LostPetPosterDialog({
    super.key,
    required this.pet,
    this.lastSeenLocation = 'Near Central Park / 5th Ave',
    this.rewardAmount = '\$500',
  });

  final Pet pet;
  final String lastSeenLocation;
  final String rewardAmount;

  /// Convenience helper to display the poster dialog.
  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    String lastSeenLocation = 'Near Central Park / 5th Ave',
    String rewardAmount = '\$500',
  }) async {
    await HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: LostPetPosterDialog(
            pet: pet,
            lastSeenLocation: lastSeenLocation,
            rewardAmount: rewardAmount,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);
    const ownerPhone = '18005557387';
    final ownerEmail = profileAsync.valueOrNull?.email ?? 'emergency@petconnect.ai';
    final todayStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final qrPayload = 'https://petconnect.ai/emergency/${pet.id}?'
        'lost=true&'
        'name=${Uri.encodeComponent(pet.name)}&'
        'phone=${Uri.encodeComponent(ownerPhone)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: scheme.error, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── TOP HEADER BANNER ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'MISSING ${pet.species.toUpperCase()} 🚨',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // ── PET NAME ──────────────────────────────────────────────
            Text(
              pet.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: scheme.error,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              pet.breedLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            AppSpacing.vGapMd,

            // ── PET PHOTO & DETAILS ROW ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.error, width: 2),
                    borderRadius: BorderRadius.circular(52),
                  ),
                  child: UserAvatar(
                    imageUrl: pet.imageUrl,
                    name: pet.name,
                    radius: 46,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPosterField('Species', pet.species.toUpperCase()),
                      _buildPosterField('Weight', pet.weightKg != null ? '${pet.weightKg} kg' : 'Not specified'),
                      _buildPosterField('Microchip', pet.microchipId?.isNotEmpty == true ? 'CHIPPED' : 'Not chipped'),
                      _buildPosterField('Date Missing', todayStr),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,

            // ── LAST SEEN LOCATION BOX ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: scheme.error),
                      AppSpacing.hGapXs,
                      const Text(
                        'LAST SEEN LOCATION:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastSeenLocation,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapMd,

            // ── REWARD BADGE ──────────────────────────────────────────
            if (rewardAmount.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Text(
                  '⭐ $rewardAmount REWARD — NO QUESTIONS ASKED ⭐',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            AppSpacing.vGapMd,

            // ── QR CODE & DIRECT CONTACT ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PetQrCodeView(
                  data: qrPayload,
                  size: 110,
                  padding: 4,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IF SEEN PLEASE CALL:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      Text(
                        ownerPhone,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Scan QR code with any phone camera to view full profile & notify owner instantly.',
                        style: TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // ── ACTION BUTTONS ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'Share Poster',
                    icon: Icons.share,
                    onPressed: () async {
                      await HapticFeedback.lightImpact();
                      await ExternalActions.shareText(
                        '🚨 MISSING PET ALERT: ${pet.name.toUpperCase()}!\n'
                        'Species: ${pet.species} • Breed: ${pet.breed ?? "Unknown"}\n'
                        'Last Seen: $lastSeenLocation\n'
                        'Reward: $rewardAmount\n\n'
                        'If found, please scan or view: $qrPayload\n'
                        'Emergency Call: $ownerPhone',
                        subject: '🚨 MISSING PET: ${pet.name}',
                      );
                    },
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: AppButton.filled(
                    label: 'Save / Print',
                    icon: Icons.print,
                    onPressed: () async {
                      await HapticFeedback.lightImpact();
                      final posterSummary =
                          '====================================================\n'
                          '              🚨 MISSING ${pet.species.toUpperCase()} 🚨             \n'
                          '====================================================\n'
                          'PET NAME:     ${pet.name.toUpperCase()}\n'
                          'BREED:        ${pet.breedLine}\n'
                          'LAST SEEN:    $lastSeenLocation\n'
                          'REWARD:       $rewardAmount\n'
                          'CONTACT:      $ownerPhone / $ownerEmail\n'
                          'PASS LINK:    $qrPayload\n'
                          '====================================================\n'
                          'Generated via PetConnect AI Emergency Rescue Network\n';

                      try {
                        final tempDir = await getTemporaryDirectory();
                        final sanitized = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
                        final file = File('${tempDir.path}/${sanitized}_Missing_Poster.txt');
                        await file.writeAsString(posterSummary);

                        // ignore: deprecated_member_use
                        await Share.shareXFiles(
                          [XFile(file.path, mimeType: 'text/plain')],
                          text: '🚨 Missing Pet Poster for ${pet.name}. Print or distribute.',
                          subject: 'MISSING PET POSTER: ${pet.name}',
                        );
                      } catch (_) {
                        // ignore: deprecated_member_use
                        await Share.share(posterSummary, subject: 'MISSING PET POSTER: ${pet.name}');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
