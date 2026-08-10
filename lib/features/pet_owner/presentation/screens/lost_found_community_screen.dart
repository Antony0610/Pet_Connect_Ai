import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Lost & Found Community**
/// (Light Theme design authority, ID `cde2db7a`).
///
/// Enables local pet owners to view missing pet alerts, report found animals,
/// and review AI-driven physical match suggestions.
class LostFoundCommunityScreen extends StatefulWidget {
  const LostFoundCommunityScreen({super.key});

  @override
  State<LostFoundCommunityScreen> createState() =>
      _LostFoundCommunityScreenState();
}

class _LostFoundCommunityScreenState extends State<LostFoundCommunityScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTab = 'All Alerts';

  final List<String> _tabs = const ['All Alerts', 'Lost (3)', 'Found (1)'];

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
          'Lost & Found Hub',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Alert Map',
            onPressed: () =>
                context.goNamed(RouteNames.ownerCommunitySightings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Header CTA Bar ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppButton.filled(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report Found Pet form opening...'),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 18),
                            SizedBox(width: 6),
                            Text('Report Found Pet'),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    AppButton.outlined(
                      onPressed: () =>
                          context.goNamed(RouteNames.ownerCommunitySightings),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, size: 18),
                          SizedBox(width: 4),
                          Text('Active Map'),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── Filter Tabs ────────────────────────────────────
                Row(
                  children: _tabs.map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(tab),
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
                          if (selected) setState(() => _selectedTab = tab);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Match Suggestion Card ───────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'AI Match Suggestion',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          const AiConfidenceBadge(percentage: 85),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'A Found pet reported 1 hour ago matches "Barnaby\'s" physical description with 85% confidence.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      AppButton.filled(
                        onPressed: () {},
                        size: AppButtonSize.small,
                        child: const Text('Review Match'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Urgent Search Card ─────────────────────────────
                const SectionHeader(title: 'Urgent Lost Alerts'),
                AppSpacing.vGapSm,
                AppCard(
                  backgroundColor: scheme.errorContainer.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              Icons.campaign,
                              size: 14,
                              color: scheme.onErrorContainer,
                            ),
                            label: const Text('LOST TODAY'),
                            backgroundColor: scheme.errorContainer,
                            labelStyle: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: AppTypography.bold,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 18),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        '"Barnaby"',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        'Terrier Mix • Brown/White',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: scheme.error,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            'Last seen: Maple St. Park',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          AppButton.filled(
                            onPressed: () => context.goNamed(
                              RouteNames.ownerCommunitySightings,
                            ),
                            size: AppButtonSize.small,
                            child: const Text('Report Sighting'),
                          ),
                          AppSpacing.hGapSm,
                          AppButton.outlined(
                            onPressed: () => context.goNamed(
                              RouteNames.ownerCommunityMessages,
                            ),
                            size: AppButtonSize.small,
                            child: const Text('Contact Owner'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Recent Reports ─────────────────────────────────
                const SectionHeader(title: 'Recent Community Reports'),
                AppSpacing.vGapSm,
                AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(
                        Icons.pets,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text('Calico Cat (Found)'),
                    subtitle: const Text(
                      'Found near elementary school • 2 hrs ago',
                    ),
                    trailing: AppButton.outlined(
                      onPressed: () =>
                          context.goNamed(RouteNames.ownerCommunityMessages),
                      size: AppButtonSize.small,
                      child: const Text('Contact'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
