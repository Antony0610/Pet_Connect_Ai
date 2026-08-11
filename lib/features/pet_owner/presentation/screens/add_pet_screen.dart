import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';

/// The Pet Owner **Add Pet — Basic Info** screen (wizard step 1 of 4).
///
/// A faithful Flutter rendering of the frozen Stitch "Add Pet - Step 1"
/// (Light master): a transactional glass header, a step progress indicator,
/// a dashed-circle photo uploader, and a form card (name, pet-type toggle,
/// breed, gender segment) with a fixed bottom action bar. Every color,
/// spacing, radius and type comes from the theme / design tokens so one
/// widget tree serves both Light and Dark.
class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

enum _PetType { dog, cat }

enum _Gender { male, female }

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  _PetType _type = _PetType.dog;
  _Gender _gender = _Gender.female;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
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
        onContinue: () => GoRouter.of(context).pop(),
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
                const Center(child: _PhotoUploader()),
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
              ],
            ),
          ),
        ),
      ),
    );
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

/// A circular, dashed-border photo drop target with an "add" affordance.
class _PhotoUploader extends StatelessWidget {
  const _PhotoUploader();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(128, 128),
            painter: _DashedCirclePainter(color: scheme.outlineVariant),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerLow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: AppIconSizes.xl,
                    color: scheme.primary,
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    'Upload Photo',
                    style: text.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ],
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
                Icons.add,
                size: AppIconSizes.sm,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
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
