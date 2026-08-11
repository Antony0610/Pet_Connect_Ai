import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Content Management Screen (Stitch ID: `d809643e6f6b48fcbf4c05af7551f919`).
///
/// CMS and educational article management dashboard screen. Displays published articles,
/// draft reviews, view/like telemetry stats, and publication actions.
class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  String _selectedTab = 'Published';

  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Top 5 Dog Parks in the City',
      'summary':
          'Discover the best places to let your furry friend run free. From sprawling fields to agility courses...',
      'views': '1.2k',
      'likes': '342',
      'status': 'Published',
      'publishedAgo': '2h ago',
      'statusColor': AppColors.success,
    },
    {
      'title': 'Nutritional Needs for Senior Cats',
      'summary':
          'As cats age, their dietary requirements change significantly. Here is a comprehensive guide to keeping them healthy...',
      'views': '3.4k',
      'likes': '890',
      'status': 'Published',
      'publishedAgo': '1d ago',
      'statusColor': AppColors.success,
    },
    {
      'title': 'Understanding Canine Allergy Symptoms',
      'summary':
          'Seasonal allergies in dogs can cause itchiness and discomfort. Learn how to recognize and treat them...',
      'views': '0',
      'likes': '0',
      'status': 'Draft',
      'publishedAgo': 'Editing',
      'statusColor': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management System'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Article Editor...')),
              );
            },
            tooltip: 'New Article',
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
                // ── Header Overview Card ────────────────────────────
                _buildCmsHeaderCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Status Filter Tabs ──────────────────────────────
                _buildStatusFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Content Article List ────────────────────────────
                ..._articles.map(
                  (art) => _buildArticleCard(context, theme, colorScheme, art),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCmsHeaderCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.article_outlined, color: colorScheme.primary),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Posts & Educational CMS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Manage articles, care guides, and official community announcements.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            text: 'Create Post',
            icon: Icons.add,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Creating new post draft...')),
              );
            },
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final tabs = ['Published', 'Drafts', 'Archived Posts', 'Pending Review'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSelected = _selectedTab == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: t,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedTab = t),
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

  Widget _buildArticleCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> art,
  ) {
    final statusColor = art['statusColor'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    art['title'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                AppChip(
                  label: art['status'] as String,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              art['summary'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  art['views'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.hGapMd,
                Icon(
                  Icons.favorite_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  art['likes'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Editing ${art['title']}')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
