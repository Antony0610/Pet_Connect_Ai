import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Community Moderation Screen (Stitch ID: `9fb93a733ef7471fa696c644563940f3`).
///
/// Flagged content review and moderation governance queue. Displays pending reported items,
/// severity filters, flagged content details, and moderation actions (Approve, Remove, Ban).
class AdminCommunityModerationScreen extends StatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  State<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends State<AdminCommunityModerationScreen> {
  String _selectedCategory = 'All Pending';

  final List<Map<String, dynamic>> _flaggedItems = [
    {
      'id': 'f1',
      'author': 'User #8492',
      'time': '12 mins ago',
      'reason': 'Potential Scam / Unauthorized Sales',
      'content':
          'Selling rare purebred puppies without license. Message for cash wire transfer...',
      'priority': 'HIGH URGENCY',
      'priorityColor': AppColors.lightError,
      'type': 'Post',
    },
    {
      'id': 'f2',
      'author': 'Commenter #2910',
      'time': '45 mins ago',
      'reason': 'Inappropriate Language / Harassment',
      'content':
          'Aggressive harassment comment targeting owner in Lost & Found section...',
      'priority': 'MEDIUM',
      'priorityColor': AppColors.warning,
      'type': 'Comment',
    },
    {
      'id': 'f3',
      'author': 'User #1048',
      'time': '2 hours ago',
      'reason': 'Duplicate Sighting Spam',
      'content':
          'Repeated identical lost pet posts across 15 different local feeds...',
      'priority': 'LOW',
      'priorityColor': AppColors.info,
      'type': 'Post',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Queue Header Banner ──────────────────────────────
                _buildModerationHeaderBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Category Filters ────────────────────────────────
                _buildCategoryFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Flagged Content Cards ────────────────────────────
                ..._flaggedItems.map(
                  (item) =>
                      _buildFlaggedCard(context, theme, colorScheme, item),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModerationHeaderBanner(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.gavel, color: colorScheme.primary),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Moderation Queue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  '42 items pending review • AI Safety Filter Active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const AppChip(
            label: '42 PENDING',
            backgroundColor: AppColors.warning,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final categories = [
      'All Pending',
      'Flagged Posts',
      'Reported Comments',
      'High Priority',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategory == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: c,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedCategory = c),
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

  Widget _buildFlaggedCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> item,
  ) {
    final priorityColor = item['priorityColor'] as Color;

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
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  child: Icon(Icons.flag_outlined, color: priorityColor),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['author']} • ${item['type']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        'Reported ${item['time']} • Reason: ${item['reason']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: item['priority'] as String,
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  textColor: priorityColor,
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${item['content']}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Content approved')),
                    );
                  },
                ),
                AppSpacing.hGapSm,
                AppButton(
                  text: 'Remove Content',
                  icon: Icons.delete_outline,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Content removed')),
                    );
                  },
                  backgroundColor: colorScheme.error,
                  textColor: colorScheme.onError,
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
