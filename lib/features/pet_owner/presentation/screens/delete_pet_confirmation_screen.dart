import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';

/// The Pet Owner **Delete Pet Confirmation** modal.
///
/// A faithful Flutter rendering of the frozen Stitch "Delete Pet
/// Confirmation" (Light master): a blurred scrim over the underlying page and
/// a centered dialog card carrying a sad-pet illustration, a destructive
/// prompt and Delete / Cancel actions. Every color, spacing, radius and type
/// comes from the theme / design tokens so one widget tree serves both Light
/// and Dark.
///
/// Presented as a route (rather than [showDialog]) so it participates in the
/// GoRouter stack; the scrim is transparent to preserve the page beneath.
class DeletePetConfirmationScreen extends StatelessWidget {
  const DeletePetConfirmationScreen({super.key, this.petName = 'Buddy'});

  final String petName;

  static const String _illustrationUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAqfb3H_kAbAknf2jSIrScXsT8e76RpJyT0VQJCpCTtT0_aL9Zbun0Pg9IAhFqtnc0Yp5mCFMo5AmCUiQCg0jBaycxxiFjq6mdypqytFl8QdPUmYwMGhXGHoi745FJkgVcnWLNr09hnblUmoyZfCwL4JI8W66ohw_DGSs9qNDgU1brlJxGpaVhmdiEcMgde5RIqAcEkNdmIelHgV0-lhuUatwgq1YQLp9t_d9ybaXY09E2Uao7khb_chA';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred scrim.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => GoRouter.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: scheme.inverseSurface.withValues(alpha: 0.40),
                ),
              ),
            ),
          ),
          // Dialog card.
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: AppRadius.brModal,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Illustration.
                        ClipRRect(
                          borderRadius: AppRadius.brSection,
                          child: AspectRatio(
                            aspectRatio: 16 / 11,
                            child: Image.network(
                              _illustrationUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: scheme.errorContainer.withValues(
                                  alpha: 0.40,
                                ),
                                child: Icon(
                                  Icons.pets,
                                  size: AppIconSizes.xxl,
                                  color: scheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.vGapLg,
                        Text(
                          'Are you sure you want to remove $petName?',
                          textAlign: TextAlign.center,
                          style: text.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'This will permanently delete all records, photos, '
                          'and AI insights. This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.vGapLg,
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: () => GoRouter.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.brPill,
                              ),
                              textStyle: text.labelLarge?.copyWith(
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_forever,
                              size: AppIconSizes.sm,
                            ),
                            label: Text('Yes, Delete $petName'),
                          ),
                        ),
                        AppSpacing.vGapSm,
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.surfaceContainerHigh,
                              foregroundColor: scheme.onSurface,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.brPill,
                              ),
                              textStyle: text.labelLarge?.copyWith(
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
