import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  void _suspendAuthor(String authorId, String authorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend User Account'),
        content: Text(
          'Are you sure you want to suspend $authorName for policy violations?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Suspend Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(adminRepositoryProvider);
      await repo.suspendUser(authorId, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$authorName suspended by administrative order.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flaggedAsync = ref.watch(adminFlaggedContentProvider);
    final flaggedItems = flaggedAsync.valueOrNull ?? [];

    final filtered = flaggedItems.where((item) {
      if (_selectedCategory == 'All Pending') return true;
      if (_selectedCategory == 'Flagged Posts') return item['type'] == 'Post';
      if (_selectedCategory == 'Reported Comments') {
        return item['type'] == 'Comment';
      }
      if (_selectedCategory == 'High Priority') {
        return item['priority'] == 'HIGH';
      }
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
                _buildModerationHeaderBanner(
                  theme,
                  colorScheme,
                  filtered.length,
                ),

                AppSpacing.vGapLg,

                // ── Category Filters ────────────────────────────────
                _buildCategoryFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Flagged Content Cards ────────────────────────────
                if (filtered.isEmpty)
                  _buildCleanEmptyState(theme, colorScheme)
                else
                  ...filtered.map(
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
    int pendingCount,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(
            0xFF7C3AED,
          ).withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Moderation Queue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pendingCount items pending review • AI Safety Filter Active',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (pendingCount > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669))
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pendingCount PENDING',
              style: TextStyle(
                color: pendingCount > 0
                    ? const Color(0xFFD97706)
                    : const Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
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
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF059669),
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
    final cats = [
      'All Pending',
      'Flagged Posts',
      'Reported Comments',
      'High Priority',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((c) {
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
    final isDark = theme.brightness == Brightness.dark;
    final isHigh = item['priority'] == 'HIGH';
    final priorityColor = isHigh
        ? const Color(0xFFE11D48)
        : const Color(0xFFD97706);
    final scaffold = ScaffoldMessenger.of(context);
    final contentId = item['id'] as String? ?? '';
    final contentType = item['type'] as String? ?? 'Post';
    final authorName = item['author'] as String? ?? 'User';
    final authorId = item['author_id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: priorityColor.withValues(alpha: isDark ? 0.25 : 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: priorityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$authorName • $contentType',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Reported ${item['time']} • Reason: ${item['reason']}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['priority'] as String? ?? 'MEDIUM',
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${item['content']}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (authorId.isNotEmpty) ...[
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                      label: const Text(
                        'Suspend Author',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD97706)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _suspendAuthor(authorId, authorName),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    onPressed: () async {
                      final res = await ref
                          .read(adminRepositoryProvider)
                          .moderateContent(
                            contentId: contentId,
                            contentType: contentType,
                            action: 'approve',
                          );
                      res.fold(
                        (f) => scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Moderation error: ${f.message}'),
                          ),
                        ),
                        (_) {
                          ref.invalidate(adminFlaggedContentProvider);
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Content approved and cleared from queue.',
                              ),
                            ),
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
                      final res = await ref
                          .read(adminRepositoryProvider)
                          .moderateContent(
                            contentId: contentId,
                            contentType: contentType,
                            action: 'remove',
                          );
                      res.fold(
                        (f) => scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Removal error: ${f.message}'),
                          ),
                        ),
                        (_) {
                          ref.invalidate(adminFlaggedContentProvider);
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Content permanently removed from platform.',
                              ),
                            ),
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
      ),
    );
  }
}
