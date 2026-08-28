import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/services/health_passport_exporter.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/pet_emergency_qr_modal.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/cards/glass_card.dart';

class PetProfileDetailScreen extends ConsumerWidget {
  const PetProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final width = context.screenWidth;
    final isWide = AppBreakpoints.isDesktop(width);
    final margin = _horizontalMargin(width);

    final petId =
        GoRouterState.of(context).pathParameters['petId'] ??
        ref.watch(selectedPetIdProvider);
    final petAsync = petId != null
        ? ref.watch(petDetailProvider(petId))
        : const AsyncValue.data(null);
    final pet = petAsync.valueOrNull ?? ref.watch(selectedPetProvider);

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Text(
        pet?.name ?? 'Pet Profile',
        style: context.textTheme.headlineSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: AppTypography.bold,
          letterSpacing: -0.25,
        ),
      ),
      actions: [
        if (pet != null)
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Emergency QR Pass',
            onPressed: () => PetEmergencyQrModal.show(context, pet),
          ),
        if (pet != null)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Health Passport',
            onPressed: () async {
              final owner = ref.read(currentUserProfileProvider).valueOrNull;
              final vaccinations = ref.read(vaccinationsProvider(pet.id)).valueOrNull ?? [];
              final healthRecords = ref.read(healthRecordsProvider(pet.id)).valueOrNull ?? [];
              final weightLogs = ref.read(petWeightLogsProvider(pet.id)).valueOrNull ?? [];

              await HealthPassportExporter.exportAndShare(
                context: context,
                pet: pet,
                owner: owner,
                vaccinations: vaccinations,
                healthRecords: healthRecords,
                weightLogs: weightLogs,
              );
            },
          ),
        if (pet != null)
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Pet Profile',
            onPressed: () => ExternalActions.shareText(
              '🐾 Meet ${pet.name} on PetConnect AI!\nSpecies: ${pet.species} • Breed: ${pet.breed}\nHealth Status: ${pet.healthStatus}\nWeight: ${pet.weightKg != null ? "${pet.weightKg} kg" : "—"}',
              subject: '${pet.name}\'s Pet Profile',
            ),
          ),
        if (pet != null)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () => context.goNamed(
              RouteNames.ownerPetEdit,
              pathParameters: {'petId': pet.id},
            ),
          ),
        if (pet != null)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pet Settings',
            onPressed: () => context.goNamed(
              RouteNames.ownerPetSettings,
              pathParameters: {'petId': pet.id},
            ),
          ),
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero photo ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    topPad + AppSpacing.md,
                    margin,
                    0,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.brCard,
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: isWide ? 21 / 9 : 4 / 3,
                          child: pet?.imageUrl != null &&
                                  pet!.imageUrl!.isNotEmpty
                              ? Image.network(
                                  pet.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _HeroFallback(wide: isWide),
                                )
                              : _HeroFallback(wide: isWide),
                        ),
                        if (!isWide)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    context.colorScheme.surface.withValues(
                                      alpha: 0,
                                    ),
                                    context.colorScheme.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ── Overlapping pet info card ───────────────────────────
                Transform.translate(
                  offset: Offset(0, isWide ? 0 : -AppSpacing.xl),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? margin : AppSpacing.sm,
                    ),
                    child: _PetInfoCard(palette: palette, pet: pet),
                  ),
                ),
                if (!isWide)
                  const SizedBox(height: AppSpacing.xl - AppSpacing.sm),
                // ── Quick Actions ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    isWide ? AppSpacing.xl : AppSpacing.sm,
                    margin,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: context.textTheme.headlineSmall,
                      ),
                      AppSpacing.vGapMd,
                      _QuickActionsGrid(wide: isWide, pet: pet),
                    ],
                  ),
                ),
                // ── Bento details ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    AppSpacing.xl,
                    margin,
                    0,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _PersonalityActivityColumn(pet: pet)),
                            AppSpacing.hGapMd,
                            Expanded(flex: 2, child: _TimelinePreviewCard(petId: pet?.id)),
                          ],
                        )
                      : _PersonalityActivityColumn(pet: pet),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

/// Glass info card overlapping the hero: name / breed + age / weight stats.
class _PetInfoCard extends StatelessWidget {
  const _PetInfoCard({required this.palette, required this.pet});

  final PortalPalette palette;
  final Pet? pet;

