import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/avatar/user_avatar.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../widgets/widgets.dart';

/// The Pet Owner **Home Dashboard** — the portal's landing screen.
///
/// A faithful Flutter rendering of the frozen Stitch "Home Dashboard - Pet
/// Owner" (Light master): a glass header, a hero pet card with a pet switcher
/// and health/collar status pills, an AI daily-insight card, a "Today's
/// Summary" stat grid, a quick-actions grid and an activity timeline. Chrome
/// (glass bottom nav + AI FAB) is supplied by [OwnerScaffold].
///
/// Layout is single-column on mobile/tablet and an 8/4 two-column split on
/// desktop (≥[AppBreakpoints.tablet]), mirroring the design's `lg:` grid. All
/// colors, spacing, radii, type and elevation come from the theme / design
/// tokens so one widget tree serves both Light and Dark.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedPetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final width = context.screenWidth;
    final isWide = AppBreakpoints.isDesktop(width);
    final margin = _horizontalMargin(width);

    final appBar = OwnerGlassAppBar(
      leading: OwnerAppBarBrand(title: 'Home', accent: palette.accent),
      actions: [
        OwnerAppBarAction(
          icon: Icons.search,
          tooltip: 'Search',
          onPressed: () => context.goNamed(RouteNames.ownerSearch),
        ),
        OwnerAppBarAction(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          showBadge: true,
          onPressed: () => context.goNamed(RouteNames.ownerNotifications),
        ),
        AppSpacing.hGapXs,
        _ProfileAvatarButton(
          imageUrl: _profilePhotoUrl,
          onTap: () => context.goNamed(RouteNames.ownerProfile),
        ),
      ],
    );

    // Clear the glass chrome: push content below the app bar (which extends
    // behind the status bar) and above the floating nav bar + AI FAB.
    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    return OwnerScaffold(
      currentTab: OwnerTab.home,
      appBar: appBar,
      body: SingleChildScrollView(
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
            child: isWide ? _buildWide(context) : _buildStacked(context),
          ),
        ),
      ),
    );
  }

  // ── Layouts ──────────────────────────────────────────────────────

  Widget _buildStacked(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPetCard(
          pets: _pets,
          selectedIndex: _selectedPetIndex,
          onSelect: _selectPet,
        ),
        AppSpacing.vGapLg,
        _AiInsightCard(onViewAnalysis: _openAiAssistant),
        AppSpacing.vGapLg,
        const _TodaySummary(),
        AppSpacing.vGapLg,
        _QuickActions(onAction: _onQuickAction),
        AppSpacing.vGapLg,
        const _TimelineCard(),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroPetCard(
                pets: _pets,
                selectedIndex: _selectedPetIndex,
                onSelect: _selectPet,
              ),
              AppSpacing.vGapLg,
              _AiInsightCard(onViewAnalysis: _openAiAssistant),
              AppSpacing.vGapLg,
              const _TodaySummary(),
            ],
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuickActions(onAction: _onQuickAction),
              AppSpacing.vGapLg,
              const _TimelineCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────

  void _selectPet(int index) => setState(() => _selectedPetIndex = index);

  void _openAiAssistant() => context.goNamed(RouteNames.ownerAiAssistant);

  void _onQuickAction(_QuickActionSpec spec) {
    final routeName = spec.routeName;
    if (routeName != null) {
      context.goNamed(routeName);
    } else {
      context.showSnackbar('${spec.label} is coming soon.');
    }
  }

  double _horizontalMargin(double width) {
    if (AppBreakpoints.isMobile(width)) return AppSpacing.marginMobile;
    if (AppBreakpoints.isTablet(width)) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

// ═══════════════════════════════════════════════════════════════════
// Hero Pet Card
// ═══════════════════════════════════════════════════════════════════

class _HeroPetCard extends StatelessWidget {
  const _HeroPetCard({
    required this.pets,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_DashboardPet> pets;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final pet = pets[selectedIndex];
    final isRow = context.screenWidth >= AppBreakpoints.mobile;
    final avatarSize = isRow ? 192.0 : 128.0;

    final avatar = _HeroPetImage(imageUrl: pet.photoUrl, size: avatarSize);
    final info = _HeroPetInfo(pet: pet, centered: !isRow);

    return GlassCard(
      padding: AppSpacing.cardPaddingPremium,
      borderRadius: AppRadius.brSection,
      child: Stack(
        children: [
          // Subtle brand wash (design: from-primary/5 to-transparent).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.05),
                    scheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PetSwitcher(
                pets: pets,
                selectedIndex: selectedIndex,
                onSelect: onSelect,
              ),
              AppSpacing.vGapMd,
              if (isRow)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    AppSpacing.hGapLg,
                    Expanded(child: info),
                  ],
                )
              else
                Column(children: [avatar, AppSpacing.vGapLg, info]),
            ],
          ),
        ],
      ),
    );
  }
}

