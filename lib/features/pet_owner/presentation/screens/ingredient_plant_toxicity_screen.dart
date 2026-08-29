import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

enum ToxicityLevel { safe, caution, toxic }

enum ToxicityCategory { all, foods, plants, medications, chemicals }

class ToxicityItem {
  const ToxicityItem({
    required this.id,
    required this.name,
    required this.level,
    required this.category,
    required this.targetSpecies,
    required this.summary,
    required this.symptoms,
    required this.firstAid,
  });

  final String id;
  final String name;
  final ToxicityLevel level;
  final ToxicityCategory category;
  final String targetSpecies;
  final String summary;
  final String symptoms;
  final String firstAid;
}

class IngredientPlantToxicityScreen extends ConsumerStatefulWidget {
  const IngredientPlantToxicityScreen({super.key});

  @override
  ConsumerState<IngredientPlantToxicityScreen> createState() =>
      _IngredientPlantToxicityScreenState();
}

class _IngredientPlantToxicityScreenState
    extends ConsumerState<IngredientPlantToxicityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ToxicityCategory _selectedCategory = ToxicityCategory.all;
  String _searchQuery = '';

  static const List<ToxicityItem> _items = [
    // ── Foods ─────────────────────────────────────────────────────────────
    ToxicityItem(
      id: 'chocolate',
      name: 'Chocolate / Cocoa / Theobromine',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains theobromine and caffeine. Dark chocolate and baking cocoa are extremely hazardous.',
      symptoms: 'Vomiting, diarrhea, tachycardia (rapid heart rate), tremors, seizures, cardiac arrhythmias.',
      firstAid: 'Measure estimated grams consumed and cocoa percentage. Seek immediate emergency veterinary decontamination.',
    ),
    ToxicityItem(
      id: 'xylitol',
      name: 'Xylitol / Birch Sweetener',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs (Severe)',
      summary: 'Common in sugar-free gum, peanut butter, and baked goods. Triggers massive insulin release.',
      symptoms: 'Severe hypoglycemia (weakness, collapse, seizures) within 30-60 mins, acute hepatic (liver) failure.',
      firstAid: 'CRITICAL EMERGENCY! Rush to the nearest clinic immediately for IV dextrose infusion.',
    ),
    ToxicityItem(
      id: 'grapes',
      name: 'Grapes & Raisins',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Causes acute nephrotoxicity (kidney failure) even in small quantities.',
      symptoms: 'Vomiting, lethargy, anorexia, decreased urination (oliguria/anuria), acute renal shutdown.',
      firstAid: 'Urgent veterinary decontamination within 2 hours. Do not wait for symptoms to appear.',
    ),
    ToxicityItem(
      id: 'onions',
      name: 'Onions, Garlic, Leeks & Chives',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats (Cats High Risk)',
      summary: 'N-propyl disulfide oxidizes hemoglobin, causing Heinz body hemolytic anemia.',
      symptoms: 'Pale mucous membranes, dark red/brown urine, lethargy, elevated heart rate, collapse.',
      firstAid: 'Monitor mucous membrane color and oxygenation. Veterinary supportive care and bloodwork needed.',
    ),
    ToxicityItem(
      id: 'macadamia',
      name: 'Macadamia Nuts',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs',
      summary: 'Unique canine toxicity causing neuromuscular weakness and hyperthermia.',
      symptoms: 'Hind-limb ataxia, tremors, joint pain, vomiting, inability to stand.',
      firstAid: 'Veterinary observation, fluid therapy, and muscle relaxation support.',
    ),
    ToxicityItem(
      id: 'peanut_butter',
      name: 'Natural Peanut Butter (Xylitol-Free)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'High in protein and healthy fats. Safe in moderation as an occasional treat.',
      symptoms: 'None when fed in moderation. Check label carefully to verify zero xylitol/birch sugar.',
      firstAid: 'Ensure clean water is available. Feed no more than 1 tablespoon per day for medium dogs.',
    ),
    ToxicityItem(
      id: 'pumpkin',
      name: 'Pure Pumpkin Puree',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Excellent source of soluble fiber for digestive health and stool regulation.',
      symptoms: 'Safe and beneficial for digestive regularity.',
      firstAid: 'Use 100% pure pumpkin, NOT spiced pumpkin pie mix containing nutmeg/cinnamon.',
    ),
    ToxicityItem(
      id: 'cooked_chicken',
      name: 'Plain Boiled Chicken (Boneless)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Bland lean protein source ideal for recovering from gastrointestinal distress.',
      symptoms: 'Safe. Must be boneless and prepared without onions, garlic, or salt.',
      firstAid: 'Never feed cooked bones as they splinter and cause GI perforation.',
    ),

    // ── Plants & Botanicals ───────────────────────────────────────────────
    ToxicityItem(
      id: 'lilies',
      name: 'True Lilies (Easter, Tiger, Daylily)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Cats (FATAL)',
      summary: 'All parts of true lilies are acutely nephrotoxic to felines. Pollen ingestion via grooming is lethal.',
      symptoms: 'Vomiting, drooling, total kidney failure within 24-72 hours, anuria, death.',
      firstAid: 'ABSOLUTE EMERGENCY! Wash pollen from fur immediately and rush cat to emergency ICU for aggressive IV fluids.',
    ),
    ToxicityItem(
      id: 'sago_palm',
      name: 'Sago Palm (Cycas Revoluta)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains cycasin. Seeds contain the highest concentration of toxin.',
      symptoms: 'Vomiting, melena (black tarry stool), jaundice, hepatic necrosis, bleeding diathesis.',
      firstAid: 'Immediate clinical decontamination, plasma transfusions, and aggressive hepatoprotection.',
    ),
    ToxicityItem(
      id: 'monstera',
      name: 'Monstera Deliciosa / Swiss Cheese Plant',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains insoluble calcium oxalate crystals that pierce oral and esophageal tissues.',
      symptoms: 'Oral irritation, intense burning of lips/tongue, excessive drooling, difficulty swallowing.',
      firstAid: 'Rinse mouth with cool water or give milk/yogurt to bind oxalate crystals. Contact vet if swelling occurs.',
    ),
    ToxicityItem(
      id: 'aloe_vera',
      name: 'Aloe Vera (Outer Rind / Saponins)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains anthraquinones and saponins that cause severe intestinal cramping.',
      symptoms: 'Vomiting, diarrhea, lethargy, tremors, change in urine color.',
      firstAid: 'Withhold food for a short period and provide veterinary gastrointestinal protectants.',
    ),
    ToxicityItem(
      id: 'spider_plant',
      name: 'Spider Plant (Chlorophytum Comosum)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Non-toxic to pets. Mild playful effect in some felines.',
      symptoms: 'Non-toxic. Excessive chewing may cause mild transient stomach upset.',
      firstAid: 'Safe houseplant. Keep out of reach if pet overeats leaves.',
    ),

    // ── Medications ───────────────────────────────────────────────────────
    ToxicityItem(
      id: 'acetaminophen',
      name: 'Acetaminophen / Tylenol / Paracetamol',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Cats (Fatal) & Dogs',
      summary: 'Cats lack glucuronyl transferase. Converts hemoglobin into methemoglobin (cannot carry oxygen).',
      symptoms: 'Cyanosis (brownish-gray gums), hypothermia, facial edema, acute hepatic failure.',
      firstAid: 'CRITICAL EMERGENCY! Administer N-acetylcysteine (NAC) and oxygen therapy at emergency clinic immediately.',
    ),
    ToxicityItem(
      id: 'ibuprofen',
      name: 'Ibuprofen / Advil / NSAIDs',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Inhibits COX-1 prostaglandins, destroying gastric mucosal barrier and renal blood flow.',
      symptoms: 'Gastric ulcers, vomiting blood (hematemesis), acute renal failure, coma.',
      firstAid: 'Emergency decontamination, proton pump inhibitors, and fluid diuresis.',
    ),

    // ── Household Chemicals ───────────────────────────────────────────────
    ToxicityItem(
      id: 'antifreeze',
      name: 'Ethylene Glycol (Automotive Antifreeze)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Sweet-tasting, highly lethal coolant. Metabolized into oxalic acid crystals in kidneys.',
      symptoms: 'Stage 1: Drunken gait, ataxia, vomiting. Stage 2: Tachypnea. Stage 3: Irreversible renal necrosis.',
      firstAid: 'CRITICAL EMERGENCY! Fomepizole (4-MP) antidote must be administered within 3-8 hours to prevent fatal shutdown.',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ToxicityItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == ToxicityCategory.all ||
          item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.symptoms.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Toxicity & Food Safety Hub',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Ask AI Veterinarian',
            onPressed: () => context.push(RoutePaths.ownerAiChat),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search foods, plants, meds (e.g. Chocolate, Lilies)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.brPill,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  AppSpacing.vGapSm,

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All Items', ToxicityCategory.all),
                        _filterChip('Foods & Ingredients', ToxicityCategory.foods),
                        _filterChip('Plants & Flora', ToxicityCategory.plants),
                        _filterChip('Medications', ToxicityCategory.medications),
                        _filterChip('Chemicals', ToxicityCategory.chemicals),
                      ],
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // Count & Emergency Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${filtered.length} verified substances',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          '24/7 Clinical Reference',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,

                  // Items List
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: scheme.outline),
                          AppSpacing.vGapSm,
                          Text(
                            'No substances found for "$_searchQuery"',
                            style: context.textTheme.titleSmall?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Try searching another ingredient or ask our AI Veterinarian directly.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.vGapMd,
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '${RoutePaths.ownerAiChat}?prompt=${Uri.encodeComponent("Is $_searchQuery safe for pets?")}',
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Ask AI Veterinarian'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => AppSpacing.vGapSm,
                      itemBuilder: (context, index) {
                        return _ToxicityItemCard(item: filtered[index]);
                      },
                    ),
                  AppSpacing.vGapXxl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, ToxicityCategory category) {
    final isSelected = _selectedCategory == category;
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? scheme.onPrimary : scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
      ),
    );
  }
}

