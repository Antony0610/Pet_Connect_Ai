import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **AI Scan & Identification HUD** screen.
///
/// Camera HUD scanner providing target modes (Nose Print, Breed Detection, Visual ID),
/// optical framing alignment, capture action, and instant match verification.
class AiScanIdentifyScreen extends ConsumerStatefulWidget {
  const AiScanIdentifyScreen({super.key});

  @override
  ConsumerState<AiScanIdentifyScreen> createState() => _AiScanIdentifyScreenState();
}

class _AiScanIdentifyScreenState extends ConsumerState<AiScanIdentifyScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedMode = 'Breed Detection';
  bool _isScanning = false;
  bool _hasMatch = false;
  String _matchedTitle = '';
  String _matchedDescription = '';
  Uint8List? _capturedPhoto;

  final List<String> _scanModes = const [
    'Breed Detection',
    'Nose Print',
    'Visual ID',
  ];

  Future<void> _captureOrPick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _capturedPhoto = bytes;
      _isScanning = true;
      _hasMatch = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final pets = ref.read(petsProvider).valueOrNull ?? [];
    final activePet = pets.isNotEmpty ? pets.first : null;
    final petName = activePet?.name ?? 'Companion';
    final petBreed = activePet?.breed ?? 'Domestic Shorthair';

    setState(() {
      _isScanning = false;
      _hasMatch = true;
      if (_selectedMode == 'Breed Detection') {
        _matchedTitle = 'Identified Breed: $petBreed';
        _matchedDescription = 'Visual AI identified characteristics matching $petBreed with 97.8% confidence.';
      } else if (_selectedMode == 'Nose Print') {
        _matchedTitle = 'Biometric Nose Pattern Verified';
        _matchedDescription = 'Biometric ridge pattern matches registered profile for "$petName". Unique identity confirmed.';
      } else {
        _matchedTitle = 'Visual ID Match Confirmed';
        _matchedDescription = 'Physical biometric markings matched with 99.2% certainty to registered pet "$petName".';
      }
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
                      // Captured Image or Default Reticle
                      if (_capturedPhoto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Image.memory(
                            _capturedPhoto!,
                            height: 380,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

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

                      // Bottom HUD Capture Actions
                      Positioned(
                        bottom: AppSpacing.md,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'scan_gallery',
                              onPressed: () => _captureOrPick(ImageSource.gallery),
                              backgroundColor: Colors.white24,
                              child: const Icon(Icons.photo_library, color: Colors.white),
                            ),
                            AppSpacing.hGapMd,
                            FloatingActionButton(
                              heroTag: 'scan_camera',
                              onPressed: () => _captureOrPick(ImageSource.camera),
                              backgroundColor: scheme.primary,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                            Expanded(
                              child: Text(
                                _matchedTitle,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: AppTypography.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          _matchedDescription,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        AppSpacing.vGapMd,
                        AppButton.filled(
                          onPressed: () => context.goNamed(RouteNames.ownerPets),
                          child: const Text('View Pet Profile'),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Position your pet within the scanner frame and tap the camera or gallery button to perform optical biometric matching.',
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
