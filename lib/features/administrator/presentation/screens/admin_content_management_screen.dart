import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_article.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/features/administrator/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class AdminContentManagementScreen extends ConsumerStatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  ConsumerState<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends ConsumerState<AdminContentManagementScreen> {
  String _selectedTab = 'Published';

  final List<AdminArticle> _fallbackArticles = [
    AdminArticle(
      id: 'art_1',
      title: 'Top 5 Dog Parks in the City',
      summary:
          'Discover the best places to let your furry friend run free. From sprawling fields to agility courses...',
      content:
          'Full article body with recommended dog parks, hydration stations, and off-leash safety rules.',
      authorName: 'Editorial Staff',
      category: 'Pet Care & Recreation',
      status: 'Published',
      viewsCount: 1240,
      likesCount: 342,
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AdminArticle(
      id: 'art_2',
      title: 'Nutritional Needs for Senior Cats',
      summary:
          'As cats age, their dietary requirements change significantly. Here is a comprehensive guide to keeping them healthy...',
      content:
          'Detailed guidelines on protein density, kidney health, moisture content in senior feline diets.',
      authorName: 'Dr. Emily Chen, DVM',
      category: 'Veterinary Advice',
      status: 'Published',
      viewsCount: 3420,
      likesCount: 890,
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AdminArticle(
      id: 'art_3',
      title: 'Understanding Canine Allergy Symptoms',
      summary:
          'Seasonal allergies in dogs can cause itchiness and discomfort. Learn how to recognize and treat them...',
      content:
          'Early detection protocol for environmental and dietary allergies in canines.',
      authorName: 'Clinical Editorial',
      category: 'Health & Wellness',
      status: 'Draft',
      viewsCount: 0,
      likesCount: 0,
      createdAt: DateTime.now(),
    ),
  ];

  void _openCreateArticleDialog() async {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'Admin Editorial');
    String category = 'Health & Wellness';
    String status = 'Published';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Publish / Draft CMS Article'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Article Headline',
                    hintText: 'e.g. Essential Summer Hydration Tips',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Summary / Teaser',
                    hintText: 'Brief summary displayed on mobile feed',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Full Content Body',
                    hintText: 'Markdown or plain text article contents',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Health & Wellness',
                      child: Text('Health & Wellness'),
                    ),
                    DropdownMenuItem(
                      value: 'Veterinary Advice',
                      child: Text('Veterinary Advice'),
                    ),
                    DropdownMenuItem(
                      value: 'Pet Care & Recreation',
                      child: Text('Pet Care & Recreation'),
                    ),
                    DropdownMenuItem(
                      value: 'Official Announcements',
                      child: Text('Official Announcements'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDlgState(() => category = val ?? 'Health & Wellness'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Publication State',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Published',
                      child: Text('Published'),
                    ),
                    DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'Archived',
                      child: Text('Archived'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDlgState(() => status = val ?? 'Published'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save to CMS'),
            ),
          ],
        ),
      ),
    );

    if (created == true && titleCtrl.text.trim().isNotEmpty) {
      final newArticle = AdminArticle(
        id: '',
        title: titleCtrl.text.trim(),
        summary: summaryCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        authorName: authorCtrl.text.trim(),
        category: category,
        status: status,
        publishedAt: status == 'Published' ? DateTime.now() : null,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.saveArticle(newArticle);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save article: ${failure.message}'),
              ),
            );
          }
        },
        (_) {
          ref.invalidate(adminArticlesProvider(null));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Article "${titleCtrl.text.trim()}" published to database!',
                ),
              ),
            );
          }
        },
      );
    }
  }

  void _deleteArticle(AdminArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to remove "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteArticle(article.id);
      ref.invalidate(adminArticlesProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article "${article.title}" removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final articlesAsync = ref.watch(adminArticlesProvider(null));
    final articleList =
        (articlesAsync.valueOrNull != null &&
            articlesAsync.valueOrNull!.isNotEmpty)
        ? articlesAsync.valueOrNull!
        : _fallbackArticles;

    final filtered = articleList.where((a) {
      if (_selectedTab == 'Published') return a.status == 'Published';
      if (_selectedTab == 'Drafts') return a.status == 'Draft';
      if (_selectedTab == 'Archived Posts') return a.status == 'Archived';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management System'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            onPressed: _openCreateArticleDialog,
            tooltip: 'New Article',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminArticlesProvider(null)),
            tooltip: 'Refresh CMS',
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
                if (filtered.isEmpty && articlesAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filtered.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No articles found in "$_selectedTab".',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Create Post" to publish new educational content or announcements.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (art) =>
                        _buildArticleCard(context, theme, colorScheme, art),
                  ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentTab: AdminTab.content,
      ),
    );
  }

  Widget _buildCmsHeaderCard(ThemeData theme, ColorScheme colorScheme) {
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
            0xFF059669,
          ).withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.newspaper_rounded,
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
                  'Community & Education CMS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage articles, pet health advisories, and care bulletins.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Create Post',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _openCreateArticleDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final tabs = ['Published', 'Drafts', 'Archived Posts'];
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
    AdminArticle art,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    final (statusColor, statusBg) = switch (art.status) {
      'Published' => (
        const Color(0xFF059669),
        const Color(0xFF059669).withValues(alpha: 0.12),
      ),
      'Draft' => (
        const Color(0xFFD97706),
        const Color(0xFFD97706).withValues(alpha: 0.12),
      ),
      _ => (
        const Color(0xFF64748B),
        const Color(0xFF64748B).withValues(alpha: 0.12),
      ),
    };

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
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      art.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      art.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                art.summary,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      art.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${art.viewsCount}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_outline_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${art.likesCount}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFE11D48),
                    ),
                    tooltip: 'Delete Article',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () => _deleteArticle(art),
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
