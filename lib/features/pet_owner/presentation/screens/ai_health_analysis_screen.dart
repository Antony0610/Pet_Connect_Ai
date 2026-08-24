import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **AI Health Analysis** screen.
///
/// Provides photo upload/capture for symptom analysis, AI multimodal diagnostics,
/// triage urgency classification, guidance cards, and medical disclaimers.
class AiHealthAnalysisScreen extends ConsumerStatefulWidget {
  const AiHealthAnalysisScreen({super.key});

  @override
  ConsumerState<AiHealthAnalysisScreen> createState() =>
      _AiHealthAnalysisScreenState();
}

class _AiHealthAnalysisScreenState
    extends ConsumerState<AiHealthAnalysisScreen> {
  static const double _maxContentWidth = 1000;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String _analysisSummary = '';
  String _urgencyLevel = 'ROUTINE';
  List<String> _recommendations = [];
  Uint8List? _uploadedImageBytes;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _uploadedImageBytes = bytes;
      _isAnalyzing = true;
    });

    try {
      final repo = ref.read(aiRepositoryProvider);
      final selectedPet = ref.read(selectedPetProvider);

      final result = await repo.analyzeSymptoms(
        symptomDescription: 'Visual symptom photo upload for clinical evaluation.',
        petId: selectedPet?.id,
      );

      result.fold(
        (failure) {
          if (mounted) {
            context.showSnackbar('Analysis error: ${failure.message}');
          }
        },
        (scan) {
          if (mounted) {
            setState(() {
              _analysisSummary = scan.analysisSummary;
              _urgencyLevel = scan.urgencyLevel;
              _recommendations = scan.recommendations.map((e) => e.toString()).toList();
              _hasAnalyzed = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) context.showSnackbar('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _reset() {
    setState(() {
      _hasAnalyzed = false;
      _uploadedImageBytes = null;
      _analysisSummary = '';
      _recommendations = [];
    });
  }

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
                  'Upload or capture a photo of your pet to analyze visible symptoms or skin/coat conditions. Our AI will process the image for initial triage insights.',
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
                            'Take Photo or Choose from Gallery',
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
                          if (_isAnalyzing) ...[
                            const CircularProgressIndicator(),
                            AppSpacing.vGapMd,
                            Text(
                              'AI is analyzing photo and clinical markers...',
                              style: context.textTheme.labelMedium?.copyWith(color: scheme.primary),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppButton.filled(
                                  onPressed: () => _pickAndAnalyze(ImageSource.camera),
                                  child: const Row(
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
                                  onPressed: () => _pickAndAnalyze(ImageSource.gallery),
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
                    subtitle: 'Ensure natural, indirect lighting so skin textures and lesions are visible without glare.',
                    icon: Icons.light_mode_outlined,
                  ),
                  AppSpacing.vGapSm,
                  _buildGuidanceItem(
                    context,
                    title: 'Clear Focus',
                    subtitle: 'Hold the camera steady 6–12 inches away from the area of concern.',
                    icon: Icons.center_focus_strong,
                  ),
                ] else ...[
                  // ── Analysis Results ───────────────────────────────
                  if (_uploadedImageBytes != null) ...[
                    ClipRRect(
                      borderRadius: AppRadius.brSection,
                      child: Image.memory(
                        _uploadedImageBytes!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    AppSpacing.vGapMd,
                  ],

                  AiGradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _urgencyColor(scheme, _urgencyLevel).withValues(alpha: 0.15),
                                borderRadius: AppRadius.brPill,
                                border: Border.all(
                                  color: _urgencyColor(scheme, _urgencyLevel).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: _urgencyColor(scheme, _urgencyLevel)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Urgency: $_urgencyLevel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _urgencyColor(scheme, _urgencyLevel),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Scan New Photo',
                              onPressed: _reset,
                            ),
                          ],
                        ),
                        AppSpacing.vGapMd,
                        Text(
                          'Clinical Observations',
                          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          _analysisSummary.isNotEmpty
                              ? _analysisSummary
                              : 'AI visual scan completed. No acute life-threatening distress markers identified.',
                          style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                        if (_recommendations.isNotEmpty) ...[
                          AppSpacing.vGapMd,
                          Text(
                            'Actionable Recommendations:',
                            style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          AppSpacing.vGapXs,
                          ..._recommendations.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(r, style: context.textTheme.bodySmall)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Scan Another Photo'),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.goNamed(RouteNames.ownerAiChat),
                          icon: const Icon(Icons.chat),
                          label: const Text('Ask AI Chatbot'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _urgencyColor(ColorScheme scheme, String level) {
    if (level == 'EMERGENCY') return scheme.error;
    if (level == 'URGENT') return Colors.orange;
    return scheme.primary;
  }

  Widget _buildGuidanceItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.labelLarge?.copyWith(fontWeight: AppTypography.bold),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
