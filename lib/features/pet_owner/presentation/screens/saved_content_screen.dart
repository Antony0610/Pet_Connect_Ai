import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'timeAgo': timeAgo,
    'route': route,
    'author': author,
  };

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    IconData ic;
    switch (json['category']) {
      case 'Lost Pet Alert':
        ic = Icons.campaign;
        break;
      case 'Community Discussion':
        ic = Icons.forum_outlined;
        break;
      case 'Adoption Profile':
        ic = Icons.pets;
        break;
      default:
        ic = Icons.article_outlined;
    }
    return SavedItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: ic,
      timeAgo: json['timeAgo'] as String,
      route: json['route'] as String,
      author: json['author'] as String?,
    );
  }
}

/// **Saved Content Screen**
///
/// Enables pet owners to view, manage, filter, and organize bookmarked articles,
/// lost pet alerts, community discussions, and saved adoption profiles with persistence.
class SavedContentScreen extends ConsumerStatefulWidget {
  const SavedContentScreen({super.key});

  @override
  ConsumerState<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends ConsumerState<SavedContentScreen> {
  static const double _maxContentWidth = 1000;
  static const String _storageKey = 'user_saved_bookmarks_v2';

  String _selectedTab = 'Recent';
  String _searchQuery = '';
  bool _isSearching = false;
  String _selectedCategory = 'All';

  final List<String> _tabs = const ['Recent', 'By Category', 'Collections'];
  final List<String> _categories = const [
    'All',
    'Knowledge Article',
    'Lost Pet Alert',
    'Community Discussion',
    'Adoption Profile',
  ];

  List<SavedItem> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _savedItems = decoded.map((e) => SavedItem.fromJson(e as Map<String, dynamic>)).toList();
        });
        return;
      } catch (_) {}
    }

    // Default starter guides
    final initial = [
      SavedItem(
        id: 'item_1',
        title: 'Science-Backed Guide to Puppy & Kitten Socialization',
        description:
            'Discover the most effective methods for introducing your young companion to novel environments, sounds, and other pets during early growth.',
        category: 'Knowledge Article',
        icon: Icons.article_outlined,
        timeAgo: 'Recently bookmarked',
        route: RouteNames.ownerCommunityDiscover,
      ),
      SavedItem(
        id: 'item_2',
        title: 'Missing Companion Protocol & Neighborhood Action',
        description:
            'Critical steps to take within the first 60 minutes of a pet going missing, including smart collar tracking and broadcast alerts.',
        category: 'Lost Pet Alert',
        icon: Icons.campaign,
        timeAgo: 'Recently bookmarked',
        route: RouteNames.ownerCommunitySightings,
      ),
      SavedItem(
        id: 'item_3',
        title: 'Homemade Sweet Potato & Oat Sensitive Stomach Treats',
        description:
            'Veterinarian-reviewed recipe for companions with gastrointestinal sensitivity and food allergies.',
        category: 'Community Discussion',
        icon: Icons.forum_outlined,
        timeAgo: '2 days ago',
        author: 'Dr. Sarah Smith',
        route: RouteNames.ownerCommunityDiscover,
      ),
    ];

    setState(() {
      _savedItems = initial;
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = jsonEncode(_savedItems.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  void _removeBookmark(SavedItem item) {
    setState(() {
      _savedItems.removeWhere((i) => i.id == item.id);
    });
    _saveBookmarks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.title}" from saved bookmarks.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _savedItems.add(item);
            });
            _saveBookmarks();
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

      final matchesCategory = _selectedTab != 'By Category' ||
          _selectedCategory == 'All' ||
          item.category == _selectedCategory;

      final matchesCollection = _selectedTab != 'Collections' ||
          item.category == 'Knowledge Article' ||
          item.category == 'Community Discussion';

      return matchesQuery && matchesCategory && matchesCollection;
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
                if (_selectedTab == 'By Category') ...[
                  AppSpacing.vGapSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
