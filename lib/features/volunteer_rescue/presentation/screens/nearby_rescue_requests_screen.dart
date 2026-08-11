import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Nearby Rescue Requests Screen (Stitch ID: `a82ba592880c4393b2e4b2104fffdc13`).
///
/// Emergency dispatch queue listing nearby rescue alerts. Includes urgency filters,
/// distance radius indicator, lost pet cards, and "Accept Mission" actions.
class NearbyRescueRequestsScreen extends StatefulWidget {
  const NearbyRescueRequestsScreen({super.key});

  @override
  State<NearbyRescueRequestsScreen> createState() =>
      _NearbyRescueRequestsScreenState();
}

class _NearbyRescueRequestsScreenState
    extends State<NearbyRescueRequestsScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'm1',
      'petName': 'Bella',
      'breed': 'Golden Retriever',
      'urgency': 'URGENT',
      'distance': '1.2km away',
      'lastSeen': '20 mins ago',
      'location': 'Pine St & 4th Ave',
      'details':
          'Lost near Pine St & 4th Ave. Very friendly but easily spooked by loud noises. Wearing a red collar.',
      'tag': 'Large Dog',
      'color': AppColors.warning,
    },
    {
      'id': 'm2',
      'petName': 'Mittens',
      'breed': 'Tuxedo Cat',
      'urgency': 'CRITICAL',
      'distance': '1.8km away',
      'lastSeen': '45 mins ago',
      'location': 'Market St Bridge',
      'details':
          'Reported trapped under bridge walkway. Rescue net & carrier required.',
      'tag': 'Cat',
      'color': AppColors.lightError,
    },
    {
      'id': 'm3',
      'petName': 'Rocky',
      'breed': 'French Bulldog',
      'urgency': 'MEDIUM',
      'distance': '3.1km away',
      'lastSeen': '1h ago',
      'location': 'Oak Park Gazebo',
      'details':
          'Spotted wandering in park area without owner. Has microchip tag.',
      'tag': 'Small Dog',
      'color': AppColors.info,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Rescue Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
            tooltip: 'Filter Radius',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Urgency Filter Bar ──────────────────────────────
                _buildFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Requests Header & Sort Indicator ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '12 Active Nearby Requests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Within 5km radius',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGapSm,

                // ── Emergency Pet Request Cards ─────────────────────
                ..._requests.map(
                  (req) => _buildRequestCard(context, theme, colorScheme, req),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final filters = ['All', 'Within 2km', 'Critical', 'Urgent'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: f,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFilter = f),
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              textColor: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> req,
  ) {
    final urgencyColor = req['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.pets, color: colorScheme.primary),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${req['petName']} (${req['breed']})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${req['distance']} • Last seen ${req['lastSeen']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: req['urgency'] as String,
                  backgroundColor: urgencyColor.withValues(alpha: 0.15),
                  textColor: urgencyColor,
                ),
              ],
            ),
            AppSpacing.vGapMd,
            Text(
              req['details'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppChip(
                  label: req['tag'] as String,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  textColor: colorScheme.onSurfaceVariant,
                ),
                AppButton(
                  text: 'Accept Mission',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Accepted mission for ${req['petName']}'),
                      ),
                    );
                    context.push('/rescue/missions/${req['id']}');
                  },
                  height: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
