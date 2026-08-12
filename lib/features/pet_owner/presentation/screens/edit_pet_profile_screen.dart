import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class EditPetProfileScreen extends ConsumerStatefulWidget {
  const EditPetProfileScreen({super.key});

  @override
  ConsumerState<EditPetProfileScreen> createState() =>
      _EditPetProfileScreenState();
}

class _EditPetProfileScreenState extends ConsumerState<EditPetProfileScreen> {
  static const String _photoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCebTvJKADcoc5qnRfZm9Zz8piAyM9XY4feJdNuTMlpSLxUy3RJULukgrawNI8hfHRNv9mMJfKunQ8JgHMSIoM368hwqlwAJ0k7dzUiLfrTEFucAXHDb6qoqfWeusOGlYMRz6SpUF87znQlQ5QDYPlQv7UgoZenpcCEkweQP1Ly2HRIJgKbn2LTRJmZ9_7zFZjhspGSQ18RJJPwev9VB9S9-IVTZx0pwpNuOv8hzTL_kJQ-RaOhXKRvYQ';

  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late final TextEditingController _birthdayController;

  bool _initialized = false;
  bool _isSaving = false;
  Pet? _currentPet;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _breedController = TextEditingController();
    _weightController = TextEditingController();
    _birthdayController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final petId =
          GoRouterState.of(context).pathParameters['petId'] ??
          ref.read(selectedPetIdProvider);
      final pet = petId != null
          ? ref.read(petDetailProvider(petId)).valueOrNull
          : ref.read(selectedPetProvider);

      if (pet != null) {
        _currentPet = pet;
        _nameController.text = pet.name;
        _breedController.text = pet.breed ?? '';
        _weightController.text = pet.weightKg?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (_currentPet == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showErrorSnack('Pet name cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);

    final updated = _currentPet!.copyWith(
      name: name,
      breed: _breedController.text.trim().isNotEmpty
          ? _breedController.text.trim()
          : null,
      weightKg: double.tryParse(_weightController.text.trim()),
    );

    final result = await ref.read(updatePetUseCaseProvider)(updated);
    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold((failure) => context.showErrorSnack(failure.message), (_) {
      ref.read(petsProvider.notifier).refreshPets();
      ref.invalidate(petDetailProvider(_currentPet!.id));
      GoRouter.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Text(
        'Edit Pet',
        style: text.headlineSmall?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _savePet,
          child: Text(
            'Save',
            style: text.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          topPad + AppSpacing.md,
          AppSpacing.marginMobile,
          bottomPad,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.tablet),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Photo ──────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipOval(
                            child: Image.network(
                              _photoUrl,
                              width: 128,
                              height: 128,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 128,
                                height: 128,
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.pets,
                                  size: AppIconSizes.xl,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: AppIconSizes.sm,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Change Photo',
                          style: text.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Form panel ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest.withValues(
                      alpha: 0.60,
                    ),
                    borderRadius: AppRadius.brCard,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        labelText: 'Name',
                        prefixIcon: Icons.pets,
                      ),
                      AppSpacing.vGapMd,
                      AppTextField(
                        controller: _breedController,
                        labelText: 'Breed',
                        prefixIcon: Icons.category,
                      ),
                      AppSpacing.vGapMd,
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final weight = AppTextField(
                            controller: _weightController,
                            labelText: 'Weight (lbs)',
                            prefixIcon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                          );
                          final birthday = AppTextField(
                            controller: _birthdayController,
                            labelText: 'Birthday',
                            prefixIcon: Icons.cake,
                            readOnly: true,
                            onSuffixIconTap: _pickBirthday,
                          );
                          if (isNarrow) {
                            return Column(
                              children: [weight, AppSpacing.vGapMd, birthday],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: weight),
                              AppSpacing.hGapMd,
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickBirthday,
                                  child: AbsorbPointer(child: birthday),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      AppSpacing.vGapSm,

                      // AI Health Tracking toggle.
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.30,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smart_toy,
                              color: scheme.primary,
                              size: AppIconSizes.md,
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Health Tracking',
                                    style: text.labelLarge?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: AppTypography.semiBold,
                                    ),
                                  ),
                                  Text(
                                    'Enable predictive insights for '
                                    '${_nameController.text}.',
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _aiHealthTracking,
                              onChanged: (v) =>
                                  setState(() => _aiHealthTracking = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Archive action ─────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.archive_outlined, color: scheme.error),
                    label: Text(
                      'Archive Pet Profile',
                      style: text.labelLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: AppTypography.semiBold,
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
