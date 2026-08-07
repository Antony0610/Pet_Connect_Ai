import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/avatar/user_avatar.dart';
import '../widgets/widgets.dart';

/// The Pet Owner **My Pets** list — the portal's pet roster.
///
/// A faithful Flutter rendering of the frozen Stitch "My Pets List" (Light
/// master): a glass header (profile avatar + primary "My Pets" wordmark + AI
/// button), a "Your Companions" section intro and a responsive grid of pet
/// cards. Each card shows a cover photo topped by a glass health badge, the
/// pet's name and breed, an overflow menu and a pair of status chips. Chrome
/// (glass bottom nav + the "Add Pet" FAB) is supplied by [OwnerScaffold].
///
/// The grid is 1 / 2 / 3 columns across the design's `md:`/`lg:` breakpoints.
/// All colors, spacing, radii, type and elevation come from the theme / design
/// tokens so one widget tree serves both Light and Dark.
class MyPetsListScreen extends StatelessWidget {
  const MyPetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final isWide = width >= _twoColumnWidth;
    final margin = _horizontalMargin(width);

    final appBar = OwnerGlassAppBar(
      leading: _HeaderAvatar(
        imageUrl: _profilePhotoUrl,
        onTap: () => context.goNamed(RouteNames.ownerProfile),
      ),
      title: Text(
        'My Pets',
        style: context.textTheme.headlineMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          color: scheme.primary,
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    // Clear the glass chrome: below the app bar (which extends behind the
    // status bar) and above the floating nav bar + FAB.
    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    return OwnerScaffold(
      currentTab: OwnerTab.pets,
      appBar: appBar,
      floatingActionButton: OwnerActionFab(
        icon: Icons.add,
        tooltip: 'Add Pet',
        onPressed: () => context.showSnackbar('Add Pet is coming soon.'),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionIntro(isWide: isWide),
                AppSpacing.vGapLg,
                _PetGrid(
                  pets: _pets,
                  onOpen: (pet) => context.goNamed(
                    RouteNames.ownerPetDetail,
                    pathParameters: {'petId': pet.id},
                  ),
                  onMore: (pet) =>
                      context.showSnackbar('${pet.name} options coming soon.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalMargin(double width) {
    if (AppBreakpoints.isMobile(width)) return AppSpacing.marginMobile;
    if (AppBreakpoints.isTablet(width)) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

// ═══════════════════════════════════════════════════════════════════
// Section intro
// ═══════════════════════════════════════════════════════════════════

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final headingStyle =
        (isWide ? context.textTheme.displayMedium : context.textTheme.headlineLarge)
            ?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Companions', style: headingStyle),
        AppSpacing.vGapXs,
        Text(
          'Manage profiles, health tracking, and smart collar alerts.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Responsive pet grid
// ═══════════════════════════════════════════════════════════════════

/// Two-column layout kicks in at the design's `md:` breakpoint (768px)…
const double _twoColumnWidth = 768;

/// …and three columns at the design's `lg:` breakpoint (1024px).
const double _threeColumnWidth = 1024;

class _PetGrid extends StatelessWidget {
  const _PetGrid({
    required this.pets,
    required this.onOpen,
    required this.onMore,
  });

  final List<_OwnerPet> pets;
  final ValueChanged<_OwnerPet> onOpen;
  final ValueChanged<_OwnerPet> onMore;

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final columns = width >= _threeColumnWidth
        ? 3
        : width >= _twoColumnWidth
            ? 2
            : 1;
    // gap-md on mobile, md:gap-lg at ≥768px.
    final gap = width >= _twoColumnWidth ? AppSpacing.lg : AppSpacing.md;

    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < pets.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            _PetCard(
              pet: pets[i],
              onTap: () => onOpen(pets[i]),
              onMore: () => onMore(pets[i]),
            ),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var start = 0; start < pets.length; start += columns) {
      final rowChildren = <Widget>[];
      for (var col = 0; col < columns; col++) {
        final index = start + col;
        if (col > 0) rowChildren.add(SizedBox(width: gap));
        rowChildren.add(
          Expanded(
            child: index < pets.length
                ? _PetCard(
                    pet: pets[index],
                    onTap: () => onOpen(pets[index]),
                    onMore: () => onMore(pets[index]),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Pet card
// ═══════════════════════════════════════════════════════════════════

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.onTap,
    required this.onMore,
  });

  final _OwnerPet pet;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brSection,
        boxShadow: AppElevation.shadowSoft,
      ),
      child: Material(
        color: scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brSection,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.20)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PetCardImage(imageUrl: pet.imageUrl, health: pet.health),
              Padding(
                padding: AppSpacing.cardPaddingPremium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PetCardHeader(pet: pet, onMore: onMore),
                    AppSpacing.vGapLg,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _PetStatChip(stat: pet.primaryStat)),
                        AppSpacing.hGapSm,
                        Expanded(child: _PetStatChip(stat: pet.secondaryStat)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 280px cover photo with a floating glass health badge.
class _PetCardImage extends StatelessWidget {
  const _PetCardImage({required this.imageUrl, required this.health});

  final String imageUrl;
  final _PetHealth health;

  static const double _height = 280;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: scheme.secondaryContainer,
                child: Icon(
                  Icons.pets_rounded,
                  size: AppIconSizes.xxl,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: _HealthBadge(health: health),
          ),
        ],
      ),
    );
  }
}

/// The translucent "Optimal" / "Needs Review" pill over the photo.
class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.health});

  final _PetHealth health;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = health.color(scheme);

    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.90),
          borderRadius: AppRadius.brPill,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.10),
          ),
          boxShadow: AppElevation.shadowSoft,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: AppIconSizes.xs, color: color),
              AppSpacing.hGapXs,
              Text(
                health.label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: color,
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

/// Name + breed line with the trailing overflow-menu button.
class _PetCardHeader extends StatelessWidget {
  const _PetCardHeader({required this.pet, required this.onMore});

  final _OwnerPet pet;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.name,
                style: context.textTheme.displaySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vGapXs,
              Text(
                pet.breedLine,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        _MoreButton(onTap: onMore),
      ],
    );
  }
}