class _ToxicityItemCard extends StatefulWidget {
  const _ToxicityItemCard({required this.item});

  final ToxicityItem item;

  @override
  State<_ToxicityItemCard> createState() => _ToxicityItemCardState();
}

class _ToxicityItemCardState extends State<_ToxicityItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final item = widget.item;

    final (badgeBg, badgeFg, badgeText, badgeIcon) = switch (item.level) {
      ToxicityLevel.toxic => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        'TOXIC / HAZARDOUS',
        Icons.warning_amber_rounded,
      ),
      ToxicityLevel.caution => (
        Colors.amber.shade100,
        Colors.amber.shade900,
        'CAUTION / MODERATE',
        Icons.info_outline_rounded,
      ),
      ToxicityLevel.safe => (
        Colors.green.shade100,
        Colors.green.shade900,
        'SAFE IN MODERATION',
        Icons.check_circle_outline_rounded,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.level == ToxicityLevel.toxic
              ? scheme.error.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badgeIcon, color: badgeFg, size: 20),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: AppRadius.brPill,
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeFg,
                                ),
                              ),
                            ),
                            Text(
                              item.targetSpecies,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.summary,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    context,
                    title: 'Clinical Symptoms & Presentation',
                    content: item.symptoms,
                    icon: Icons.monitor_heart_outlined,
                    iconColor: item.level == ToxicityLevel.toxic ? scheme.error : scheme.primary,
                  ),
                  AppSpacing.vGapSm,
                  _detailRow(
                    context,
                    title: 'Emergency First-Aid & Protocol',
                    content: item.firstAid,
                    icon: Icons.medical_services_outlined,
                    iconColor: Colors.teal,
                  ),
                  AppSpacing.vGapSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '${RoutePaths.ownerAiChat}?prompt=${Uri.encodeComponent("Tell me more about ${item.name} toxicity symptoms and emergency treatment for my pet")}',
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: const Text('Ask AI Context'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    final scheme = context.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        AppSpacing.hGapXs,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
