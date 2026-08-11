import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Local Community** (Light
/// Theme design authority, ID `8bdfe144`).
///
/// Enables pet owners to view local activity feeds, explore pet-friendly spots,
/// view the verified local network directory, and receive AI local insights.
class LocalCommunityScreen extends StatefulWidget {
  const LocalCommunityScreen({super.key});

  @override
  State<LocalCommunityScreen> createState() => _LocalCommunityScreenState();
}

class _LocalCommunityScreenState extends State<LocalCommunityScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'All';

  final List<_LocalCategory> _categories = const [
    _LocalCategory('All', Icons.grid_view),
    _LocalCategory('Parks', Icons.park),
    _LocalCategory('Cafes', Icons.local_cafe),
    _LocalCategory('Alerts', Icons.campaign),
  ];

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
          'Local Community',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Current Location',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location set: San Francisco, CA'),
                ),
              );
            },
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Banner & Join Button ──────────────────────
                AppCard(
                  backgroundColor: scheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'San Francisco Bay Area',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            AppSpacing.vGapXs,
                            Text(
                              'Connect with 1,240 nearby pet owners & local spots.',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hGapMd,
                      AppButton.filled(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Joined local San Francisco group!',
                              ),
                            ),
                          );
                        },
                        size: AppButtonSize.small,
                        child: const Text('Join Group'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat.label;
                      return ChoiceChip(
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? scheme.onPrimary : scheme.primary,
                        ),
                        label: Text(cat.label),
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
                          if (selected)
                            setState(() => _selectedCategory = cat.label);
                        },
                      );
                    },
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Recent Activity Section ────────────────────────
                const SectionHeader(
                  title: 'Recent Activity',
                  actionLabel: 'View All',
                ),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: scheme.primary, size: 20),
                          AppSpacing.hGapSm,
                          Text(
                            'Weekend Pack Walk',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Join us for a 3-mile loop around Dolores Park this Saturday. All friendly dogs welcome!',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Row(
                        children: [
                          Text(
                            '2 hours ago • 12 attending',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('RSVP'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: scheme.primary,
                            size: 20,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'Lost Pet Alert Resolved',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Max the Golden Retriever has been found safe! Thanks to everyone who helped search.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        '5 hours ago',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Local Network Directory Section ────────────────
                const SectionHeader(
                  title: 'Local Network',
                  actionLabel: 'Browse Directory',
                ),
                AppSpacing.vGapSm,
                _buildNetworkTile(
                  context,
                  name: 'Dr. Sarah Jenkins',
                  subtitle: 'City Pet Hospital • 1.2 mi',
                  icon: Icons.local_hospital,
                  isVerified: true,
                ),
                AppSpacing.vGapXs,
                _buildNetworkTile(
                  context,
                  name: 'Marcus Chen',
                  subtitle: 'Rescue Transport • 2.5 mi',
                  icon: Icons.directions_car,
                  isVerified: false,
                ),
                AppSpacing.vGapXs,
                _buildNetworkTile(
                  context,
                  name: 'Elena Rodriguez',
                  subtitle: "Owner of 'Luna' • 0.8 mi",
                  icon: Icons.person,
                  isVerified: false,
                ),
                AppSpacing.vGapLg,

                // ── AI Community Insight Card ──────────────────────
                AiGradientBorderCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: scheme.primary,
                        size: AppIconSizes.md,
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          'Based on your activity, you might be interested in the "Weekend Agility Training" group meeting 1 mile away.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkTile(
    BuildContext context, {
    required String name,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: UserAvatar(name: name, radius: 20),
        title: Row(
          children: [
            Text(
              name,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            if (isVerified) ...[
              AppSpacing.hGapXs,
              Icon(Icons.verified, size: 16, color: scheme.primary),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () {},
      ),
    );
  }
}

class _LocalCategory {
  const _LocalCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