/// A 40px circular outlined overflow-menu button.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: _size,
      height: _size,
      child: Material(
        type: MaterialType.transparency,
        shape: CircleBorder(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.50)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(
            Icons.more_vert,
            size: AppIconSizes.md,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A collar / activity status chip. Highlighted chips use the secondary
/// container tint; muted chips use the neutral surface container.
class _PetStatChip extends StatelessWidget {
  const _PetStatChip({required this.stat});

  final _PetStat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final Color background;
    final Color border;
    final Color foreground;
    if (stat.highlighted) {
      background = scheme.secondaryContainer.withValues(alpha: 0.50);
      border = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    } else {
      background = scheme.surfaceContainer;
      border = scheme.outlineVariant.withValues(alpha: 0.30);
      foreground = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: AppIconSizes.sm, color: foreground),
          AppSpacing.hGapXs,
          Flexible(
            child: Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The header profile avatar; taps through to the Profile tab.
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
        child: UserAvatar(imageUrl: imageUrl, size: _size),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Presentation mock data
// ═══════════════════════════════════════════════════════════════════

/// A pet's overall health state, shown as a badge over the photo.
enum _PetHealth {
  optimal('Optimal'),
  needsReview('Needs Review');

  const _PetHealth(this.label);

  final String label;

  /// The badge tint — `primary` for optimal, `tertiary` for review.
  Color color(ColorScheme scheme) =>
      this == _PetHealth.optimal ? scheme.primary : scheme.tertiary;
}

/// A single collar / activity status chip on a pet card.
class _PetStat {
  const _PetStat({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
}

/// A pet shown in the My Pets grid. Presentation-only mock data until the
/// Pets domain layer is wired; images fall back gracefully.
class _OwnerPet {
  const _OwnerPet({
    required this.id,
    required this.name,
    required this.breedLine,
    required this.imageUrl,
    required this.health,
    required this.primaryStat,
    required this.secondaryStat,
  });

  final String id;
  final String name;
  final String breedLine;
  final String imageUrl;
  final _PetHealth health;
  final _PetStat primaryStat;
  final _PetStat secondaryStat;
}

const List<_OwnerPet> _pets = [
  _OwnerPet(
    id: 'luna',
    name: 'Luna',
    breedLine: 'Siberian Husky • 3 years',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCiHWTij2HHJqqqGBMtljXopq2ktMlYGW79e4xjex8vCnvfNCk1jpnwMQyomaZ1WgxlF7UBLG-NMw3gM3I3IYUcjcawI76svTBjdVNbu83bxJzBuDq9PSc6pxa3gybdX0kJYkLLnMzL4PVYaNHq01EiH79sy5rNWj2EMnBd5hcCdy-R29_O_ltaapX7xJHDZwqIF1-5rGNszJiqPj7xQx8Au53vGWpgiTu2unhxOYlCrQsqscbl2fsS0A',
    health: _PetHealth.optimal,
    primaryStat: _PetStat(
      icon: Icons.location_on,
      label: 'Collar Online',
      highlighted: true,
    ),
    secondaryStat: _PetStat(
      icon: Icons.directions_walk,
      label: 'Activity Normal',
    ),
  ),
  _OwnerPet(
    id: 'oliver',
    name: 'Oliver',
    breedLine: 'Maine Coon • 5 years',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBAofv0tT8LexPb9Pp8bwTKft13fdhq6ZIsMJHa-R2Bg73z1Sz5OwFQ3JWvnvfojQX26ywI3uN6ELym3cJfWA7a6hAT0rFq3N8Rfv1Xp8F6eTypQuGDp1SM-tN8kIYE4JCEn3CCGBbZqgLhkraT77cd2UAA3ZVO3u9JHIL8auNZMW4MAmH07aulJWQAYP8mtD1RGLi0NGv0bE-7ockYwJun5oI3PztUMoYihVPWsIKGT2bLChIBsrxakA',
    health: _PetHealth.needsReview,
    primaryStat: _PetStat(
      icon: Icons.location_off,
      label: 'Collar Offline',
    ),
    secondaryStat: _PetStat(
      icon: Icons.restaurant,
      label: 'Diet Plan Active',
    ),
  ),
];

const String _profilePhotoUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAqXs9-8o_9UQdDqaW523Fjes2TWHU1jYiexscUhhcNCt9nhCbSOe74Lr1yDs1eMgbNvubeMc8G4X1a9-_BlwpcCzoly3EXq-FlpVJfRCnBl7mHxF4USx8gMVSepoj8l3lfdWv4LQEKV_SmabegHDCttbhZeYICPPn2rRtO9uBBlwQY_iVUM8SdwP7XiMqkywiUhymEwgywjpfgP0lTsuj1EXnvtVcyvHPIbdWlovogNtLc2te7rqSHmA';
