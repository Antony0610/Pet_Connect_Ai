import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **AI Health Analysis**
/// (Light Theme design authority, ID `ca587b92c5c349c482c261a395ad561a`).
///
/// Provides photo upload/capture for symptom analysis, AI confidence assessment,
/// guidance cards, and medical disclaimers.
class AiHealthAnalysisScreen extends StatefulWidget {
  const AiHealthAnalysisScreen({super.key});

  @override
  State<AiHealthAnalysisScreen> createState() => _AiHealthAnalysisScreenState();
}

class _AiHealthAnalysisScreenState extends State<AiHealthAnalysisScreen> {
  static const double _maxContentWidth = 1000;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'AI Health Analysis',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Subtitle ────────────────────────────────
                Text(
                  'Upload a photo of your pet to analyze symptoms or visible conditions. Our AI will process the image for initial insights.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Photo Upload Zone / Result ─────────────────────
                if (!_hasAnalyzed) ...[
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    backgroundColor: scheme.surfaceContainerLow,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: scheme.primary,
                            ),
                          ),
                          AppSpacing.vGapMd,
                          Text(
                            'Tap to Upload Photo',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Supports JPG, PNG up to 10MB',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.vGapLg,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppButton.filled(
                                onPressed: _isAnalyzing
                                    ? null
                                    : () {
                                        setState(() => _isAnalyzing = true);
                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _isAnalyzing = false;
                                                _hasAnalyzed = true;
                                              });
                                            }
                                          },
                                        );
                                      },
                                child: _isAnalyzing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.photo_camera, size: 18),
                                          AppSpacing.hGapXs,
                                          Text('Take Photo'),
                                        ],
                                      ),
                              ),
                              AppSpacing.hGapSm,
                              AppButton.outlined(
                                onPressed: () {
                                  setState(() => _hasAnalyzed = true);
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library, size: 18),
                                    AppSpacing.hGapXs,
                                    Text('Gallery'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.vGapXl,

                  // ── Capture Guidance Cards ─────────────────────────
                  const SectionHeader(title: 'Capture Guidance'),
                  AppSpacing.vGapSm,
                  _buildGuidanceItem(
                    context,
                    title: 'Bright Lighting',
                    subtitle:
                        'Ensure clear, natural lighting for accurate color analysis.',
                  ),
                  AppSpacing.vGapXs,
                  _buildGuidanceItem(
                    context,
                    title: 'Center Area of Concern',
                    subtitle:
                        'Keep the affected skin or coat area clear and centered.',
                  ),
                  AppSpacing.vGapXs,
                  _buildGuidanceItem(
                    context,
                    title: 'Steady Device',
                    subtitle: 'Avoid camera motion blur during photo capture.',
                  ),
                ] else ...[
                  // ── Analysis Result Verdict ────────────────────────
                  AiGradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              avatar: Icon(
                                Icons.psychology,
                                size: 16,
                                color: scheme.onPrimary,
                              ),
                              label: const Text('AI Assessment'),
                              backgroundColor: scheme.primary,
                              labelStyle: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: const Text('92% Confidence'),
                              backgroundColor: scheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: scheme.onSecondaryContainer,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapMd,
                        Text(
                          'Mild Mild Dermatitis / Allergic Rash Detected',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          'Visual scan shows localized redness and slight flaking around the left ear fold. Non-urgent condition.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        AppSpacing.vGapLg,

                        // ── Medical Safety Disclaimer ─────────────────────
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: scheme.onSurfaceVariant,
                                size: 18,
                              ),
                              AppSpacing.hGapSm,
                              Expanded(
                                child: Text(
                                  'AI-generated assessment only. Not a confirmed veterinary diagnosis.',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vGapLg,

                        // ── Recommended Next Actions ──────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.filled(
                                onPressed: () => context.goNamed(
                                  RouteNames.ownerAiDiagnostic,
                                ),
                                child: const Text('Open Diagnostic Center'),
                              ),
                            ),
                            AppSpacing.hGapSm,
                            AppButton.outlined(
                              onPressed: () =>
                                  setState(() => _hasAnalyzed = false),
                              child: const Text('New Scan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceItem(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final scheme = context.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle, color: scheme.primary, size: 20),
      title: Text(
        title,
        style: context.textTheme.labelLarge?.copyWith(
          fontWeight: AppTypography.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
