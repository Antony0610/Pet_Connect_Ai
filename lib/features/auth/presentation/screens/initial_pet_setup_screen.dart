import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

enum PetSpecies { dog, cat }

class InitialPetSetupScreen extends ConsumerStatefulWidget {
  const InitialPetSetupScreen({super.key});

  @override
  ConsumerState<InitialPetSetupScreen> createState() =>
      _InitialPetSetupScreenState();
}

class _InitialPetSetupScreenState extends ConsumerState<InitialPetSetupScreen> {
  static const String _dogImageUrl =
      'https://lh3.googleusercontent.com/aida-public/'
      'AB6AXuBHazV0mqkqQ42xRhcxA-nfQYGG4ThWYLNN9tDZ9ZmB1tilbONIhD8dkghPElCSpMw54eBoqy3MbO0CIQyLVNFxOlYdppvqajL0pDTS_uaoCJq72pIUY75Cp_34RHQTzILP58KjR8290qQMKEjf-OAS7QwseYdQIiXwrvdCsAH-UO6ew2rIfgqL07OwlcRPUBMQQ2bEjazSfC6b9r6WyEDgx2aJXZ6KCIOZwFMR81m_WSZdHaCTnXeojQ';
  static const String _catImageUrl =
      'https://lh3.googleusercontent.com/aida-public/'
      'AB6AXuDOyRzTqb7bU2JGktAN-BSfJc56hZuK2KH9YcQGoNiBdZewb708Vo4v-u5quS4JxJoTBASX6HL5wVz9ntZrB92cvJ8cGZ6C6B8_ht9TcIS7qR3FcLqxWLTguXeVfMUevEjU7Vg7v4Ytt_BWlvwoPuLQUgxbKimrw7unbVtrNohz9L4MHoEG5TWEMwaPUM5Ye8m0rnt2xvhcsbERzmtbiaamyva62UbbBYD_KHJ5fow72Jv224nxHGxvxg';

  PetSpecies? _selected;

  void _select(PetSpecies species) {
    HapticFeedback.selectionClick();
    setState(() => _selected = species);
  }

  Future<void> _continue() async {
    if (_selected == null) return;
    final speciesStr = _selected == PetSpecies.dog ? 'dog' : 'cat';
    final defaultName = _selected == PetSpecies.dog ? 'Buddy' : 'Whiskers';

    final newPet = Pet(
      id: '',
      ownerId: '',
      name: defaultName,
      species: speciesStr,
      healthStatus: 'optimal',
    );

    final result = await ref.read(createPetUseCaseProvider)(newPet);
    result.fold((_) {}, (createdPet) {
      ref.read(selectedPetIdProvider.notifier).state = createdPet.id;
      ref.read(petsProvider.notifier).refreshPets();
    });

    if (mounted) context.go(RoutePaths.ownerHome);
  }

  void _skip() => context.go(RoutePaths.ownerHome);

  void _back() {
    if (context.canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go(RoutePaths.welcomeSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
        ),
        title: Text(
          'PetConnect AI',
          style: textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                children: [
                  const _StepIndicator(currentStep: 0, totalSteps: 3),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'STEP 1 OF 3',
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    "Let's meet your pet.",
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.vGapMd,
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Text(
                      'Tell us what kind of companion you have so we can '
                      'personalize your PetConnect experience.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SpeciesGrid(
                    dogImageUrl: _dogImageUrl,
                    catImageUrl: _catImageUrl,
                    selected: _selected,
                    accent: accent,
                    onSelect: _select,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SetupActions(
                    canContinue: _selected != null,
                    onContinue: _continue,
                    onSkip: _skip,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three-dot wizard progress row. The active step renders as a wider pill.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return Padding(
          padding: EdgeInsets.only(
            right: index == totalSteps - 1 ? 0 : AppSpacing.sm,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 12,
            width: isActive ? 40 : 12,
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: AppRadius.brPill,
              border: isActive
                  ? null
                  : Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
          ),
        );
      }),
    );
  }
}

/// Responsive two-up (single column on narrow) species selection grid.
class _SpeciesGrid extends StatelessWidget {
  const _SpeciesGrid({
    required this.dogImageUrl,
    required this.catImageUrl,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final String dogImageUrl;
  final String catImageUrl;
  final PetSpecies? selected;
  final Color accent;
  final ValueChanged<PetSpecies> onSelect;

  @override
  Widget build(BuildContext context) {
    final dog = _PetCard(
      label: 'Dog',
      caption: 'Puppies to seniors',
      imageUrl: dogImageUrl,
      isSelected: selected == PetSpecies.dog,
      accent: accent,
      onTap: () => onSelect(PetSpecies.dog),
    );
    final cat = _PetCard(
      label: 'Cat',
      caption: 'Kittens to seniors',
      imageUrl: catImageUrl,
      isSelected: selected == PetSpecies.cat,
      accent: accent,
      onTap: () => onSelect(PetSpecies.cat),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dog),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: cat),
            ],
          );
        }
        return Column(
          children: [
            dog,
            const SizedBox(height: AppSpacing.xl),
            cat,
          ],
        );
      },
    );
  }
}

/// A single glass species card. Selecting lifts and scales it, swaps the
/// border to the Pet Owner emerald [accent], and reveals the check badge.
class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.label,
    required this.caption,
    required this.imageUrl,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String caption;
  final String imageUrl;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    return AnimatedScale(
      scale: isSelected ? 1.02 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brCard,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.05)
                  : scheme.surface.withValues(alpha: 0.7),
              borderRadius: AppRadius.brCard,
              border: Border.all(
                color: isSelected
                    ? accent
                    : scheme.outline.withValues(alpha: 0.1),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? accent.withValues(alpha: 0.25)
                      : scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: isSelected ? 40 : 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: AppRadius.brLg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: AppRadius.brLg,
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              label == 'Dog' ? Icons.pets : Icons.pets_outlined,
                              size: 72,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      label,
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      caption,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: AnimatedScale(
                    scale: isSelected ? 1 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.15),
                              blurRadius: AppSpacing.xs,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Continue (gated on selection) + Skip actions. On wide layouts Continue sits
/// on the right, matching the design's reversed row.
class _SetupActions extends StatelessWidget {
  const _SetupActions({
    required this.canContinue,
    required this.onContinue,
    required this.onSkip,
  });

  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final continueBtn = AppButton.filled(
      label: 'Continue',
      icon: Icons.arrow_forward,
      iconAlignment: IconAlignment.end,
      isFullWidth: true,
      size: AppButtonSize.large,
      borderRadius: AppRadius.brPill,
      onPressed: canContinue ? onContinue : null,
    );
    final skipBtn = AppButton.outlined(
      label: 'Skip for now',
      isFullWidth: true,
      size: AppButtonSize.large,
      borderRadius: AppRadius.brPill,
      onPressed: onSkip,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 400) {
            return Row(
              children: [
                Expanded(child: skipBtn),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: continueBtn),
              ],
            );
          }
          return Column(
            children: [
              continueBtn,
              const SizedBox(height: AppSpacing.lg),
              skipBtn,
            ],
          );
        },
      ),
    );
  }
}