/// The circular hero pet photo with a light rim and an emerald "verified" badge.
class _HeroPetImage extends StatelessWidget {
  const _HeroPetImage({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 4),
            boxShadow: AppElevation.soft(context.theme.brightness),
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: scheme.secondaryContainer,
                child: Icon(
                  Icons.pets_rounded,
                  size: size * 0.4,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base + 2),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
              boxShadow: AppElevation.soft(context.theme.brightness),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: AppIconSizes.xs,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPetInfo extends StatelessWidget {
  const _HeroPetInfo({required this.pet, required this.centered});

  final _DashboardPet pet;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          pet.name,
          textAlign: textAlign,
          style: context.textTheme.displaySmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          pet.breedLine,
          textAlign: textAlign,
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.vGapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: const [
            _StatusPill(icon: Icons.favorite, label: 'Health: Optimal'),
            _StatusPill(icon: Icons.wifi, label: 'Collar: Active'),
          ],
        ),
      ],
    );
  }
}

/// A soft emerald "container" status pill (health / collar).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final container = palette.accentContainer(brightness);
    final onContainer = palette.onAccentContainer(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: container,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: palette.accent.withValues(alpha: 0.20)),
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

/// The Buddy/Luna pet switcher pill row.
class _PetSwitcher extends StatelessWidget {
  const _PetSwitcher({
    required this.pets,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_DashboardPet> pets;
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

  final _DashboardPet pet;
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
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PetChipAvatar(imageUrl: pet.avatarUrl, dimmed: !isActive),
              AppSpacing.hGapXs,
              Text(
                pet.name,
                style: context.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetChipAvatar extends StatelessWidget {
  const _PetChipAvatar({required this.imageUrl, required this.dimmed});

  final String imageUrl;
  final bool dimmed;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Opacity(
      opacity: dimmed ? 0.7 : 1,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: _size,
            height: _size,
            color: scheme.secondaryContainer,
            child: Icon(
              Icons.pets_rounded,
              size: _size * 0.55,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AI Insight Card
// ═══════════════════════════════════════════════════════════════════

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.onViewAnalysis});

  final VoidCallback onViewAnalysis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;
    final isRow = context.screenWidth >= AppBreakpoints.mobile;

    final iconBadge = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy,
        color: scheme.primary,
        size: AppIconSizes.md,
      ),
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Daily Insight',
          style: context.textTheme.labelLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapXs,
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Activity levels are optimal. New Article: ',
              ),
              TextSpan(
                text: 'Mastering Recall',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text:
                    ' from the Knowledge Hub might help with your evening '
                    'walks.',
              ),
            ],
          ),
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final action = TextButton(
      onPressed: onViewAnalysis,
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
      ),
      child: Text(
        'View Analysis',
        style: context.textTheme.labelLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final content = isRow
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconBadge,
              AppSpacing.hGapMd,
              Expanded(child: textBlock),
              AppSpacing.hGapMd,
              action,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBadge,
              AppSpacing.vGapMd,
              textBlock,
              AppSpacing.vGapXs,
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );

    return ClipRRect(
      borderRadius: AppRadius.brSection,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.brSection,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.20),
          ),
          boxShadow: AppElevation.soft(context.theme.brightness),
        ),
        child: Stack(
          children: [
            // Left accent stripe (design: gradient primary → secondary).
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: AppSpacing.base,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                ),
              ),
            ),
            Padding(padding: AppSpacing.cardPadding, child: content),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Today's Summary
// ═══════════════════════════════════════════════════════════════════

