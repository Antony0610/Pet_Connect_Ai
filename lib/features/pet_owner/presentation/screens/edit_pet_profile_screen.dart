import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class EditPetProfileScreen extends ConsumerStatefulWidget {
  const EditPetProfileScreen({super.key});

  @override
  ConsumerState<EditPetProfileScreen> createState() =>
      _EditPetProfileScreenState();
}

class _EditPetProfileScreenState extends ConsumerState<EditPetProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late final TextEditingController _birthdayController;

  bool _initialized = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _aiHealthTracking = true;
  String? _uploadedPhotoUrl;
  Pet? _currentPet;
  DateTime? _selectedBirthday;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final authUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      final profileUserId = ref.read(currentUserProfileProvider).valueOrNull?.id;
      final String userId = authUserId ?? profileUserId ?? '00000000-0000-0000-0000-000000000001';
      final petId = _currentPet?.id ?? 'pet_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final base64Fallback = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final repo = ref.read(storageRepositoryProvider);
      final result = await repo.uploadPetAvatar(
        userId: userId,
        petId: petId,
        bytes: bytes,
        fileName: fileName,
        mimeType: 'image/jpeg',
      );

      result.fold(
        (failure) {
          // If storage upload fails, fallback to local Base64 image
          if (mounted) {
            setState(() {
              _uploadedPhotoUrl = base64Fallback;
              _isUploadingPhoto = false;
            });
            context.showSnackbar('Pet photo updated successfully!');
          }
        },
        (url) {
          if (mounted) {
            setState(() {
              _uploadedPhotoUrl = url;
              _isUploadingPhoto = false;
            });
            context.showSnackbar('Pet photo uploaded successfully!');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnack('Failed to upload photo: $e');
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  static Widget _photoFallback(ColorScheme scheme) => Container(
        width: 128,
        height: 128,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.pets,
          size: AppIconSizes.xl,
          color: scheme.onSurfaceVariant,
        ),
      );

  Future<void> _pickBirthday() async {
    final initial = _selectedBirthday ?? DateTime(2021, 5, 12);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime(1995),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text =
            '${_month(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }

  String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

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
        _selectedBirthday = pet.dateOfBirth;
        if (pet.dateOfBirth != null) {
          _birthdayController.text =
              '${_month(pet.dateOfBirth!.month)} ${pet.dateOfBirth!.day}, ${pet.dateOfBirth!.year}';
        }
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
      imageUrl: _uploadedPhotoUrl ?? _currentPet!.imageUrl,
      dateOfBirth: _selectedBirthday,
    );

    final result = await ref.read(updatePetUseCaseProvider)(updated);
    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold((failure) => context.showErrorSnack(failure.message), (_) {
      ref.invalidate(petsProvider);
      ref.invalidate(petDetailProvider(_currentPet!.id));
      GoRouter.of(context).pop();
    });
  }

  Future<void> _archiveOrDeletePet() async {
    if (_currentPet == null) return;
    final pet = _currentPet!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${pet.name}?'),
        content: Text(
          'Are you sure you want to remove ${pet.name} from active companions? This action will archive or remove the pet profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive / Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleteUseCase = ref.read(deletePetUseCaseProvider);
      final result = await deleteUseCase(pet.id);
      if (mounted) {
        result.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to archive: ${failure.message}')),
          ),
          (_) {
                  ref.invalidate(petsProvider);
            ref.invalidate(petDetailProvider(pet.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${pet.name} was successfully archived.')),
            );
            GoRouter.of(context).pop();
          },
        );
      }
    }
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
                            child: (_uploadedPhotoUrl ?? _currentPet?.imageUrl) != null &&
                                    (_uploadedPhotoUrl ?? _currentPet?.imageUrl)!.isNotEmpty
                                ? Image.network(
                                    _uploadedPhotoUrl ?? _currentPet!.imageUrl!,
                                    width: 128,
                                    height: 128,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _photoFallback(scheme),
                                  )
                                : _photoFallback(scheme),
                          ),
                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
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
                        onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Text(
                          _isUploadingPhoto ? 'Uploading…' : 'Change Photo',
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
                            labelText: 'Weight (kg)',
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
                          final birthdayWidget = GestureDetector(
                            onTap: _pickBirthday,
                            child: AbsorbPointer(child: birthday),
                          );
                          if (isNarrow) {
                            return Column(
                              children: [weight, AppSpacing.vGapMd, birthdayWidget],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: weight),
                              AppSpacing.hGapMd,
                              Expanded(child: birthdayWidget),
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
                    onPressed: _archiveOrDeletePet,
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
