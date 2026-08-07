import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../widgets/widgets.dart';

/// The Pet Owner **Pet Media Gallery** screen.
///
/// A faithful Flutter rendering of the frozen Stitch "Pet Gallery" (Light
/// master): a glass header, a Grid / Timeline view toggle, a horizontal
/// "Featured Moments" carousel and a bento "All Photos" grid (mixing large,
/// standard, video and panoramic tiles). Every color, spacing, radius and
/// type comes from the theme / design tokens so one widget tree serves both
/// Light and Dark.
class PetMediaGalleryScreen extends StatefulWidget {
  const PetMediaGalleryScreen({super.key});

  @override
  State<PetMediaGalleryScreen> createState() => _PetMediaGalleryScreenState();
}

enum _GalleryView { grid, timeline }

class _PetMediaGalleryScreenState extends State<PetMediaGalleryScreen> {
  _GalleryView _view = _GalleryView.grid;

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD4c2_Eyxn1W2w0wYumuTsucRL2spHlmLqjxK2zOJe-gfj2N_9Neg00JYQ7OmrhYEdrwa8yRBbwnC8hpcvsFQpo7qDA6-mfKhbEnOTIXfYoWXNcB86RIAkZdUbQIfZuvOMvUvUPUsApmFCp3I-2fswOYehvZl7OViwwyBAk2x1q1c5ScOMwydNF0PeEUgXB1sOBd7Tvyl4jtJiMh-kBj7Qz1MBu6HwK85h3EMDdxLCHFnfpSza2Iika_A';

  static const List<_Moment> _moments = [
    _Moment(
      title: 'The Great Leap',
      date: 'Oct 12, 2023',
      icon: Icons.calendar_today,
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAUvxT7Y1p-rbxU4l25SLtWP3CNgcs0ro5RB93ZUtR3h7kYzI3moorx-DgjZ-R4I7tTncw8i3StSXph-06mCAh-cfkwbNipq51X-QhnPQt5NKlIpbyYVGa8j1482ehOej-Uw2VQGTC1tWH6A69ZrziZMX54PvKmjWXNpmM4ZS1VIheizgd4cEaoWgLz6LwETgiKKTyv1TTOFlgpC1-5VztyBZRZxCaoXWDG2VFMluxGjmh5UgmibdZNQg',
    ),
    _Moment(
      title: 'Nap Time Buddies',
      date: 'Sep 28, 2023',
      icon: Icons.favorite,
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDJ6MShsxBv8ytWA-QfSKJzgXa1bJIGQJN_dvGBd-eDKiwyooxg1WI3l7QtDRpN2OAAVhBYFOfGoYTAiwQE9ary9kwueV85pc0HLSMHDi_BPPuME1AQ1fX_MQmzGoBGRsiau9DazsXVDIwgqLFNW4vZkERwSPR5dB-FDp99F0saLAQi9ehhmn-VZWAj_d4Flw06mIPmgrYcGHCRnWg5B8pKRNQdPdMnq8lKUEfAfa24ibSGgpmLYugwOQ',
    ),
    _Moment(
      title: 'Lake Day Splash',
      date: 'Sep 15, 2023',
      icon: Icons.water_drop,
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCOR-wpKUbsL1n6p1-Wr7--ZBProIgrua2YbEJzrzHXkZMWq0Be1XfiTVeZr0coOf_ZtYa77Sc0v1t9AkLrXZloPq5KWYMDdRpLz3sd5px_yUwmEZxh8nELPfG5KqAp3djaCg92jmt04dNXt7v6necjdx-MNoTQv-xT64mOxNvrWvd6OFU5FmBAzH6SAldGYNbtGd83rzdb2ijeGgcfS84pH72yE-VsUlHVgH0sEzqg6voMS8kfPuPoBw',
    ),
  ];

