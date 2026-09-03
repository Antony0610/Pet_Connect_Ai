import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Mission Completed Screen (Stitch ID: `97a26f78f6d4445795807aa4f188124f`).
///
/// Rescue debrief and reunion summary view. Displays duration metrics, distance covered,
/// owner gratitude quote, photo proof placeholder, and return to dashboard action.
class MissionCompletedScreen extends StatefulWidget {
  const MissionCompletedScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  @override
  State<MissionCompletedScreen> createState() => _MissionCompletedScreenState();
}

class _MissionCompletedScreenState extends State<MissionCompletedScreen> {
  bool _photoAttached = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Resolution'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Rescue Successful Celebration Banner ───────────
                _buildSuccessCelebrationBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Mission Impact Metrics Row ──────────────────────
                _buildImpactMetricsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Owner Gratitude Testimonial ──────────────────────
                _buildOwnerTestimonialCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Photo Proof & Reunion Report Action ─────────────
                _buildReunionPhotoUploadCard(context, theme, colorScheme),

                AppSpacing.vGapXl,

                // ── Return to Dashboard Button ──────────────────────
                AppButton(
                  text: 'Return to Mission Dashboard',
                  icon: Icons.dashboard,
                  isFullWidth: true,
                  onPressed: () => context.go('/rescue'),
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 48,
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCelebrationBanner(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.success,
            child: Icon(Icons.pets, size: 36, color: Colors.white),
          ),
          AppSpacing.vGapMd,
          Text(
            'Rescue Successful!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: AppTypography.bold,
              color: AppColors.success,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Luna has been safely reunited with her family.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetricsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '42m',
            label: 'Duration',
            icon: Icons.timer_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '1.9 km',
            label: 'Covered',
            icon: Icons.route_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '4 Team',
            label: 'Volunteers',
            icon: Icons.group_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerTestimonialCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Incident Resolution & Debrief Log',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Record field debrief notes, animal physiological condition, or guardian handover details...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.check, size: 14),
                label: const Text('Reunited with Guardian'),
                onPressed: () {
                  setState(() {
                    _notesController.text = 'Pet successfully identified and safely reunited with verified guardian in stable condition.';
                  });
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.local_hospital, size: 14),
                label: const Text('Transferred to Vet'),
                onPressed: () {
                  setState(() {
                    _notesController.text = 'Delivered to nearest accredited veterinary clinic for medical examination and stabilization.';
                  });
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.home_work, size: 14),
                label: const Text('Sheltered at EOC'),
                onPressed: () {
                  setState(() {
                    _notesController.text = 'Transferred to emergency overflow shelter facility. Microchip scan and intake logged.';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReunionPhotoUploadCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _photoAttached ? Icons.check_circle : Icons.add_a_photo_outlined,
                color: _photoAttached ? AppColors.success : colorScheme.primary,
                size: 28,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _photoAttached ? 'Reunion Photo Attached' : 'Reunion Photo & Proof',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      _photoAttached
                          ? 'Photo uploaded to community field records.'
                          : 'Upload photo for community field records.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _photoAttached
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.check, size: 16, color: AppColors.success),
                      label: const Text('Change'),
                      onPressed: () {
                        setState(() => _photoAttached = false);
                      },
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Attach'),
                      onPressed: () {
                        setState(() => _photoAttached = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reunion photo attached successfully!')),
                        );
                      },
                    ),
            ],
          ),
          if (_photoAttached) ...[
            AppSpacing.vGapMd,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: colorScheme.primaryContainer,
                      child: Icon(Icons.pets, color: colorScheme.primary),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'reunion_luna_cubbon_park.jpg',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Captured by Alex Rivera • GPS verified',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
