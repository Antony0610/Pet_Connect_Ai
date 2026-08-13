import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **AI Scan & Identification HUD**
/// (Light Theme design authority, ID `c461c65970c64ee0961712de4ea38cd6`).
///
/// Camera HUD scanner providing target modes (Nose Print, Breed Detection, Visual ID),
/// optical framing alignment, capture action, and instant match verification.
class AiScanIdentifyScreen extends StatefulWidget {
  const AiScanIdentifyScreen({super.key});

  @override
  State<AiScanIdentifyScreen> createState() => _AiScanIdentifyScreenState();
}

class _AiScanIdentifyScreenState extends State<AiScanIdentifyScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedMode = 'Nose Print';
  final bool _isScanning = false;
  bool _hasMatch = false;

  final List<String> _scanModes = const [
    'Nose Print',
    'Breed Detection',
    'Visual ID',
  ];

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
          'AI Scan & Identify HUD',
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
                // ── Mode Selector Chips ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _scanModes.map((mode) {
                    final isSelected = _selectedMode == mode;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: isSelected,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMode = mode;
                              _hasMatch = false;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Camera Scanner HUD Container ───────────────────
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // HUD Alignment Reticle Frame
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hasMatch
                                ? Colors.greenAccent
                                : scheme.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Icon(
                            _selectedMode == 'Nose Print'
                                ? Icons.fingerprint
                                : Icons.pets,
                            size: 64,
                            color: _hasMatch
                                ? Colors.greenAccent
                                : scheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      // Mode Guidance Overlay Banner
                      Positioned(
                        top: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'Align pet\'s ${_selectedMode.toLowerCase()} within frame',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ),
                      ),

                      // Scanning Animation Indicator
                      if (_isScanning)
                        const CircularProgressIndicator(color: Colors.white),

                      // Bottom HUD Capture Button
                      Positioned(
                        bottom: AppSpacing.md,
                        child: FloatingActionButton(
                          onPressed: () {
                            context.showSnackbar(
                              'Camera Hardware Required — Scan feature waiting for camera device input.',
                            );
                          },
                          backgroundColor: scheme.primary,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Match Result Card ───────────────────────────────
                if (_hasMatch)
                  AppCard(
                    backgroundColor: scheme.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: scheme.primary,
                              size: 24,
                            ),
                            AppSpacing.hGapSm,
                            Text(
                              'Identification Match Confirmed!',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          _selectedMode == 'Nose Print'
                              ? 'Biometric Nose Print matched to registered pet: "Max" (ID #PET-9842)'
                              : _selectedMode == 'Breed Detection'
                              ? 'Breed identified: Golden Retriever (98.4% Confidence)'
                              : 'Visual ID match found in local neighborhood network.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        AppSpacing.vGapMd,
                        AppButton.filled(
                          onPressed: () =>
                              context.goNamed(RouteNames.ownerPetDetail),
                          child: const Text('View Pet Profile'),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Position your pet within the scanner frame and tap the camera button to perform optical biometric matching.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
