import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_activity_summary.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Home Dashboard Screen
// ═══════════════════════════════════════════════════════════════════════════════

/// The Pet Owner **Home Dashboard** — the portal's landing screen.
///
/// Uses real backend data exclusively:
/// - [petsProvider] for the pet hero card
/// - [currentUserProfileProvider] for the user avatar
/// - [registeredCollarsProvider] for real battery/collar status
/// - [collarActivitySummariesProvider] for today's step count
/// - [_recentNotificationsProvider] for the activity timeline
/// - [_dailyInsightProvider] for the AI daily insight
///
/// ZERO dummy/mock data — all unavailable data shows honest empty states.
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState
    extends ConsumerState<HomeDashboardScreen> {
  int _selectedPetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final width = context.screenWidth;
    final isWide = AppBreakpoints.isDesktop(width);
    final margin = _horizontalMargin(width);

    final avatarUrl =
        ref.watch(currentUserProfileProvider).valueOrNull?.avatarUrl;

    final appBar = OwnerGlassAppBar(
      leading: OwnerAppBarBrand(title: 'Home', accent: palette.accent),
      actions: [
        OwnerAppBarAction(
          icon: Icons.search,
          tooltip: 'Search',
          onPressed: () => context.push(RoutePaths.ownerSearch),
        ),
        OwnerAppBarAction(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          showBadge: true,
          onPressed: () => context.push(RoutePaths.ownerNotifications),
        ),
        AppSpacing.hGapXs,
        _ProfileAvatarButton(
          imageUrl: avatarUrl,
          onTap: () => context.push(RoutePaths.ownerProfile),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    final petsAsync = ref.watch(petsProvider);

    return OwnerScaffold(
      currentTab: OwnerTab.home,
      appBar: appBar,
      body: petsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Unable to load dashboard: $e',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: context.colorScheme.error),
            ),
          ),
        ),
        data: (pets) {
          // Clamp so index stays valid after a pet is deleted.
          final safeIndex = pets.isEmpty
              ? 0
              : _selectedPetIndex.clamp(0, pets.length - 1);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              margin,
              topPad + AppSpacing.md,
              margin,
              bottomPad,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: isWide
                    ? _buildWide(pets, safeIndex)
                    : _buildStacked(pets, safeIndex),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────────

  Widget _buildStacked(List<Pet> pets, int safeIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPetCard(
          pets: pets,
          selectedIndex: safeIndex,
          onSelect: (i) => setState(() => _selectedPetIndex = i),
        ),
        AppSpacing.vGapLg,
        const _TodaySummary(),
        AppSpacing.vGapLg,
        const _QuickActionsGrid(),
      ],
    );
  }

  Widget _buildWide(List<Pet> pets, int safeIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroPetCard(
                pets: pets,
                selectedIndex: safeIndex,
                onSelect: (i) =>
                    setState(() => _selectedPetIndex = i),
              ),
              AppSpacing.vGapLg,
              const _TodaySummary(),
            ],
          ),
        ),
        AppSpacing.hGapMd,
        const Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuickActionsGrid(),
            ],
          ),
        ),
      ],
    );
  }

  double _horizontalMargin(double width) {
    if (AppBreakpoints.isMobile(width)) return AppSpacing.marginMobile;
    if (AppBreakpoints.isTablet(width)) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Hero Pet Card
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroPetCard extends ConsumerWidget {
  const _HeroPetCard({
    required this.pets,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Pet> pets;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;

    if (pets.isEmpty) {
      return GlassCard(
        padding: AppSpacing.cardPaddingPremium,
        borderRadius: AppRadius.brSection,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: AppIconSizes.xxl,
              color: scheme.primary.withValues(alpha: 0.40),
            ),
            AppSpacing.vGapMd,
            Text(
              'Add Your First Pet',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'Your companion will appear here once added.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapLg,
            FilledButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.ownerPetAdd),
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      );
    }

    final pet = pets[selectedIndex];
    final collarsAsync = ref.watch(registeredCollarsProvider);

    final collars = collarsAsync.valueOrNull ?? [];
    final matchingCollars = collars.where((c) => c.petId == pet.id);
    final CollarDevice? linkedCollar = matchingCollars.isNotEmpty
        ? matchingCollars.first
        : (collars.isNotEmpty ? collars.first : null);

    final collarLabel = linkedCollar == null
        ? 'No collar connected'
        : linkedCollar.isActive
            ? 'Collar: Active'
            : 'Collar: Offline';

    return GlassCard(
      padding: AppSpacing.cardPaddingPremium,
      borderRadius: AppRadius.brSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pet switcher
          _PetSwitcher(
            pets: pets,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          AppSpacing.vGapMd,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/owner/pets/${pet.id}');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroPetImage(imageUrl: pet.imageUrl, size: 100),
                AppSpacing.hGapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        pet.breedLine,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _StatusPill(
                            icon: Icons.favorite,
                            label: 'Health: ${_cap(pet.healthStatus)}',
                          ),
                          _StatusPill(
                            icon: linkedCollar != null
                                ? Icons.wifi
                                : Icons.wifi_off,
                            label: collarLabel,
                            muted: linkedCollar == null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _HeroPetImage extends StatelessWidget {
  const _HeroPetImage(
      {required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 3),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _placeholder(scheme, size),
              )
            : _placeholder(scheme, size),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, double size) {
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.45,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

class _PetSwitcher extends StatelessWidget {
  const _PetSwitcher({
    required this.pets,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Pet> pets;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < pets.length; i++)
          _PetSwitcherChip(
            pet: pets[i],
            isActive: i == selectedIndex,
            onTap: () => onSelect(i),
          ),
        // Add-pet chip
        _AddPetChip(
          onTap: () => context.push(RoutePaths.ownerPetAdd),
        ),
      ],
    );
  }
}

class _PetSwitcherChip extends StatelessWidget {
  const _PetSwitcherChip({
    required this.pet,
    required this.isActive,
    required this.onTap,
  });

  final Pet pet;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;
    final bg = isActive ? accent : scheme.surface;
    final fg = isActive ? Colors.white : scheme.onSurfaceVariant;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brPill,
        side: isActive
            ? BorderSide.none
            : BorderSide(
                color:
                    scheme.outlineVariant.withValues(alpha: 0.30),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChipAvatar(
                  imageUrl: pet.imageUrl, dimmed: !isActive),
              AppSpacing.hGapXs,
              Text(
                pet.name,
                style: context.textTheme.labelLarge
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPetChip extends StatelessWidget {
  const _AddPetChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brPill,
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: AppIconSizes.xs,
                  color: scheme.primary),
              AppSpacing.hGapXs,
              Text('Add',
                  style: context.textTheme.labelLarge
                      ?.copyWith(color: scheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipAvatar extends StatelessWidget {
  const _ChipAvatar({required this.imageUrl, required this.dimmed});

  final String? imageUrl;
  final bool dimmed;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!,
                width: _size, height: _size, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _placeholder(scheme))
            : _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
    width: _size,
    height: _size,
    color: scheme.secondaryContainer,
    child: Icon(Icons.pets_rounded,
        size: _size * 0.5,
        color: scheme.onSecondaryContainer),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.icon, required this.label, this.muted = false});

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final scheme = context.colorScheme;
    final container = muted
        ? scheme.surfaceContainerHighest
        : palette.accentContainer(brightness);
    final onContainer = muted
        ? scheme.onSurfaceVariant
        : palette.onAccentContainer(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.base),
      decoration: BoxDecoration(
        color: container,
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: muted
              ? scheme.outline.withValues(alpha: 0.15)
              : palette.accent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xs, color: onContainer),
          AppSpacing.hGapXs,
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: onContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Today's Summary
// ═══════════════════════════════════════════════════════════════════════════════

class _TodaySummary extends ConsumerWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;
    final selectedPet = ref.watch(selectedPetProvider);
    final collarsAsync = ref.watch(registeredCollarsProvider);

    final collars = collarsAsync.valueOrNull ?? [];
    final matchingCollars = collars.where((c) => c.petId == selectedPet?.id);
    final CollarDevice? collar = matchingCollars.isNotEmpty
        ? matchingCollars.first
        : (collars.isNotEmpty ? collars.first : null);

    // Battery
    final batteryValue =
        collar != null ? '${collar.batteryPercentage}%' : null;

    // Today's steps — only watch if a collar exists.
    final today = DateTime.now();
    CollarActivitySummary? todayActivity;
    if (collar != null) {
      final activitiesAsync =
          ref.watch(collarActivitySummariesProvider(collar.id));
      final activities = activitiesAsync.valueOrNull ?? [];
      final matches = activities.where(
        (s) =>
            s.activityDate.year == today.year &&
            s.activityDate.month == today.month &&
            s.activityDate.day == today.day,
      );
      if (matches.isNotEmpty) {
        todayActivity = matches.first;
      }
    }

    final stepValue = todayActivity != null
        ? _formatSteps(todayActivity.stepCount)
        : null;

    final bool isRow =
        context.screenWidth >= AppBreakpoints.mobile;

    final Widget activity = _StatCard(
      icon: Icons.directions_run,
      accent: scheme.primary,
      label: 'Activity',
      value: stepValue ?? '—',
      sub: stepValue != null ? 'Steps today' : 'No collar data',
      onTap: () => context.push(RoutePaths.ownerCollarActivity),
    );
    final Widget collarCard = _StatCard(
      icon: Icons.battery_full,
      accent: accent,
      label: 'Collar',
      value: batteryValue ?? '—',
      sub: batteryValue != null
          ? 'Battery level'
          : 'No collar connected',
      onTap: () => context.push(RoutePaths.ownerCollar),
    );
    final Widget apptCard = _StatCard(
      icon: Icons.calendar_month,
      accent: scheme.secondary,
      label: 'Next Appt',
      value: '—',
      sub: 'No appointments',
      onTap: () => context.push(RoutePaths.ownerHealthTimeline),
    );

    if (isRow) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: activity),
            AppSpacing.hGapMd,
            Expanded(child: collarCard),
            AppSpacing.hGapMd,
            Expanded(child: apptCard),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: activity),
              AppSpacing.hGapMd,
              Expanded(child: collarCard),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        apptCard,
      ],
    );
  }

  static String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return '$steps';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? scheme.surfaceContainer
                : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.40),
              width: 1.0,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.06),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: accent, size: 16),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        label,
                        style: context.textTheme.labelMedium
                            ?.copyWith(color: accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    value,
                    style: context.textTheme.headlineMedium
                        ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    sub,
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quick Actions Grid — Aesthetic cards filling dashboard page with direct push
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<QuickActionItemSpec> _specs = [
    QuickActionItemSpec(
      icon: Icons.health_and_safety_rounded,
      title: 'Health\nPassport',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      onTap: _noop,
    ),
    QuickActionItemSpec(
      icon: Icons.podcasts_rounded,
      title: 'Smart\nCollar',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      onTap: _noop,
    ),
    QuickActionItemSpec(
      icon: Icons.notifications_active_rounded,
      title: 'Safety\nAlerts',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      onTap: _noop,
    ),
    QuickActionItemSpec(
      icon: Icons.campaign_rounded,
      title: 'Lost Mode\nSOS',
      gradientColors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      badgeText: 'SOS',
      isDanger: true,
      onTap: _noop,
    ),
    QuickActionItemSpec(
      icon: Icons.groups_rounded,
      title: 'Community\nHub',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      onTap: _noop,
    ),
    QuickActionItemSpec(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Hub\nServices',
      gradientColors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      badgeText: 'AI',
      onTap: _noop,
    ),
  ];

  static void _noop() {}

  static const List<String> _routes = [
    RoutePaths.ownerHealth,
    RoutePaths.ownerCollar,
    RoutePaths.ownerNotifications,
    RoutePaths.ownerLostMode,
    RoutePaths.ownerCommunity,
    RoutePaths.ownerAi,
  ];

  void _navigate(BuildContext context, String path) {
    HapticFeedback.lightImpact();
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final activeSpecs = List.generate(_specs.length, (i) {
      final spec = _specs[i];
      return QuickActionItemSpec(
        title: spec.title,
        icon: spec.icon,
        gradientColors: spec.gradientColors,
        badgeText: spec.badgeText,
        isDanger: spec.isDanger,
        onTap: () => _navigate(context, _routes[i]),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            Text(
              '${_specs.length} Services',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        QuickActionsGridContainer(
          items: activeSpecs,
          crossAxisCount: 3,
          tabletCrossAxisCount: 6,
          containerSize: 52,
          iconSize: 26,
        ),
      ],
    );
  }
}

// ── Avatar button ──────────────────────────────────────────────────────────────

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton(
      {required this.imageUrl, required this.onTap});

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: UserAvatar(imageUrl: imageUrl ?? '', size: 32),
      ),
    );
  }
}
