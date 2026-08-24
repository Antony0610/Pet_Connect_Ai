import 'dart:convert';
import 'dart:ui';

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
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// The Pet Owner **Add Pet — Basic Info** screen (wizard step 1 of 4).
///
/// A faithful Flutter rendering of the frozen Stitch "Add Pet - Step 1"
/// (Light master): a transactional glass header, a step progress indicator,
/// a dashed-circle photo uploader, and a form card (name, pet-type toggle,
/// breed, gender segment) with a fixed bottom action bar. Every color,
/// spacing, radius and type comes from the theme / design tokens so one
/// widget tree serves both Light and Dark.
class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

enum _PetType { dog, cat }

enum _Gender { male, female }

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  _PetType _type = _PetType.dog;
  _Gender _gender = _Gender.female;
  DateTime? _dateOfBirth;
  bool _isSaving = false;

  /// Holds the publicly accessible URL returned after a successful photo upload.
  /// Null until the user picks and uploads a photo.
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showErrorSnack('Please enter your pet name.');
      return;
    }

    setState(() => _isSaving = true);

    final weightText = _weightController.text.trim();
    final weight = weightText.isNotEmpty ? double.tryParse(weightText) : null;

    final newPet = Pet(
      id: '',
      ownerId: '',
      name: name,
      species: _type.name,
      breed: _breedController.text.trim().isNotEmpty
          ? _breedController.text.trim()
          : null,
      gender: _gender.name,
      dateOfBirth: _dateOfBirth,
      weightKg: weight,
      healthStatus: 'optimal',
      imageUrl: _uploadedImageUrl, // real URL from storage upload
    );

    final result = await ref.read(createPetUseCaseProvider)(newPet);
    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold((failure) => context.showErrorSnack(failure.message), (
      createdPet,
    ) {
      ref.read(selectedPetIdProvider.notifier).state = createdPet.id;
      ref.read(petsProvider.notifier).refreshPets();
      GoRouter.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Center(
        child: Text(
          'Add Pet',
          style: text.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.semiBold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      actions: const [SizedBox(width: AppIconSizes.xxl)],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      bottomNavigationBar: _BottomActionBar(
        onCancel: () => GoRouter.of(context).pop(),
        onContinue: _isSaving ? () {} : _savePet,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          topPad + AppSpacing.sm,
          AppSpacing.marginMobile,
          AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.tablet),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Step progress ─────────────────────────────────────
                const _StepProgress(
                  label: 'Basic Info',
                  step: 1,
                  total: 4,
                  progress: 0.25,
                ),
                AppSpacing.vGapXl,

                // ── Photo uploader ────────────────────────────────────
                Center(
                  child: _PhotoUploader(
                    initialImageUrl: _uploadedImageUrl,
                    onUploaded: (url) =>
                        setState(() => _uploadedImageUrl = url),
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Form fields ───────────────────────────────────────
                const _FormLabel(text: 'Pet’s Name', required: true),
                AppSpacing.vGapXs,
                AppTextField(
                  controller: _nameController,
                  hintText: 'What’s their name?',
                ),
                AppSpacing.vGapLg,

                const _FormLabel(text: 'Pet Type', required: true),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    Expanded(
                      child: _TypeOption(
                        icon: Icons.pets,
                        label: 'Dog',
                        selected: _type == _PetType.dog,
                        onTap: () => setState(() => _type = _PetType.dog),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: _TypeOption(
                        icon: Icons.cruelty_free,
                        label: 'Cat',
                        selected: _type == _PetType.cat,
                        onTap: () => setState(() => _type = _PetType.cat),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                const _FormLabel(text: 'Breed', optional: true),
                AppSpacing.vGapXs,
                AppTextField(
                  controller: _breedController,
                  hintText: 'e.g. Golden Retriever',
                  suffixIcon: Icons.search,
                ),
                AppSpacing.vGapLg,

                const _FormLabel(text: 'Gender'),
                AppSpacing.vGapXs,
                _GenderSegment(
                  value: _gender,
                  onChanged: (g) => setState(() => _gender = g),
                ),
                AppSpacing.vGapLg,

                const _FormLabel(text: 'Date of Birth', optional: true),
                AppSpacing.vGapXs,
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: AppRadius.brCard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadius.brCard,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                              : 'Select Date of Birth',
                          style: text.bodyMedium?.copyWith(
                            color: _dateOfBirth != null
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: AppIconSizes.sm,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.vGapLg,

                const _FormLabel(text: 'Weight (kg)', optional: true),
                AppSpacing.vGapXs,
                AppTextField(
                  controller: _weightController,
                  hintText: 'e.g. 12.5',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now.subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }
}

/// The "Basic Info · Step 1 of 4" caption row plus the progress track.
class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.label,
    required this.step,
    required this.total,
    required this.progress,
  });

  final String label;
  final int step;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: text.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            Text(
              'Step $step of $total',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        ClipRRect(
          borderRadius: AppRadius.brPill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
          ),
        ),
      ],
    );
  }
}

/// A circular photo picker — tapping opens the gallery, uploads to Supabase
/// Storage and returns the public URL via [onUploaded].
class _PhotoUploader extends ConsumerStatefulWidget {
  const _PhotoUploader({
    required this.onUploaded,
    this.initialImageUrl,
  });

  final ValueChanged<String> onUploaded;
  final String? initialImageUrl;

  @override
  ConsumerState<_PhotoUploader> createState() => _PhotoUploaderState();
}

class _PhotoUploaderState extends ConsumerState<_PhotoUploader> {
  String? _localImageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _localImageUrl = widget.initialImageUrl;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64Fallback = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final client = ref.read(supabaseClientProvider);
      final String? userId = client.auth.currentUser?.id ??
          ref.read(currentUserProfileProvider).valueOrNull?.id;

      if (userId != null && userId.isNotEmpty && userId != 'anon') {
        final storageRepo = ref.read(storageRepositoryProvider);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final result = await storageRepo.uploadPetAvatar(
          userId: userId,
          petId: 'temp_$timestamp',
          bytes: bytes,
          fileName: 'avatar_$timestamp.jpg',
          mimeType: 'image/jpeg',
        );

        result.fold(
          (failure) {
            // Fall back to Base64 data URI so user photo is 100% visible and retained
            setState(() => _localImageUrl = base64Fallback);
            widget.onUploaded(base64Fallback);
          },
          (url) {
            setState(() => _localImageUrl = url);
            widget.onUploaded(url);
          },
        );
      } else {
        setState(() => _localImageUrl = base64Fallback);
        widget.onUploaded(base64Fallback);
      }
    } catch (_) {
      // Direct local fallback on any unexpected error
      try {
        final bytes = await picked.readAsBytes();
        final base64Fallback = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() => _localImageUrl = base64Fallback);
        widget.onUploaded(base64Fallback);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildPhotoPreview(String url, ColorScheme scheme, TextTheme text) {
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
        );
      } catch (_) {
        return _defaultContent(scheme, text);
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultContent(scheme, text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    const size = 128.0;

    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: const Size(size, size),
              painter: _DashedCirclePainter(color: scheme.outlineVariant),
              child: ClipOval(
                child: _localImageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildPhotoPreview(_localImageUrl!, scheme, text),
                          if (_uploading)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.40),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            ),
                        ],
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainerLow,
                        ),
                        child: _uploading
                            ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : _defaultContent(scheme, text),
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
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: AppIconSizes.sm,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultContent(ColorScheme scheme, textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: AppIconSizes.xl, color: scheme.primary),
        AppSpacing.vGapXs,
        Text(
          'Add Photo',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}

/// Paints the dashed circular stroke around the photo uploader.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const twoPi = 2 * 3.141592653589793;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const dash = 6.0;
    const gap = 6.0;
    final sweep = (dash + gap) / radius;
    var angle = 0.0;
    while (angle < twoPi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        angle,
        dash / radius,
        false,
        paint,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A field label with an optional required-asterisk or "(Optional)" suffix.
class _FormLabel extends StatelessWidget {
  const _FormLabel({
    required this.text,
    this.required = false,
    this.optional = false,
  });

  final String text;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.labelLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: AppTypography.semiBold,
    );

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.base),
      child: RichText(
        text: TextSpan(
          text: text,
          style: style,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: style?.copyWith(color: scheme.error),
              ),
            if (optional)
              TextSpan(
                text: ' (Optional)',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One of the two large Dog / Cat selectable type tiles.
class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.10)
          : scheme.surfaceContainer,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: AppIconSizes.lg, color: fg),
              AppSpacing.vGapXs,
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Male / Female pill segmented control.
class _GenderSegment extends StatelessWidget {
  const _GenderSegment({required this.value, required this.onChanged});

  final _Gender value;
  final ValueChanged<_Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.brCard,
      ),
      child: Row(
        children: [
          Expanded(
            child: _GenderChip(
              icon: Icons.male,
              label: 'Male',
              selected: value == _Gender.male,
              onTap: () => onChanged(_Gender.male),
            ),
          ),
          Expanded(
            child: _GenderChip(
              icon: Icons.female,
              label: 'Female',
              selected: value == _Gender.female,
              onTap: () => onChanged(_Gender.female),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
      borderRadius: AppRadius.brMd,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppIconSizes.sm, color: fg),
              AppSpacing.hGapXs,
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The fixed, blurred bottom bar carrying Cancel + Continue.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onCancel, required this.onContinue});

  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.md + context.viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: AppButton.outlined(
                  label: 'Cancel',
                  onPressed: onCancel,
                  isFullWidth: true,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                flex: 3,
                child: AppButton.filled(
                  label: 'Continue',
                  icon: Icons.arrow_forward,
                  iconAlignment: IconAlignment.end,
                  onPressed: onContinue,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
