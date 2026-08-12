import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';

class DeletePetConfirmationScreen extends ConsumerStatefulWidget {
  const DeletePetConfirmationScreen({super.key, this.petName});

  final String? petName;

  @override
  ConsumerState<DeletePetConfirmationScreen> createState() =>
      _DeletePetConfirmationScreenState();
}

class _DeletePetConfirmationScreenState
    extends ConsumerState<DeletePetConfirmationScreen> {
  static const String _illustrationUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAqfb3H_kAbAknf2jSIrScXsT8e76RpJyT0VQJCpCTtT0_aL9Zbun0Pg9IAhFqtnc0Yp5mCFMo5AmCUiQCg0jBaycxxiFjq6mdypqytFl8QdPUmYwMGhXGHoi745FJkgVcnWLNr09hnblUmoyZfCwL4JI8W66ohw_DGSs9qNDgU1brlJxGpaVhmdiEcMgde5RIqAcEkNdmIelHgV0-lhuUatwgq1YQLp9t_d9ybaXY09E2Uao7khb_chA';

  bool _isDeleting = false;

  Future<void> _delete(String? petId) async {
    if (petId == null) {
      GoRouter.of(context).pop();
      return;
    }

    setState(() => _isDeleting = true);

    final result = await ref.read(deletePetUseCaseProvider)(petId);
    if (!mounted) return;

    setState(() => _isDeleting = false);

    result.fold((failure) => context.showErrorSnack(failure.message), (_) {
      ref.read(petsProvider.notifier).refreshPets();
      ref.read(selectedPetIdProvider.notifier).state = null;
      context.goNamed(RouteNames.ownerPets);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final pathPetId =
        GoRouterState.of(context).pathParameters['petId'] ??
        ref.watch(selectedPetIdProvider);
    final petAsync = pathPetId != null
        ? ref.watch(petDetailProvider(pathPetId))
        : const AsyncValue.data(null);
    final pet = petAsync.valueOrNull ?? ref.watch(selectedPetProvider);
    final displayName = widget.petName ?? pet?.name ?? 'this pet';

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
                          'Are you sure you want to remove $displayName?',
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
                            onPressed: _isDeleting
                                ? null
                                : () => _delete(pathPetId),
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
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.delete_forever),
                            label: Text(
                              _isDeleting
                                  ? 'Deleting...'
                                  : 'Delete Pet Profile',
                            ),
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
