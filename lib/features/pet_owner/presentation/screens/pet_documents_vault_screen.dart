import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Pet Documents Vault**
/// (Light Theme design authority, ID `ab7d2d74a7ae4eb3b1c6d3df399c51eb`).
///
/// Centralized vault for organizing medical certificates, lab results, prescriptions,
/// and insurance policies with search, filter, download, and share actions.
class PetDocumentsVaultScreen extends StatefulWidget {
  const PetDocumentsVaultScreen({super.key});

  @override
  State<PetDocumentsVaultScreen> createState() =>
      _PetDocumentsVaultScreenState();
}

class _PetDocumentsVaultScreenState extends State<PetDocumentsVaultScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = const [
    'All',
    'Vaccinations',
    'Lab Results',
    'Prescriptions',
    'Insurances',
  ];

  final List<_VaultDocumentItem> _documents = const [
    _VaultDocumentItem(
      title: 'Rabies Vaccination Certificate 2024',
      category: 'Vaccinations',
      meta: 'PDF • 1.2 MB • Added May 12, 2024',
      provider: 'Dr. Emily Carter • Metro Vet Clinic',
    ),
    _VaultDocumentItem(
      title: 'Blood Work & CBC Panel',
      category: 'Lab Results',
      meta: 'PDF • 3.4 MB • Added Apr 02, 2024',
      provider: 'Dr. Mark Vance • City Animal Hospital',
    ),
    _VaultDocumentItem(
      title: 'Apoquel Prescription Renewal',
      category: 'Prescriptions',
      meta: 'PDF • 0.8 MB • Added Mar 15, 2024',
      provider: 'Dr. Emily Carter • Metro Vet Clinic',
    ),
    _VaultDocumentItem(
      title: 'Pet Insurance Policy #PT-9042',
      category: 'Insurances',
      meta: 'PDF • 2.1 MB • Added Jan 05, 2024',
      provider: 'HealthyPaws Insurance Co.',
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

    final filteredDocs = _documents.where((doc) {
      final matchesCategory =
          _selectedCategory == 'All' || doc.category == _selectedCategory;
      final query = _searchController.text.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          doc.title.toLowerCase().contains(query) ||
          doc.provider.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Pet Documents Vault',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Document',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document upload picker ready')),
              );
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
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Subtitle & Search Input ────────────────────────
                Text(
                  'Secure digital repository for all medical records, lab reports, and insurance documents.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search documents by title, clinic, or vet...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.vGapLg,

                // ── Category Filter Chips ──────────────────────────
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

                // ── Document Cards List ───────────────────────────
                if (filteredDocs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No documents found in this category.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredDocs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAlignment.start,
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
                                Icons.picture_as_pdf,
                                color: scheme.primary,
                                size: AppIconSizes.md,
                              ),
                            ),
                            AppSpacing.hGapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(
                                          fontWeight: AppTypography.bold,
                                        ),
                                  ),
                                  AppSpacing.vGapXs,
                                  Text(
                                    doc.meta,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                  ),
                                  Text(
                                    doc.provider,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: AppTypography.semiBold,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.file_download_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                              tooltip: 'Download',
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.share_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                              tooltip: 'Share',
                              onPressed: () {},
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
}

class _VaultDocumentItem {
  const _VaultDocumentItem({
    required this.title,
    required this.category,
    required this.meta,
    required this.provider,
  });

  final String title;
  final String category;
  final String meta;
  final String provider;
}