  static const String _photoLarge =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC88AIA2j3Imx7K7RohO6sKbkCQvfcPZ5KuN7ETxkCKecmz-8ZRlVHr90uSC675ctb0wAzdkEqGZDEy4KjviHN7dS88YX6TKINQn8dvou5ocBOlBCu_oygHktxCjdY9TKDqlsp5EpZwe6SvpYUAPTrbM1c2Op1V0x1W-0ECFjOknVsmg1obvIkSUyNzAnT34KZynB7rSRGbp304fnJEXRi4PIqrx3SvA-N0HhNQUzeetu9ezilRJ_k_5g';
  static const String _photoA =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBqFYhoY1oM0t-tD_p8ybomOoqhsVgQPY6lY__qnqo57oUDKGlTtKT5UIHtn22qYkNMeih1CrtojrEAoN9M0QZXfPrTDnF96rOKzxkGe4oCJnI8UibCC65XE00DfcDOxArA5WYzwd6ZPezYn01jrvj6FKG9eqUNY4S6eQodBGt-WehH0rsHQpM-pHkgnObCCplhsrx8B0OhH3VLkj54cAiFjqvnEJCSWzl2Ty9t9HfpKf9UpnttuJlLUA';
  static const String _photoB =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAqNyvNSdOUZ7wm2w6ZUWTYnnMzi1uhTxUtHwHzfv9xnlrw1lLFPFgTUar7CGWUP2GtxilmzdBCANXUgDSKrsv_QAzKGi4CelQnwTJYG2rAM0zoAVjZhZZGcHm2A5AesSzUviTikx4X3pCFKUyJHHarqkIltTnIgpjbfu5fCw8C1zQcbbPhuoLzG6UETJ1DZxKvotnCwnQ15a08z1gWcAExp7IHnnyVDKpZlIW0IFpA5lke4wy_6j3Z1w';
  static const String _photoVideo =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAq1L0d_i7qMFaE8enCZC7Tw1sYWeG9-gNcbmagzkcn3X-HSbY6dHemFVWpfIh0h-nr-N1HaX1v94TPdvaJDKjYN3WCG2zrcbJbB2YhYomhS62kVAboMjOfZCfcTvzBEhbKzDMtcKFt1D17GGCTjk4mgLvv40IQyBRpNst8FcOvhjcvJc3DoYX6DOib-WUJYVN5fdbBbMtSUKgi_otz3eP1wm1BnC_2iZaHuK-iT8TrO_dbpQfqH_8AgQ';
  static const String _photoC =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCUgvVdi13CtZZe6mCPOXfZT4CAb2Rty10fjAe_oOZ7nnzG25wPHIMt1YlaNngLFJ3BN3FabOurR_RYJQ7oCPI9rKADWIu_6j-CfjVoUdoHas-rNZcXcvXOMfwok9Mnc5dLe8aJT9-g8i3ADvb_iEpix-FSlxXAss1IpxbUNJrDlc4v65Bu9Ior9z7WehvlXtD5wglFDnANYZ-XOFo8P9mO3yTRos-ZL-2Qf12E_aWFXvuKBC9CfRYvhA';
  static const String _photoBanner =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBc3zy77PxL_LSVb9uYafChDRo8ud8y8V3dDE_OJ7dZ0yiwaJp0fkIUolhFTtUxhQzlAlmTXOFuREi7dZHgZPTTDD6OqyNNaQWM12i6tugxs3tGYpwx-7a2m_XwgRHSXEd-56sknlcJPTqs8mR7OsBYn3Wr4LjgQ2vwqYZD2CqihgHVvpsDDMZ0WRonwZBPY6gGEer8xCZQKYQ3OJD6-fJden1MFmAHXNem5WBzv36Gw4LfsSxFADs2lQ';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: ClipOval(
        child: Image.network(
          _avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 40,
            height: 40,
            color: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.pets,
              size: AppIconSizes.sm,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(
        'PetConnect AI',
        style: text.headlineSmall?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
          letterSpacing: -0.25,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;

    return OwnerScaffold(
      currentTab: OwnerTab.pets,
      appBar: appBar,
      showAiFab: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: topPad + AppSpacing.sm),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title + view toggle ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gallery',
                        style: text.headlineMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      _ViewToggle(
                        value: _view,
                        onChanged: (v) => setState(() => _view = v),
                      ),
                    ],
                  ),
                  AppSpacing.vGapLg,

