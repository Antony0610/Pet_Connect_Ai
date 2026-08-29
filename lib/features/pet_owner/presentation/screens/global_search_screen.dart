import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Ecosystem Search Item representation across pets, posts, records, and alerts.
class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.snippet,
    required this.color,
    required this.route,
    this.routeParams = const {},
  });

  final String id;
  final String title;
  final String category;
  final IconData icon;
  final String snippet;
  final Color color;
  final String route;
  final Map<String, String> routeParams;
}

/// Global Search Screen.
///
/// Multi-domain ecosystem search across pets, medical records,
/// community posts, lost pet alerts, and health guides.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  Timer? _debounceTimer;
  bool _isLoading = false;

  List<String> _recentSearches = [];
  List<SearchResultItem> _searchResults = [];

  static const String _historyKey = 'global_search_history_v2';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    final prefs = ref.read(sharedPreferencesProvider);
    final history = prefs.getStringList(_historyKey) ?? [];
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final list = List<String>.from(_recentSearches);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 10) list.removeLast();

    setState(() => _recentSearches = list);
    await prefs.setStringList(_historyKey, list);
  }

  Future<void> _clearSearchHistory() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_historyKey);
    setState(() => _recentSearches = []);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseClientProvider);
    final results = <SearchResultItem>[];

    try {
      // 1. Search Pets
      try {
        final petsRes = await supabase
            .from('pets')
            .select()
            .or('name.ilike.%$query%,breed.ilike.%$query%,species.ilike.%$query%')
            .limit(5);

        for (final p in petsRes as List) {
          final m = p as Map<String, dynamic>;
          results.add(
            SearchResultItem(
              id: m['id'].toString(),
              title: m['name']?.toString() ?? 'Companion',
              category: 'Companion',
              icon: Icons.pets_rounded,
              snippet: '${m['breed'] ?? m['species'] ?? 'Pet'} • Status: ${m['health_status'] ?? 'Active'}',
              color: AppColors.lightPrimary,
              route: RouteNames.ownerPetDetail,
              routeParams: {'petId': m['id'].toString()},
            ),
          );
        }
      } catch (_) {}

      // 2. Search Community Posts
      try {
        final postsRes = await supabase
            .from('community_posts')
            .select()
            .or('title.ilike.%$query%,content.ilike.%$query%')
            .limit(5);

        for (final p in postsRes as List) {
          final m = p as Map<String, dynamic>;
          results.add(
            SearchResultItem(
              id: m['id'].toString(),
              title: m['title']?.toString() ?? 'Community Discussion',
              category: 'Community',
              icon: Icons.forum_rounded,
              snippet: m['content']?.toString() ?? '',
              color: AppColors.info,
              route: RoutePaths.ownerCommunity,
            ),
          );
        }
      } catch (_) {}

      // 3. Search Medical Records
      try {
        final recordsRes = await supabase
            .from('health_records')
            .select()
            .or('title.ilike.%$query%,diagnosis.ilike.%$query%,veterinarian_name.ilike.%$query%')
            .limit(5);

        for (final r in recordsRes as List) {
          final m = r as Map<String, dynamic>;
          results.add(
            SearchResultItem(
              id: m['id'].toString(),
              title: m['title']?.toString() ?? 'Medical Record',
              category: 'Health Record',
              icon: Icons.monitor_heart_rounded,
              snippet: 'Diagnosis: ${m['diagnosis'] ?? 'Routine Care'} • ${m['veterinarian_name'] ?? 'Veterinary Clinic'}',
              color: AppColors.success,
              route: RoutePaths.ownerHealthMedical,
            ),
          );
        }
      } catch (_) {}

      // 4. Search Lost Pet Alerts
      try {
        final alertsRes = await supabase
            .from('lost_pet_alerts')
            .select()
            .or('pet_name.ilike.%$query%,last_seen_location.ilike.%$query%')
            .limit(5);

        for (final a in alertsRes as List) {
          final m = a as Map<String, dynamic>;
          results.add(
            SearchResultItem(
              id: m['id'].toString(),
              title: 'Lost Alert: ${m['pet_name'] ?? 'Pet'}',
              category: 'Lost & Found',
              icon: Icons.warning_amber_rounded,
              snippet: 'Last seen: ${m['last_seen_location'] ?? 'Area'} • Status: ${m['status'] ?? 'Active'}',
              color: AppColors.lightError,
              route: RoutePaths.ownerCommunitySightings,
            ),
          );
        }
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredResults = _selectedCategory == 'All'
        ? _searchResults
        : _searchResults.where((r) => r.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Ecosystem Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                // ── Search Input Bar ────────────────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search companions, posts, medical records, or alerts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  onChanged: _onSearchChanged,
                ),

                AppSpacing.vGapLg,

                // ── Category Filter Chips ────────────────────────────
                _buildCategoryChips(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Recent Searches Section ──────────────────────────
                if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearSearchHistory,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((s) {
                      return ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(s),
                        onPressed: () {
                          _searchController.text = s;
                          _performSearch(s);
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.vGapLg,
                ],

                // ── Search Results List ─────────────────────────────
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchController.text.isNotEmpty) ...[
                  Text(
                    'Search Results (${filteredResults.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  if (filteredResults.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
                          AppSpacing.vGapSm,
                          Text(
                            'No matching results found for "${_searchController.text}"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredResults.map(
                      (res) => _buildResultCard(context, theme, colorScheme, res),
                    ),
                ] else ...[
                  Text(
                    'Quick Search Shortcuts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.pets, size: 16),
                        label: const Text('My Pets'),
                        onPressed: () {
                          _searchController.text = 'dog';
                          _performSearch('dog');
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.vaccines, size: 16),
                        label: const Text('Vaccinations'),
                        onPressed: () {
                          _searchController.text = 'vaccine';
                          _performSearch('vaccine');
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.warning, size: 16),
                        label: const Text('Lost Alerts'),
                        onPressed: () {
                          _searchController.text = 'lost';
                          _performSearch('lost');
                        },
                      ),
                    ],
                  ),
                ],

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, ColorScheme colorScheme) {
    final categories = [
      'All',
      'Companion',
      'Community',
      'Health Record',
      'Lost & Found',
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

  Widget _buildResultCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    SearchResultItem res,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: () {
          _saveSearchTerm(_searchController.text);
          if (res.routeParams.isNotEmpty) {
            context.goNamed(res.route, pathParameters: res.routeParams);
          } else {
            context.push(res.route);
          }
        },
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: res.color.withValues(alpha: 0.15),
                child: Icon(res.icon, color: res.color),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            res.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ),
                        AppChip(
                          label: res.category,
                          backgroundColor: res.color.withValues(alpha: 0.15),
                          textColor: res.color,
                        ),
                      ],
                    ),
                    if (res.snippet.isNotEmpty)
                      Text(
                        res.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
