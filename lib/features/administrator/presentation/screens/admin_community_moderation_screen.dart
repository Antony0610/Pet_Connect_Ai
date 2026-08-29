import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class AdminCommunityModerationScreen extends ConsumerStatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  ConsumerState<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends ConsumerState<AdminCommunityModerationScreen> {
  String _selectedCategory = 'All Pending';

  final List<Map<String, dynamic>> _demoFlagged = [
    {
      'id': 'mod_demo_1',
      'author': 'User @alex_doglover',
      'author_id': 'u_demo_1',
      'type': 'Post',
      'time': '12 mins ago',
      'reason': 'Unverified Prescription Dosage Advice',
      'priority': 'HIGH',
      'content': 'You don\'t need a vet clinic visit for eye infection, just give 500mg human amoxicillin twice a day directly!',
    },
    {
      'id': 'mod_demo_2',
      'author': 'User @sparky_sales',
      'author_id': 'u_demo_2',
      'type': 'Comment',
      'time': '45 mins ago',
      'reason': 'Commercial Spam / Unregulated Pet Sale',
      'priority': 'MEDIUM',
      'content': 'Cheap exotic puppies for sale! Contact WhatsApp +1-999-000-1111 immediately for shipping discount!',
    },
  ];

  void _suspendAuthor(String authorId, String authorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend User Account'),
        content: Text('Are you sure you want to suspend $authorName for policy violations?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend Account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(adminRepositoryProvider);
      await repo.suspendUser(authorId, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$authorName suspended by administrative order.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flaggedAsync = ref.watch(adminFlaggedContentProvider);
    final flaggedDbItems = flaggedAsync.valueOrNull ?? [];
    final flaggedItems = flaggedDbItems.isNotEmpty ? flaggedDbItems : _demoFlagged;

    final filtered = flaggedItems.where((item) {
      if (_selectedCategory == 'All Pending') return true;
      if (_selectedCategory == 'Flagged Posts') return item['type'] == 'Post';
      if (_selectedCategory == 'Reported Comments') return item['type'] == 'Comment';
      if (_selectedCategory == 'High Priority') return item['priority'] == 'HIGH';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminFlaggedContentProvider),
            tooltip: 'Refresh Queue',
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
                // ── Queue Header Banner ──────────────────────────────
                _buildModerationHeaderBanner(theme, colorScheme, filtered.length),

                AppSpacing.vGapLg,

                // ── Category Filters ────────────────────────────────
                _buildCategoryFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Flagged Content Cards ────────────────────────────
                if (filtered.isEmpty)
                  _buildCleanEmptyState(theme, colorScheme)
                else
                  ...filtered.map(
                    (item) => _buildFlaggedCard(
                      context,
                      theme,
                      colorScheme,
                      item,
                    ),
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
    int pendingCount,
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
                  '$pendingCount items pending review • AI Safety Filter Active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppChip(
            label: '$pendingCount PENDING',
            backgroundColor: pendingCount > 0 ? AppColors.warning : AppColors.success,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.success,
                size: 44,
              ),
            ),
            AppSpacing.vGapMd,
            Text(
              'All Caught Up!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'No flagged posts or comments in the moderation queue.\nCommunity feeds are clean and operating safely.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
    final isHigh = item['priority'] == 'HIGH';
    final priorityColor = isHigh ? colorScheme.error : AppColors.warning;
    final scaffold = ScaffoldMessenger.of(context);
    final contentId = item['id'] as String? ?? '';
    final contentType = item['type'] as String? ?? 'Post';
    final authorName = item['author'] as String? ?? 'User';
    final authorId = item['author_id'] as String? ?? '';

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
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  child: Icon(Icons.flag_outlined, color: priorityColor),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$authorName • $contentType',
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
                  label: item['priority'] as String? ?? 'MEDIUM',
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  textColor: priorityColor,
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Container(
              width: double.infinity,
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
                if (authorId.isNotEmpty) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.block, size: 14, color: Colors.orange),
                    label: const Text('Suspend Author', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    onPressed: () => _suspendAuthor(authorId, authorName),
                  ),
                  AppSpacing.hGapSm,
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  onPressed: () async {
                    final res = await ref.read(adminRepositoryProvider).moderateContent(
                          contentId: contentId,
                          contentType: contentType,
                          action: 'approve',
                        );
                    res.fold(
                      (f) => scaffold.showSnackBar(
                        SnackBar(content: Text('Moderation error: ${f.message}')),
                      ),
                      (_) {
                        ref.invalidate(adminFlaggedContentProvider);
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Content approved and cleared from queue.')),
                        );
                      },
                    );
                  },
                ),
                AppSpacing.hGapSm,
                AppButton(
                  text: 'Remove Content',
                  icon: Icons.delete_outline,
                  onPressed: () async {
                    final res = await ref.read(adminRepositoryProvider).moderateContent(
                          contentId: contentId,
                          contentType: contentType,
                          action: 'remove',
                        );
                    res.fold(
                      (f) => scaffold.showSnackBar(
                        SnackBar(content: Text('Removal error: ${f.message}')),
                      ),
                      (_) {
                        ref.invalidate(adminFlaggedContentProvider);
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Content permanently removed from platform.')),
                        );
                      },
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