                  // ── Featured Moments ───────────────────────────────
                  Text(
                    'Featured Moments',
                    style: text.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapMd,
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _moments.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapSm,
                      itemBuilder: (context, i) =>
                          _MomentCard(moment: _moments[i]),
                    ),
                  ),
                  AppSpacing.vGapXl,

                  // ── All Photos ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Photos',
                        style: text.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(
                          Icons.filter_list,
                          size: AppIconSizes.sm,
                        ),
                        label: const Text('Filter'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.primary,
                          textStyle: text.labelLarge?.copyWith(
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,
                  const _BentoGrid(
                    large: _photoLarge,
                    a: _photoA,
                    b: _photoB,
                    video: _photoVideo,
                    c: _photoC,
                    banner: _photoBanner,
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

class _Moment {
  const _Moment({
    required this.title,
    required this.date,
    required this.icon,
    required this.url,
  });

  final String title;
  final String date;
  final IconData icon;
  final String url;
}

/// The Grid / Timeline pill segmented control.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final _GalleryView value;
  final ValueChanged<_GalleryView> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewChip(
            icon: Icons.grid_view,
            label: 'Grid',
            selected: value == _GalleryView.grid,
            onTap: () => onChanged(_GalleryView.grid),
          ),
          _ViewChip(
            icon: Icons.view_timeline,
            label: 'Timeline',
            selected: value == _GalleryView.timeline,
            onTap: () => onChanged(_GalleryView.timeline),
          ),
        ],
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.surface : Colors.transparent,
      borderRadius: AppRadius.brPill,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.base + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSizes.xs, color: fg),
              AppSpacing.hGapXs,
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A featured-moment carousel card: image, bottom gradient, date + title.
class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.moment});

  final _Moment moment;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final width = context.screenWidth >= AppBreakpoints.tablet ? 350.0 : 280.0;

    return SizedBox(
      width: width,
      child: _GalleryTile(
        url: moment.url,
        overlay: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(moment.icon, size: 14, color: Colors.white70),
                    AppSpacing.hGapXs,
                    Text(
                      moment.date,
                      style: text.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  moment.title,
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
        gradient: true,
      ),
    );
  }
}

/// The bento-style "All Photos" layout: a large tile, a 2×2 cluster of
/// standard tiles (one is a video), and a full-width panoramic banner.
class _BentoGrid extends StatelessWidget {
  const _BentoGrid({
    required this.large,
    required this.a,
    required this.b,
    required this.video,
    required this.c,
    required this.banner,
  });

  final String large;
  final String a;
  final String b;
  final String video;
  final String c;
  final String banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large tile (2×2).
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _GalleryTile(
                  url: large,
                  overlay: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: _GlassChip(icon: Icons.more_vert),
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.hGapSm,
            // 2×2 cluster.
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _SquareTile(url: a)),
                      AppSpacing.hGapSm,
                      Expanded(child: _SquareTile(url: b)),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Row(
                    children: [
                      Expanded(
                        child: _SquareTile(
                          url: video,
                          badge: const _VideoBadge(duration: '0:15'),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(child: _SquareTile(url: c)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        // Panoramic banner (2:1).
        AspectRatio(
          aspectRatio: 2 / 1,
          child: _GalleryTile(url: banner),
        ),
      ],
    );
  }
}

class _SquareTile extends StatelessWidget {
  const _SquareTile({required this.url, this.badge});

  final String url;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: _GalleryTile(
        url: url,
        overlay: badge == null
            ? null
            : Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: badge,
                ),
              ),
      ),
    );
  }
}

/// A rounded, bordered gallery image tile with an optional overlay + gradient.
class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.url,
    this.overlay,
    this.gradient = false,
  });

  final String url;
  final Widget? overlay;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.10),
          ),
          borderRadius: AppRadius.brCard,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  color: scheme.onSurfaceVariant,
                  size: AppIconSizes.lg,
                ),
              ),
            ),
            if (gradient)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface.withValues(alpha: 0.80),
      ),
      child: Icon(icon, size: AppIconSizes.sm, color: scheme.onSurface),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.base,
      ),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 14, color: Colors.white),
          AppSpacing.hGapXs,
          Text(
            duration,
            style: text.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
