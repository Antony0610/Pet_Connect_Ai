import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/lost_pet_poster_dialog.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/pet_emergency_qr_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// Centralized emergency command dashboard connecting collar Lost Mode radar,
/// community sighting reports, AI probability matches, and volunteer dispatch.
class LostPetDashboardScreen extends ConsumerStatefulWidget {
  const LostPetDashboardScreen({super.key});

  @override
  ConsumerState<LostPetDashboardScreen> createState() => _LostPetDashboardScreenState();
}

class _LostPetDashboardScreenState extends ConsumerState<LostPetDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const double _maxContentWidth = 1000;
  late final AnimationController _sonarController;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sonarController.dispose();
    super.dispose();
  }

  Future<void> _confirmMarkPetFound(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Pet Safe & Found?'),
          ],
        ),
        content: Text(
          'Marking ${pet.name} as found will deactivate emergency Lost Mode, notify all alerted volunteers, and return collar GPS to normal conservation frequency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm: Safe at Home'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResolving = true);
    await HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.resolveLostMode(pet.id);
      ref.invalidate(activeLostAlertProvider(pet.id));

      if (!mounted) return;
      context.showSnackbar('🎉 Fantastic news! ${pet.name} marked as safe and Lost Mode deactivated.');
    } catch (e) {
      if (mounted) context.showSnackbar('Resolution error: $e');
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';
    final petBreed = pet?.breed ?? 'Pet';
    final petId = pet?.id ?? '';

    final activeAlertAsync = petId.isNotEmpty ? ref.watch(activeLostAlertProvider(petId)) : null;
    final sightingsAsync = ref.watch(communitySightingsProvider(petId));

    final isLostActive = activeAlertAsync?.asData?.value != null;
    final radiusKm = (activeAlertAsync?.asData?.value?['broadcast_radius_km'] as num?) ?? 15;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Emergency Command Center',
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.error,
            fontWeight: AppTypography.bold,
          ),
        ),
        actions: [
          if (pet != null) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'Emergency QR Pass',
              onPressed: () => PetEmergencyQrModal.show(context, pet),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Generate Lost Pet Poster',
              onPressed: () => LostPetPosterDialog.show(context, pet: pet),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Radar Sonar Banner ───────────────────────
                _buildRadarCard(theme, scheme, petName, petBreed, isLostActive, radiusKm),
                AppSpacing.vGapLg,

                // ── Emergency Action Toolkit (Poster & QR) ────────
                if (pet != null) ...[
                  _buildEmergencyToolkit(theme, scheme, pet),
                  AppSpacing.vGapLg,
                ],

                // ── Live Volunteer Response Status ─────────────────
                _buildVolunteerResponseBanner(theme, scheme, radiusKm),
                AppSpacing.vGapLg,

                // ── Recent Community Sightings ─────────────────────
                _buildSightingsSection(theme, scheme, sightingsAsync),
                AppSpacing.vGapLg,

                // ── Resolution Bar (Found Pet) ─────────────────────
                if (pet != null)
                  _buildResolutionBar(theme, scheme, pet),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyToolkit(ThemeData theme, ColorScheme scheme, Pet pet) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 20, color: scheme.primary),
              AppSpacing.hGapXs,
              Text(
                'Rapid Recovery Toolkit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Export Poster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => LostPetPosterDialog.show(context, pet: pet),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: const Text('Pet QR Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => PetEmergencyQrModal.show(context, pet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard(
    ThemeData theme,
    ColorScheme scheme,
    String petName,
    String petBreed,
    bool isLostActive,
    num radiusKm,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isLostActive ? scheme.error.withValues(alpha: 0.8) : scheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: isLostActive
            ? [
                BoxShadow(
                  color: scheme.error.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLostActive ? scheme.error : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLostActive ? 'EMERGENCY RADAR ACTIVE' : 'RADAR STANDBY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isLostActive ? scheme.error : Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Radius: $radiusKm km',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,

          // Radar Graphic & Pet Title
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(80, 80),
                      painter: _SonarRadarPainter(
                        animation: _sonarController,
                        color: scheme.error,
                      ),
                    ),
                    const Icon(Icons.pets, color: Colors.white, size: 24),
                  ],
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missing: $petName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$petBreed • Collar Beacon Transmitting at 30s intervals',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,

          // Live Radar Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => context.goNamed(RouteNames.ownerCollarTracking),
                  icon: const Icon(Icons.satellite_alt, size: 16),
                  label: const Text('Live GPS Radar Map'),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () => context.goNamed(RouteNames.ownerCommunitySightings),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('Community Sightings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerResponseBanner(ThemeData theme, ColorScheme scheme, num radiusKm) {
    return AppCard(
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: scheme.primary, size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '18 Active Volunteer Rescuers Alerted',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Emergency push broadcast sent to all registered pet searchers in the $radiusKm km corridor.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightingsSection(
    ThemeData theme,
    ColorScheme scheme,
    AsyncValue<List<Map<String, dynamic>>> sightingsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Community Sighting Reports',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: AppTypography.bold),
            ),
            TextButton.icon(
              onPressed: () => context.goNamed(RouteNames.ownerCommunitySightings),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View All'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        sightingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Could not load sightings: $e'),
          ),
          data: (sightings) {
            if (sightings.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.radar, size: 36, color: scheme.onSurfaceVariant),
                      AppSpacing.vGapSm,
                      Text(
                        'Scanning for Community Sightings',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'No matching sightings reported in the last 24h. Local volunteers are keeping active watch.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: sightings.take(3).map((s) {
                final loc = s['location_name'] as String? ?? 'Nearby Area';
                final notes = s['notes'] as String? ?? 'Sighting reported';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => context.goNamed(RouteNames.ownerCommunitySightings),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.errorContainer,
                          child: Icon(Icons.remove_red_eye, color: scheme.onErrorContainer, size: 18),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                notes,
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResolutionBar(ThemeData theme, ColorScheme scheme, Pet pet) {
    return AppCard(
      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found your companion?',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Deactivate Lost Mode to stop emergency beacon broadcasts.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_isResolving)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmMarkPetFound(pet),
              child: const Text('Mark Safe'),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the glowing sonar radar concentric animation
class _SonarRadarPainter extends CustomPainter {
  _SonarRadarPainter({required this.animation, required this.color}) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Static concentric rings
    canvas.drawCircle(center, maxRadius * 0.33, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.66, ringPaint);
    canvas.drawCircle(center, maxRadius, ringPaint);

    // Expanding pulsing wave
    final waveRadius = maxRadius * animation.value;
    final waveOpacity = (1.0 - animation.value).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: waveOpacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, waveRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _SonarRadarPainter oldDelegate) => true;
}