class _TodaySummary extends StatelessWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;
    final isRow = context.screenWidth >= AppBreakpoints.mobile;

    final activity = _StatCard(
      icon: Icons.directions_run,
      accent: scheme.primary,
      label: 'Activity',
      value: '4,230',
      sub: 'Steps today',
    );
    final collar = _StatCard(
      icon: Icons.battery_full,
      accent: accent,
      label: 'Collar',
      value: '84%',
      sub: 'Battery Level',
    );
    final nextAppt = _StatCard(
      icon: Icons.calendar_month,
      accent: scheme.secondary,
      label: 'Next Appt',
      value: 'Tomorrow\n10:00 AM',
      sub: 'Dr. Smith (Checkup)',
      compactValue: true,
    );

    if (isRow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: activity),
          AppSpacing.hGapMd,
          Expanded(child: collar),
          AppSpacing.hGapMd,
          Expanded(child: nextAppt),
        ],
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
              Expanded(child: collar),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        nextAppt,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.sub,
    this.compactValue = false,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String sub;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return GlassCard(
      padding: AppSpacing.cardPadding,
      borderRadius: AppRadius.brCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: AppIconSizes.md),
              AppSpacing.hGapXs,
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            value,
            style:
                (compactValue
                        ? context.textTheme.titleLarge
                        : context.textTheme.headlineMedium)
                    ?.copyWith(color: scheme.onSurface),
          ),
          AppSpacing.vGapXs,
          Text(
            sub,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Actions
// ═══════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAction});

  final ValueChanged<_QuickActionSpec> onAction;

  static const List<_QuickActionSpec> _specs = [
    _QuickActionSpec(
      icon: Icons.monitor_heart_outlined,
      label: 'Health',
      routeName: RouteNames.ownerHealth,
    ),
    _QuickActionSpec(
      icon: Icons.settings_input_antenna,
      label: 'Collar',
      routeName: RouteNames.ownerCollar,
    ),
    _QuickActionSpec(icon: Icons.event, label: 'Appts'),
    _QuickActionSpec(
      icon: Icons.campaign,
      label: 'Lost',
      routeName: RouteNames.ownerLostMode,
      isDanger: true,
    ),
    _QuickActionSpec(icon: Icons.volunteer_activism, label: 'Rescue'),
    _QuickActionSpec(
      icon: Icons.groups,
      label: 'Community',
      routeName: RouteNames.ownerCommunity,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapMd,
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final spec in _specs)
              _QuickActionTile(spec: spec, onTap: () => onAction(spec)),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.spec, required this.onTap});

  final _QuickActionSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final danger = spec.isDanger;

    final tileColor = danger
        ? scheme.errorContainer.withValues(alpha: 0.30)
        : scheme.surface;
    final borderColor = danger
        ? scheme.error.withValues(alpha: 0.10)
        : scheme.outlineVariant.withValues(alpha: 0.10);
    final iconBg = danger
        ? scheme.errorContainer
        : scheme.primaryContainer.withValues(alpha: 0.20);
    final iconColor = danger ? scheme.error : scheme.primary;

    return _SoftCard(
      color: tileColor,
      borderRadius: AppRadius.brCard,
      border: Border.all(color: borderColor),
      onTap: onTap,
      padding: AppSpacing.cardPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(spec.icon, color: iconColor, size: AppIconSizes.md),
          ),
          AppSpacing.vGapXs,
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation spec for a quick-action tile. A null [routeName] means the
/// destination isn't built yet (the tile shows a "coming soon" hint).
class _QuickActionSpec {
  const _QuickActionSpec({
    required this.icon,
    required this.label,
    this.routeName,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final String? routeName;
  final bool isDanger;
}

// ═══════════════════════════════════════════════════════════════════
// Timeline
// ═══════════════════════════════════════════════════════════════════

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    const events = <_TimelineEvent>[
      _TimelineEvent(
        time: 'Just now',
        text: "Sarah replied to your post in 'Training Tips'.",
        style: _TimelineDotStyle.accentFilled,
      ),
      _TimelineEvent(
        time: 'Today, 9:30 AM',
        text: 'New Event: Puppy Meetup nearby at Central Park.',
        style: _TimelineDotStyle.accentOutlined,
      ),
      _TimelineEvent(
        time: 'Yesterday',
        text: 'Collar Alert: Geofence exit detected.',
        style: _TimelineDotStyle.primaryOutlined,
      ),
    ];

    return GlassCard(
      padding: AppSpacing.cardPadding,
      borderRadius: AppRadius.brCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: context.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
                child: Text(
                  'View All',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          for (var i = 0; i < events.length; i++)
            _TimelineTile(event: events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final _TimelineEvent event;
  final bool isLast;

  static const double _railWidth = 20;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                _TimelineDot(style: event.style),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.40),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.time,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    event.text,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.style});

  final _TimelineDotStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;

    late final Color fill;
    late final Border? border;
    switch (style) {
      case _TimelineDotStyle.accentFilled:
        fill = accent;
        border = null;
      case _TimelineDotStyle.accentOutlined:
        fill = scheme.surface;
        border = Border.all(color: accent, width: 2);
      case _TimelineDotStyle.primaryOutlined:
        fill = scheme.surface;
        border = Border.all(color: scheme.primary, width: 2);
    }

    // Surface "ring" hides the rail behind the dot (design: ring-4 ring-surface).
    return Container(
      width: AppSpacing.md + AppSpacing.base,
      height: AppSpacing.md + AppSpacing.base,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
      child: Container(
        width: AppSpacing.sm,
        height: AppSpacing.sm,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: border,
        ),
      ),
    );
  }
}

