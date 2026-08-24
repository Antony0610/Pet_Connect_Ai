import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

class SavedItem {
  SavedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.timeAgo,
    required this.route,
    this.author,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final String timeAgo;
  final String route;
  final String? author;
}

/// **Saved Content Screen**
///
/// Enables pet owners to view, manage, filter, and organize bookmarked articles,
/// lost pet alerts, community discussions, and saved adoption profiles.
class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTab = 'Recent';
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _tabs = const ['Recent', 'By Category', 'Collections'];

  final List<SavedItem> _savedItems = [
    SavedItem(
      id: 'item_1',
      title: 'Ultimate Guide to Puppy Socialization in 2026',
      description:
          'Discover the most effective, science-backed methods for introducing your new puppy to the world, ensuring they grow into confident adult dogs.',
      category: 'Knowledge Article',
      icon: Icons.article_outlined,
      timeAgo: 'Saved 2 days ago',
      route: RouteNames.ownerCommunityDiscover,
    ),
    SavedItem(
      id: 'item_2',
      title: "Missing: 'Snowball' — Bichon Frise",
      description:
          'White Bichon Frise, female, 3 years old. Last seen near Maple Park. Wearing red collar with tags.',
      category: 'Lost Pet Alert',
      icon: Icons.campaign,
      timeAgo: 'Saved 3 days ago',
      route: RouteNames.ownerCommunitySightings,
    ),
    SavedItem(
      id: 'item_3',
      title: 'Homemade Treats Recipe that actually works!',
      description:
          'Tried this new sweet potato and oat recipe for sensitive dog stomachs and it is a game changer.',
      category: 'Community Discussion',
      icon: Icons.forum_outlined,
      timeAgo: 'Saved 5 days ago',
      author: 'Alex Johnson',
      route: RouteNames.ownerCommunityDiscover,
    ),
    SavedItem(
      id: 'item_4',
      title: 'Bella — Golden Retriever Mix',
      description: '2 yrs • Female • City Rescue Shelter · Adoption Candidate',
      category: 'Adoption Profile',
      icon: Icons.pets,
      timeAgo: 'Saved 1 week ago',
      route: RouteNames.ownerCommunityAdoption,
    ),
  ];

  void _removeBookmark(SavedItem item) {
    setState(() {
      _savedItems.removeWhere((i) => i.id == item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.title}" from saved bookmarks.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _savedItems.add(item);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final filteredItems = _savedItems.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesQuery;
    }).toList();

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search saved items…',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                'Saved Content',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: AppTypography.bold,
                  letterSpacing: -0.25,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
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
                // ── Filter Tabs Row ────────────────────────────────
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

                if (filteredItems.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 48,
                            color: scheme.onSurfaceVariant,
                          ),
                          AppSpacing.vGapSm,
                          Text(
                            'No saved items found',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No bookmarks matched "$_searchQuery".'
                                : 'Bookmark articles, alerts, or posts to read them later.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final item in filteredItems) ...[
                    AppCard(
                      onTap: () => context.goNamed(item.route),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.icon,
                                color: item.category == 'Lost Pet Alert'
                                    ? scheme.error
                                    : scheme.primary,
                                size: 18,
                              ),
                              AppSpacing.hGapXs,
                              Text(
                                item.category,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: item.category == 'Lost Pet Alert'
                                      ? scheme.error
                                      : scheme.primary,
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.bookmark,
                                  color: item.category == 'Lost Pet Alert'
                                      ? scheme.error
                                      : scheme.primary,
                                ),
                                tooltip: 'Remove Bookmark',
                                onPressed: () => _removeBookmark(item),
                              ),
                            ],
                          ),
                          Text(
                            item.title,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            item.description,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.vGapSm,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.timeAgo,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              AppButton.outlined(
                                onPressed: () => context.goNamed(item.route),
                                size: AppButtonSize.small,
                                borderRadius: AppRadius.brPill,
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vGapSm,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