  @override
  Widget build(BuildContext context) {
    final name = pet?.name ?? 'Companion';
    final breedStr = pet?.breedLine ?? 'Pet Details';
    final weightStr = pet?.weightKg != null ? '${pet!.weightKg}kg' : 'N/A';

    return GlassCard(
      padding: AppSpacing.cardPaddingPremium,
      borderRadius: AppRadius.brCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: context.textTheme.headlineLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
              Text(
                breedStr,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _PetStatBox(
                label: 'Species',
                value: pet?.species.toUpperCase() ?? 'DOG',
              ),
              AppSpacing.hGapSm,
              _PetStatBox(label: 'Weight', value: weightStr),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact stat tile (Age / Weight) inside the pet info card.
class _PetStatBox extends StatelessWidget {
  const _PetStatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          RichText(
            text: TextSpan(
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: AppTypography.semiBold,
              ),
              children: [TextSpan(text: value)],
            ),
          ),
          if (value.endsWith('lb'))
            Text(
              'lb',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The eight-slot quick-actions grid (4 across on mobile, 8 across on desktop).
class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid({required this.wide, this.pet});

  final bool wide;
  final Pet? pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <_QuickAction>[
      _QuickAction(
        label: 'Health',
        icon: Icons.favorite,
        iconFilled: true,
        background: context.colorScheme.primaryContainer.withValues(
          alpha: 0.10,
        ),
        color: context.colorScheme.primary,
        onTap: () => context.push(RoutePaths.ownerHealth),
      ),
      _QuickAction(
        label: 'AI Care',
        icon: Icons.smart_toy,
        iconFilled: true,
        background: Color.alphaBlend(
          context.colorScheme.secondaryContainer.withValues(alpha: 0.35),
          context.colorScheme.primaryContainer.withValues(alpha: 0.25),
        ),
        color: context.colorScheme.primary,
        onTap: () => context.push(RoutePaths.ownerAiAssistant),
      ),
      _QuickAction(
        label: 'QR Pass',
        icon: Icons.qr_code_2_rounded,
        iconFilled: true,
        background: context.colorScheme.primaryContainer.withValues(alpha: 0.20),
        color: context.colorScheme.primary,
        onTap: () {
          if (pet != null) {
            PetEmergencyQrModal.show(context, pet!);
          }
        },
      ),
      _QuickAction(
        label: 'PDF Export',
        icon: Icons.picture_as_pdf_outlined,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () async {
          if (pet != null) {
            final owner = ref.read(currentUserProfileProvider).valueOrNull;
            final vaccinations = ref.read(vaccinationsProvider(pet!.id)).valueOrNull ?? [];
            final healthRecords = ref.read(healthRecordsProvider(pet!.id)).valueOrNull ?? [];
            final weightLogs = ref.read(petWeightLogsProvider(pet!.id)).valueOrNull ?? [];

            await HealthPassportExporter.exportAndShare(
              context: context,
              pet: pet!,
              owner: owner,
              vaccinations: vaccinations,
              healthRecords: healthRecords,
              weightLogs: weightLogs,
            );
          }
        },
      ),
      _QuickAction(
        label: 'Collar',
        icon: Icons.pets,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () => context.push(RoutePaths.ownerCollar),
      ),
      _QuickAction(
        label: 'Appts',
        icon: Icons.event,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () => context.push(RoutePaths.ownerHealthTimeline),
      ),
      _QuickAction(
        label: 'Lost Mode',
        icon: Icons.location_on,
        background: context.colorScheme.errorContainer.withValues(alpha: 0.20),
        color: context.colorScheme.error,
        onTap: () => context.push(RoutePaths.ownerLostMode),
      ),
      _QuickAction(
        label: 'Gallery',
        icon: Icons.photo_library_outlined,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () {
          if (pet != null) {
            context.pushNamed(
              RouteNames.ownerPetGallery,
              pathParameters: {'petId': pet!.id},
            );
          }
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 8 : 4,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

/// A single quick-action tile.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.color,
    this.iconFilled = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color color;
  final bool iconFilled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.brLg,
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: AppRadius.brLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppIconSizes.lg,
                color: color,
                fill: iconFilled ? 1 : 0,
              ),
              AppSpacing.vGapXs,
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bento left column: personality tags + activity level card.
class _PersonalityActivityColumn extends StatelessWidget {
  const _PersonalityActivityColumn({this.pet});

  final Pet? pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PersonalityCard(pet: pet),
        AppSpacing.vGapMd,
        _ActivityLevelCard(pet: pet),
        if (!AppBreakpoints.isDesktop(context.screenWidth)) ...[
          AppSpacing.vGapMd,
          _TimelinePreviewCard(petId: pet?.id),
        ],
      ],
    );
  }
}

/// Personality tags card.
class _PersonalityCard extends StatelessWidget {
  const _PersonalityCard({this.pet});

  final Pet? pet;

  @override
  Widget build(BuildContext context) {
    final species = (pet?.species ?? 'dog').toLowerCase();
    final List<String> tags;
    if (species.contains('cat')) {
      tags = const ['Calm', 'Independent', 'Playful'];
    } else if (species.contains('bird')) {
      tags = const ['Curious', 'Vocal', 'Social'];
    } else {
      tags = const ['Friendly', 'Energetic', 'Loyal'];
    }

    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: AppIconSizes.md,
                color: context.colorScheme.secondary,
              ),
              AppSpacing.hGapSm,
              Text(
                'Personality',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      tag,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Activity level card with a tertiary progress bar.
class _ActivityLevelCard extends StatelessWidget {
  const _ActivityLevelCard({this.pet});

  final Pet? pet;

  @override
  Widget build(BuildContext context) {
    final tertiary = context.colorScheme.tertiary;
    final isOptimal = pet?.healthStatus == 'optimal';
    final activityLevel = isOptimal ? 'High' : 'Moderate';
    final progress = isOptimal ? 0.85 : 0.60;

    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: AppIconSizes.md, color: tertiary),
                  AppSpacing.hGapSm,
                  Text(
                    'Activity Level',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ],
              ),
              Text(
                activityLevel,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: tertiary,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppSpacing.xs,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(tertiary),
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            progress >= 0.8
                ? 'Requires 2+ hours of exercise daily.'
                : 'Maintains healthy daily activity.',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timeline preview card (two-column span on desktop) displaying real health events.
class _TimelinePreviewCard extends ConsumerWidget {
  const _TimelinePreviewCard({this.petId});

  final String? petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final timelineAsync = petId != null
        ? ref.watch(healthTimelineEventsProvider(petId!))
        : const AsyncValue<List<HealthTimelineEvent>>.data([]);

    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline Preview',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push(RoutePaths.ownerHealthTimeline);
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          timelineAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Unable to load timeline events.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: AppIconSizes.md,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          'No health timeline events recorded yet.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final previewEvents = events.take(3).toList();
              return Column(
                children: [
                  for (final event in previewEvents)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: AppSpacing.xl,
                            height: AppSpacing.xl,
                            decoration: BoxDecoration(
                              color: _categoryBgColor(event.category, scheme),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _categoryIcon(event.category),
                              size: AppIconSizes.sm,
                              color: _categoryFgColor(event.category, scheme),
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                                if (event.description != null && event.description!.isNotEmpty)
                                  Text(
                                    event.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(event.eventDate),
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vaccination':
      case 'vaccine':
        return Icons.vaccines_rounded;
      case 'surgery':
      case 'procedure':
        return Icons.medical_services_rounded;
      case 'checkup':
      case 'exam':
        return Icons.health_and_safety_rounded;
      case 'medication':
      case 'prescription':
        return Icons.medication_rounded;
      case 'diet':
      case 'food':
      case 'nutrition':
        return Icons.restaurant_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  static Color _categoryBgColor(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case 'vaccination':
      case 'vaccine':
        return scheme.primaryContainer;
      case 'surgery':
      case 'procedure':
        return scheme.errorContainer;
      case 'medication':
        return scheme.tertiaryContainer;
      default:
        return scheme.secondaryContainer;
    }
  }

  static Color _categoryFgColor(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case 'vaccination':
      case 'vaccine':
        return scheme.onPrimaryContainer;
      case 'surgery':
      case 'procedure':
        return scheme.onErrorContainer;
      case 'medication':
        return scheme.onTertiaryContainer;
      default:
        return scheme.onSecondaryContainer;
    }
  }
}

/// Placeholder shown while the hero photo streams in (or fails to load).
class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 320 : 256,
      color: context.colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.pets,
        size: AppIconSizes.xxl,
        color: context.colorScheme.primary.withValues(alpha: 0.35),
      ),
    );
  }
}
