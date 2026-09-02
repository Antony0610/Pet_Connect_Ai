import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/pharmacy_inventory_notifier.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/buttons/portal_notification_badge_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// **Interactive Inventory & Pharmacy Manager** — `/vet/inventory`.
///
/// Live pharmacy management with stock adjustments, restock order dispatches,
/// low-stock threshold triggers, expiration date trackers, and SKU registration.
class InventoryPharmacyScreen extends ConsumerStatefulWidget {
  const InventoryPharmacyScreen({super.key});

  @override
  ConsumerState<InventoryPharmacyScreen> createState() =>
      _InventoryPharmacyScreenState();
}

class _InventoryPharmacyScreenState
    extends ConsumerState<InventoryPharmacyScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'Pharmacy',
    'Biologics',
    'Preventatives',
    'Surgical',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inventory = ref.watch(pharmacyInventoryStateProvider);

    final filtered = inventory.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCat =
          _selectedCategory == 'ALL' || item.category == _selectedCategory;

      return matchesQuery && matchesCat;
    }).toList();

    final lowStockCount = inventory.where((i) => i.isLowStock).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pharmacy & Medical Inventory',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${inventory.length} active SKUs • $lowStockCount low stock alerts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PortalNotificationBadgeButton(
            onPressed: () => context.push(RoutePaths.vetNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add Medical Item',
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Categories ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  AppTextField(
                    hintText: 'Search by medication name, SKU, or batch LOT…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  AppSpacing.vGapSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: colorScheme.primaryContainer,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Inventory List ─────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48),
                          AppSpacing.vGapSm,
                          Text(
                            'No inventory items found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => AppSpacing.vGapSm,
                      itemBuilder: (ctx, index) {
                        final item = filtered[index];
                        return _buildInventoryCard(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add SKU'),
      ),
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.dashboard),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    PharmacyInventoryEntry item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expiryFormatted = DateFormat('MMM yyyy').format(item.expirationDate);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isLowStock
                      ? Colors.red.shade50
                      : colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  item.isCritical
                      ? Icons.emergency_rounded
                      : Icons.medication_rounded,
                  color: item.isLowStock ? Colors.red : colorScheme.primary,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(item),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      'SKU: ${item.sku} • LOT: ${item.batchNumber} • Exp: $expiryFormatted',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          const Divider(height: 1),
          AppSpacing.vGapSm,

          // Live Stock Counts & Adjustment Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT STOCK',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Text(
                    '${item.stockQuantity} ${item.unit}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: item.isLowStock ? Colors.red.shade700 : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove, size: 18),
                    tooltip: 'Dispense / Reduce 1',
                    onPressed: item.stockQuantity > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(pharmacyInventoryStateProvider.notifier)
                                .adjustStock(item.id, -1);
                          }
                        : null,
                  ),
                  AppSpacing.hGapXs,
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Add / Stock 1',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(pharmacyInventoryStateProvider.notifier)
                          .adjustStock(item.id, 1);
                    },
                  ),
                  AppSpacing.hGapSm,
                  AppButton.outlined(
                    label: 'Reorder',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () => _showReorderDialog(context, item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PharmacyInventoryEntry item) {
    Color bg = Colors.green.shade50;
    Color fg = Colors.green.shade800;

    if (item.stockQuantity <= 0) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else if (item.isLowStock) {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        item.statusText.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  void _showReorderDialog(BuildContext context, PharmacyInventoryEntry item) {
    int reorderUnits = 25;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reorder ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current on hand: ${item.stockQuantity} ${item.unit} (Min Threshold: ${item.minThreshold})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              AppSpacing.vGapMd,
              const Text('Select Reorder Batch Quantity:', style: TextStyle(fontWeight: FontWeight.bold)),
              AppSpacing.vGapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: reorderUnits > 5
                        ? () => setDialogState(() => reorderUnits -= 5)
                        : null,
                  ),
                  AppSpacing.hGapMd,
                  Text(
                    '$reorderUnits ${item.unit}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.hGapMd,
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: () => setDialogState(() => reorderUnits += 5),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            AppButton.filled(
              label: 'Dispatch PO',
              icon: Icons.check,
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref
                    .read(pharmacyInventoryStateProvider.notifier)
                    .reorderStock(item.id, reorderUnits);
                Navigator.of(ctx).pop();
                context.showSnackbar(
                  '✓ Purchase order for $reorderUnits ${item.unit} of ${item.name} dispatched!',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '20');
    final minCtrl = TextEditingController(text: '5');
    final batchCtrl = TextEditingController(text: 'LOT-NEW-01');
    String category = 'Pharmacy';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Register New Pharmacy SKU',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapMd,
                AppTextField(controller: nameCtrl, labelText: 'Medication / Item Name'),
                AppSpacing.vGapSm,
                AppTextField(controller: skuCtrl, labelText: 'SKU Code (e.g. PH-5021)'),
                AppSpacing.vGapSm,
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: stockCtrl, labelText: 'Initial Stock')),
                    AppSpacing.hGapSm,
                    Expanded(child: AppTextField(controller: minCtrl, labelText: 'Min Alert Level')),
                  ],
                ),
                AppSpacing.vGapSm,
                AppTextField(controller: batchCtrl, labelText: 'LOT Batch Code'),
                AppSpacing.vGapMd,
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Pharmacy', label: Text('Pharmacy')),
                    ButtonSegment(value: 'Biologics', label: Text('Biologics')),
                    ButtonSegment(value: 'Surgical', label: Text('Surgical')),
                  ],
                  selected: {category},
                  onSelectionChanged: (set) => setModalState(() => category = set.first),
                ),
                AppSpacing.vGapLg,
                AppButton.filled(
                  label: 'Add to Inventory Catalog',
                  icon: Icons.check,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(pharmacyInventoryStateProvider.notifier).addItem(
                          name: nameCtrl.text.trim(),
                          category: category,
                          sku: skuCtrl.text.trim().isNotEmpty
                              ? skuCtrl.text.trim()
                              : 'SKU-TEMP',
                          initialStock: int.tryParse(stockCtrl.text) ?? 20,
                          unit: 'units',
                          minThreshold: int.tryParse(minCtrl.text) ?? 5,
                          isCritical: false,
                          batchNumber: batchCtrl.text.trim(),
                          expirationDate: DateTime.now().add(const Duration(days: 365)),
                        );
                    Navigator.of(ctx).pop();
                    context.showSnackbar('✓ Added ${nameCtrl.text.trim()} to catalog');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
