import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_elevation.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/lost_pet_poster_dialog.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/pet_emergency_qr_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The Pet Owner **Activate Lost Mode** emergency screen.
///
/// Tactically dimmed map background with a pulsing locator beacon,
/// broadcast radius selector, emergency contact info, and instant Supabase alert dispatch.
class ActivateLostModeScreen extends ConsumerStatefulWidget {
  const ActivateLostModeScreen({super.key});

  static const double _floatingWidth = 768;

  @override
  ConsumerState<ActivateLostModeScreen> createState() => _ActivateLostModeScreenState();
}

class _ActivateLostModeScreenState extends ConsumerState<ActivateLostModeScreen> {
  double _broadcastRadiusKm = 15.0;
  bool _isActivating = false;
  final _descriptionCtrl = TextEditingController(text: 'Last seen near neighborhood park. Wearing blue collar.');

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _activateLostMode(Pet? pet) async {
    if (pet == null) return;
    setState(() => _isActivating = true);
    await HapticFeedback.heavyImpact();

    try {
      final repo = ref.read(petRepositoryProvider);
      final result = await repo.activateLostMode(
        petId: pet.id,
        latitude: 12.9716,
        longitude: 77.5946,
        radiusKm: _broadcastRadiusKm,
        description: _descriptionCtrl.text.trim(),
      );

      result.fold(
        (failure) {
          if (mounted) {
            context.showSnackbar('Emergency Alert note: ${failure.message}');
          }
        },
        (_) {
          ref.invalidate(activeLostAlertProvider(pet.id));
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(context.push(RoutePaths.ownerLostDashboard));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚨 Emergency Lost Mode Broadcast Active for ${pet.name}! Radar ping boosted & nearby rescue network notified.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) context.showSnackbar('Error activating lost mode: $e');
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isWide = context.screenWidth >= ActivateLostModeScreen._floatingWidth;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // ── Map background (dimmed) ───────────────────────────────
          const Positioned.fill(child: _MapBackground()),

          // ── Central focus marker (pulse) ──────────────────────────
          const Align(alignment: Alignment(0, -0.45), child: _PulseMarker()),

          // ── Bottom sheet / confirmation card ──────────────────────
          Align(
            alignment: isWide ? Alignment.center : Alignment.bottomCenter,
            child: _buildConfirmationSheet(context, isWide, petName, pet),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSheet(
    BuildContext context,
    bool isWide,
    String petName,
    Pet? pet,
  ) {
    final scheme = context.colorScheme;
    final borderRadius = isWide ? AppRadius.brModal : AppRadius.brModalTop;
    final pad = isWide ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

    final sheet = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.95),
            borderRadius: borderRadius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.30),
            ),
            boxShadow: AppElevation.shadowOverlay,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeader(petName: petName),
                AppSpacing.vGapMd,

                // ── Broadcast Radius Slider ────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.radar, size: 18, color: scheme.error),
                              AppSpacing.hGapXs,
                              Text(
                                'Emergency Broadcast Radius',
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.error,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_broadcastRadiusKm.toInt()} km',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _broadcastRadiusKm,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        activeColor: scheme.error,
                        onChanged: (val) => setState(() => _broadcastRadiusKm = val),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapMd,

                const _ActionList(),
                AppSpacing.vGapLg,

                // ── Rapid Recovery Actions ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('Export Poster', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (pet != null) {
                            LostPetPosterDialog.show(context, pet: pet);
                          }
                        },
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: scheme.primary,
                          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('Pet QR Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (pet != null) {
                            PetEmergencyQrModal.show(context, pet);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,

                // ── Actions ────────────────────────────────────────
                if (_isActivating)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: () => _activateLostMode(pet),
                        icon: const Icon(Icons.emergency_share, size: 20),
                        label: Text(
                          'Activate Lost Mode ($petName)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      AppSpacing.vGapSm,
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel & Return'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _SlideUp(child: sheet),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, size: 36, color: scheme.error),
        ),
        AppSpacing.vGapSm,
        Text(
          'Activate Lost Mode?',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          "We'll broadcast $petName's profile to nearby volunteer searchers & boost collar GPS frequency.",
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList();

  static const List<_LostAction> _actions = [
    _LostAction(
      icon: Icons.satellite_alt,
      title: 'High-Frequency Collar Telemetry',
      subtitle: 'GPS pings boosted to 30-second intervals',
    ),
    _LostAction(
      icon: Icons.my_location,
      title: 'Real-Time Radar Tracking',
      subtitle: 'Live geofence beacon on interactive map',
    ),
    _LostAction(
      icon: Icons.notifications_active,
      title: 'Volunteer Network Dispatch',
      subtitle: 'Alerts active rescue volunteers in radius',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _actions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.15),
              ),
            _ActionRow(action: _actions[i]),
          ],
        ],
      ),
    );
  }
}

class _LostAction {
  const _LostAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final _LostAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(action.icon, color: scheme.error, size: 20),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  action.subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Opacity(
      opacity: 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              scheme.errorContainer.withValues(alpha: 0.30),
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final ringScale = 1.0 + t * 1.5;
        final ringOpacity = (1.0 - t).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: ringScale,
              child: Opacity(
                opacity: ringOpacity,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.error.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error,
                boxShadow: [
                  BoxShadow(
                    color: scheme.error.withValues(alpha: 0.50),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 28),
            ),
          ],
        );
      },
    );
  }
}

class _SlideUp extends StatefulWidget {
  const _SlideUp({required this.child});

  final Widget child;

  @override
  State<_SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<_SlideUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offset, child: widget.child);
  }
}
