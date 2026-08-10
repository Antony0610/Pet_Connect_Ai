import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Global Search - PetConnect**
/// (Light Theme design authority, ID `00e65b5fa17947ea87edbc875b48e3e4`).
///
/// Universal ecosystem search across pets, medical records, community discussions,
/// veterinary contacts, and smart collar telemetry.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  static const double _maxContentWidth = 1000;
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Pets',
    'Health',
    'Community',
    'Vets',
    'Collar',
  ];

  final List<_SearchResultItem> _allResults = const [
    _SearchResultItem(
      title: 'Buddy (Golden Retriever)',
      category: 'Pets',
      subtitle: 'Active Collar Online • 65 lbs • Vaccinated',
      icon: Icons.pets,
      routeName: RouteNames.ownerPets,
    ),
    _SearchResultItem(
      title: 'Rabies Vaccination Certificate 2024',
      category: 'Health',
      subtitle: 'Health Vault • PDF Document • Added May 12',
      icon: Icons.assignment_outlined,
      routeName: RouteNames.ownerHealthVault,
    ),
    _SearchResultItem(
      title: 'Post-Surgery Knee Rehab (TPLO)',
      category: 'Health',
      subtitle: 'Active Treatment Plan • 65% Completed',
      icon: Icons.healing,
      routeName: RouteNames.ownerHealthTreatment,
    ),
    _SearchResultItem(
      title: 'Metro Vet Clinic — Dr. Emily Carter',
      category: 'Vets',
      subtitle: 'Orthopedic Specialist • 1.2 miles away',
      icon: Icons.local_hospital_outlined,
      routeName: RouteNames.ownerHealth,
    ),
    _SearchResultItem(
      title: 'Weekend Dog Park Playdate Group',
      category: 'Community',
      subtitle: 'Local Community • 42 members active nearby',
      icon: Icons.groups_outlined,
      routeName: RouteNames.ownerCommunityLocal,
    ),
    _SearchResultItem(
      title: 'Smart Collar Battery & Telemetry',
      category: 'Collar',
      subtitle: 'Collar Status: 94% Battery • GPS Online',
      icon: Icons.watch_outlined,
      routeName: RouteNames.ownerCollar,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final filteredResults = _allResults.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final query = _searchController.text.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: AppTextField(
          controller: _searchController,
          hintText: 'Search pets, health, community, vets...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchController.clear()),
                )
              : null,
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Category Filters ───────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(cat),
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
                            if (selected)
                              setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Recent Search Tags ─────────────────────────────
                if (_searchController.text.isEmpty) ...[
                  Text(
                    'Recent Searches',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildRecentTag('Rabies Certificate'),
                      _buildRecentTag('Dr. Emily Carter'),
                      _buildRecentTag('Apoquel Dosing'),
                      _buildRecentTag('Lost Retriever'),
                    ],
                  ),
                  AppSpacing.vGapXl,
                ],

                // ── Universal Results List ─────────────────────────
                Text(
                  'Results (${filteredResults.length})',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                if (filteredResults.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No matching records or posts found.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredResults.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => context.goNamed(item.routeName),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                color: scheme.primary,
                                size: AppIconSizes.md,
                              ),
                            ),
                            AppSpacing.hGapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: context.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: AppTypography.bold,
                                              ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(item.category),
                                        backgroundColor:
                                            scheme.surfaceContainerHigh,
                                        labelStyle: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    item.subtitle,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTag(String text) {
    return ActionChip(
      avatar: const Icon(Icons.history, size: 14),
      label: Text(text),
      onPressed: () {
        setState(() => _searchController.text = text);
      },
    );
  }
}

class _SearchResultItem {
  const _SearchResultItem({
    required this.title,
    required this.category,
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final String category;
  final String subtitle;
  final IconData icon;
  final String routeName;
}
