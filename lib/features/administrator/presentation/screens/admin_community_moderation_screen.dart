import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Community Moderation Screen (Stitch ID: `9fb93a733ef7471fa696c644563940f3`).
///
/// Flagged content review and moderation governance queue. Displays pending reported items,
/// severity filters, flagged content details, and real moderation actions (Approve, Remove).
class AdminCommunityModerationScreen extends ConsumerStatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  ConsumerState<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends ConsumerState<AdminCommunityModerationScreen> {
  String _selectedCategory = 'All Pending';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flaggedAsync = ref.watch(adminFlaggedContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: flaggedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Error loading moderation queue: $err',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
        data: (flaggedItems) {
          final count = flaggedItems.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Queue Header Banner ──────────────────────────────
                    _buildModerationHeaderBanner(theme, colorScheme, count),

                    AppSpacing.vGapLg,

                    // ── Category Filters ────────────────────────────────
                    _buildCategoryFilterChips(theme, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Flagged Content Cards / Empty State ──────────────
                    if (flaggedItems.isEmpty)
                      _buildCleanEmptyState(theme, colorScheme)
                    else
                      ...flaggedItems.map(
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
          );
        },
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
    const priorityColor = AppColors.warning;
    final scaffold = ScaffoldMessenger.of(context);
    final contentId = item['id'] as String? ?? '';
    final contentType = item['type'] as String? ?? 'Post';

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
                  child: const Icon(Icons.flag_outlined, color: priorityColor),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['author']} • $contentType',
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
