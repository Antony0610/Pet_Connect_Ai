import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
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
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

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
    final actions = [
      QuickActionItemSpec(
        title: 'Health\nPassport',
        icon: Icons.health_and_safety_rounded,
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () {
          if (pet != null) {
            context.push(RoutePaths.ownerHealth);
          }
        },
      ),
      QuickActionItemSpec(
        title: 'QR Pass\nModal',
        icon: Icons.qr_code_2_rounded,
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        onTap: () {
          if (pet != null) {
            PetEmergencyQrModal.show(context, pet!);
          }
        },
      ),
      QuickActionItemSpec(
        title: 'PDF Health\nExport',
        icon: Icons.picture_as_pdf_rounded,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
      QuickActionItemSpec(
        title: 'Smart\nCollar',
        icon: Icons.podcasts_rounded,
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(RoutePaths.ownerCollar),
      ),
      QuickActionItemSpec(
        title: 'Lost Mode\nSOS',
        icon: Icons.campaign_rounded,
        gradientColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        badgeText: 'SOS',
        isDanger: true,
        onTap: () => context.push(RoutePaths.ownerLostMode),
      ),
      QuickActionItemSpec(
        title: 'Photo\nGallery',
        icon: Icons.photo_library_rounded,
        gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions.map((act) => Expanded(
                child: QuickActionButton(
                  title: act.title,
                  icon: act.icon,
                  gradientColors: act.gradientColors,
                  badgeText: act.badgeText,
                  isDanger: act.isDanger,
                  onTap: act.onTap,
                ),
              )).toList(),
            )
          : Wrap(
              alignment: WrapAlignment.start,
              spacing: 6,
              runSpacing: 10,
              children: actions.map((act) {
                final width = (context.screenWidth - 56) / 3;
                return SizedBox(
                  width: width.clamp(80.0, 115.0),
                  child: QuickActionButton(
                    title: act.title,
                    icon: act.icon,
                    gradientColors: act.gradientColors,
                    badgeText: act.badgeText,
                    isDanger: act.isDanger,
                    onTap: act.onTap,
                  ),
                );
              }).toList(),
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

/// Dynamic Personality tags card with interactive trait selector.
class _PersonalityCard extends ConsumerStatefulWidget {
  const _PersonalityCard({this.pet});

  final Pet? pet;

  @override
  ConsumerState<_PersonalityCard> createState() => _PersonalityCardState();
}

class _PersonalityCardState extends ConsumerState<_PersonalityCard> {
  List<String> _traits = [];

  static const List<String> _availableTraits = [
    'Energetic',
    'Gentle',
    'Playful',
    'Loyal',
    'Affectionate',
    'Guard Dog',
    'Curious',
    'Calm',
    'Vocal',
    'Shy',
    'Kid Friendly',
    'Cuddly',
    'Highly Trained',
    'Foodie',
    'Independent',
  ];

  @override
  void initState() {
    super.initState();
    _loadTraits();
  }

  @override
  void didUpdateWidget(covariant _PersonalityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet?.id != widget.pet?.id) {
      _loadTraits();
    }
  }

  void _loadTraits() {
    final petId = widget.pet?.id;
    if (petId == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getStringList('pet_traits_$petId');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _traits = saved);
    } else {
      final species = (widget.pet?.species ?? 'dog').toLowerCase();
      if (species.contains('cat')) {
        setState(() => _traits = ['Calm', 'Independent', 'Playful']);
      } else if (species.contains('bird')) {
        setState(() => _traits = ['Curious', 'Vocal', 'Social']);
      } else {
        setState(() => _traits = ['Friendly', 'Energetic', 'Loyal']);
      }
    }
  }

  Future<void> _saveTraits(List<String> newTraits) async {
    final petId = widget.pet?.id;
    if (petId == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList('pet_traits_$petId', newTraits);
    setState(() => _traits = newTraits);
  }

  void _openTraitEditor() {
    HapticFeedback.lightImpact();
    final selected = Set<String>.from(_traits);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.pet?.name ?? "Pet"}\'s Personality',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
              Text(
                'Select traits that best describe your companion\'s behavior.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTraits.map((trait) {
                  final isChecked = selected.contains(trait);
                  return FilterChip(
                    label: Text(trait),
                    selected: isChecked,
                    selectedColor: context.colorScheme.primaryContainer,
                    checkmarkColor: context.colorScheme.onPrimaryContainer,
                    onSelected: (val) {
                      HapticFeedback.lightImpact();
                      setModalState(() {
                        if (val) {
                          selected.add(trait);
                        } else {
                          selected.remove(trait);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              AppSpacing.vGapLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Save Personality Traits'),
                  onPressed: () {
                    _saveTraits(selected.toList());
                    Navigator.pop(ctx);
                    context.showSnackbar('Personality traits updated!');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    Icons.psychology_rounded,
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
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                tooltip: 'Edit Personality Traits',
                color: context.colorScheme.primary,
                onPressed: _openTraitEditor,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in _traits)
                Container(
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
              InkWell(
                onTap: _openTraitEditor,
                borderRadius: BorderRadius.circular(AppRadius.brPill.topLeft.x),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: context.colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Add Trait',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dynamic Activity Level card backed by Smart Collar telemetry or manual walk tracker.
class _ActivityLevelCard extends ConsumerWidget {
  const _ActivityLevelCard({this.pet});

  final Pet? pet;

  void _openLogWalkDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    int loggedMinutes = 30;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Log Activity for ${pet?.name ?? "Pet"}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add walking or play duration today to update activity level:',
                style: ctx.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setDlgState(() => loggedMinutes = (loggedMinutes - 10).clamp(10, 180)),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$loggedMinutes mins',
                    style: ctx.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: () => setDlgState(() => loggedMinutes = (loggedMinutes + 10).clamp(10, 180)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final petId = pet?.id;
                if (petId != null) {
                  final prefs = ref.read(sharedPreferencesProvider);
                  final current = prefs.getInt('pet_activity_mins_$petId') ?? 0;
                  await prefs.setInt('pet_activity_mins_$petId', current + loggedMinutes);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  context.showSnackbar('Logged $loggedMinutes mins of exercise!');
                }
              },
              child: const Text('Save Log'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tertiary = context.colorScheme.tertiary;
    final petId = pet?.id;

    final collarsAsync = ref.watch(registeredCollarsProvider);
    final collars = collarsAsync.valueOrNull ?? [];
    final matchingCollars = collars.where((c) => c.petId == petId);
    final CollarDevice? collar = matchingCollars.isNotEmpty ? matchingCollars.first : null;

    int steps = 0;
    int activeMinutes = 0;

    if (collar != null) {
      final activitiesAsync = ref.watch(collarActivitySummariesProvider(collar.id));
      final today = DateTime.now();
      final activities = activitiesAsync.valueOrNull ?? [];
      final matches = activities.where(
        (s) => s.activityDate.year == today.year && s.activityDate.month == today.month && s.activityDate.day == today.day,
      );
      if (matches.isNotEmpty) {
        steps = matches.first.stepCount;
        activeMinutes = matches.first.activeMinutes;
      }
    } else if (petId != null) {
      final prefs = ref.watch(sharedPreferencesProvider);
      activeMinutes = prefs.getInt('pet_activity_mins_$petId') ?? 45;
      steps = (activeMinutes * 110);
    }

    const double targetSteps = 10000;
    final double progress = (steps / targetSteps).clamp(0.05, 1.0);
    final String activityLevel = progress >= 0.8
        ? 'High'
        : (progress >= 0.4 ? 'Moderate' : 'Low');

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
              Row(
                children: [
                  Text(
                    activityLevel,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (collar == null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      tooltip: 'Log Activity',
                      onPressed: () => _openLogWalkDialog(context, ref),
                    ),
                  ],
                ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$steps steps • ${activeMinutes}m active today',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% of goal',
                style: context.textTheme.labelSmall?.copyWith(
                  color: tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