enum _TimelineDotStyle { accentFilled, accentOutlined, primaryOutlined }

class _TimelineEvent {
  const _TimelineEvent({
    required this.time,
    required this.text,
    required this.style,
  });

  final String time;
  final String text;
  final _TimelineDotStyle style;
}

// ═══════════════════════════════════════════════════════════════════
// Shared building blocks
// ═══════════════════════════════════════════════════════════════════

/// A solid surface card with the design's soft ambient shadow, matching the
/// non-glass cards in the frozen design. Supports an optional ripple.
class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.borderRadius,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppElevation.soft(context.theme.brightness),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? scheme.surface,
            borderRadius: borderRadius,
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// The header profile avatar; taps through to the Profile tab.
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: UserAvatar(imageUrl: imageUrl, size: 32),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Presentation mock data
// ═══════════════════════════════════════════════════════════════════

/// A pet shown in the dashboard hero / switcher. Presentation-only mock data
/// until the Pets domain layer is wired; images fall back gracefully.
class _DashboardPet {
  const _DashboardPet({
    required this.name,
    required this.breedLine,
    required this.photoUrl,
    required this.avatarUrl,
  });

  final String name;
  final String breedLine;
  final String photoUrl;
  final String avatarUrl;
}

const List<_DashboardPet> _pets = [
  _DashboardPet(
    name: 'Buddy',
    breedLine: 'Golden Retriever • 3 yrs • 65 lbs',
    photoUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDfrXGD0EoeCCB7VS2psOCoRYSgCVhYaZnY_XlG6esRWte5IFtb354CMrjUcIe1oUV42cyFjOxmBvCDiPXNvHCPt3VNbwkXMfm4FPgYENQ7RIPULzR9kmmTUELypw_ZPWHL0K0btGhj_OIQLqi7syE8agWmpY1JMjr1Xmlc5PA8xtkVWmDVxiMCJfFsY99f51uslB42AApx2sSrE0JvpgSkpITwxw8S3rwtoMJRYHlCvJaxS03vi-OypA',
    avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDAxfTvenWKVtwB-grFwZuhHc5SFWE9GAkouJdryUqMJkXF7oUoBAgsf1G71O2gXLSpxiw6zhsGL3T-9qrsYhL-YdgFRxGcpjlTLAtWVtOqiQgpuXuVnReIx19qI7KLm1A6mY3EQOcTMcbIP4PsK2IxuiWGKotKvo7u3mvmWvFmlpfuxdsS_t08QRYzs_v_dTj61EhFGfM60uIgcSTis_8njKUj_M0YI7bjqqfCDJ6xBKqDwQnlCo62pw',
  ),
  _DashboardPet(
    name: 'Luna',
    breedLine: 'Siberian Husky • 2 yrs • 48 lbs',
    photoUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAOFzE_Yr2RpZ7ldqYMuEp1zCENf-Zy_0_nCgvJ6ITd6NexxVHz-43yhyAAgLJPOL9w_S1ZagXevsvwrnMU78nti_R0qzeq2O6aaGvc9k_t4KIr7t01labqUj08RQHUSPDnPGEx2U6EpU_2QB6b7QbRZewrVIlYG-HmEfG6TqojVhMF7IvHet2Q7FNN1kkpOwp69TSwRuAU--JZwR1Gc7-w3LR7eWU3w6kW6qV-gBBSEFGSI_aknbPyLw',
    avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAOFzE_Yr2RpZ7ldqYMuEp1zCENf-Zy_0_nCgvJ6ITd6NexxVHz-43yhyAAgLJPOL9w_S1ZagXevsvwrnMU78nti_R0qzeq2O6aaGvc9k_t4KIr7t01labqUj08RQHUSPDnPGEx2U6EpU_2QB6b7QbRZewrVIlYG-HmEfG6TqojVhMF7IvHet2Q7FNN1kkpOwp69TSwRuAU--JZwR1Gc7-w3LR7eWU3w6kW6qV-gBBSEFGSI_aknbPyLw',
  ),
];

const String _profilePhotoUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB8VqkpoBF8x0U-dJo8SjDb197qdU4pbhLxXqAVEvB7Y-6pzwsMfaoVxFVZyl9NpBjYiHLYlcyN74xVI55W6HIM_jRujfnzsd2p-7Xqo15Zmhcqpri-wPdznzLMRoecD50z3iFKHIwPbuj2b_9P60eNY5U9D4sbCVXN9X1gqzEGiy6JlPuX7ziGiaLn7fEzqXix0nx9bbz0TODw0Vj3EnNaQ33fqpkz_n022V_AuKoQuyQMvw4iDeqsDA';
