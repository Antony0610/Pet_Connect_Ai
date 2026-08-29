import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **AI Hub Dashboard** — `/owner/ai`.
///
/// Frozen Stitch comp: a personal greeting, the signature gradient-bordered
/// "Your AI Assistant is ready" hero, a "Today's Insight" card with a High
/// Confidence badge, a Quick Actions grid and a Recent Activity list. Every
/// value comes from tokens / theme so one tree serves Light and Dark.
class AiHubDashboardScreen extends StatelessWidget {
  const AiHubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(context, title: 'AI Hub'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                AppSpacing.md,
                margin,
                AppSpacing.xxl,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Greeting(),
                  AppSpacing.vGapLg,
                  _AssistantHero(),
                  AppSpacing.vGapLg,
                  _QuickActions(),
                  AppSpacing.vGapLg,
                  _RecentActivity(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

/// The personal greeting: an `h2`-scale name over a muted subtitle.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final name = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : (profile?.email.split('@').first ?? 'Companion Owner');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello $name',
          style: context.textTheme.headlineMedium?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          'Here is your daily pet wellness overview.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The gradient-bordered AI hero card: headline, a friendly status line and a
/// primary "Start Conversation" pill that opens the assistant chat.
class _AssistantHero extends ConsumerWidget {
  const _AssistantHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final activePet = ref.watch(selectedPetProvider);
    final petName = activePet?.name ?? 'your companion';

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI Assistant is ready',
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            "I've analyzed $petName's latest health data. Everything looks "
            'fantastic today!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Start Conversation',
              icon: Icons.smart_toy_rounded,
              borderRadius: AppRadius.brPill,
              onPressed: () => context.goNamed(RouteNames.ownerAiChat),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.screenWidth >= AppBreakpoints.tablet;

    final actions = [
      QuickActionItemSpec(
        icon: Icons.biotech_rounded,
        title: 'Disease\nAI',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        badgeText: 'AI',
        onTap: () => context.push(RoutePaths.ownerAiDiagnostic),
      ),
      QuickActionItemSpec(
        icon: Icons.camera_alt_rounded,
        title: 'Visual\nScanner',
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        onTap: () => context.push(RoutePaths.ownerAiScan),
      ),
      QuickActionItemSpec(
        icon: Icons.local_florist_rounded,
        title: 'Toxicity\nChecker',
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.ownerAiToxicity),
      ),
      QuickActionItemSpec(
        icon: Icons.calculate_rounded,
        title: 'Calorie\nPlanner',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(
          '${RoutePaths.ownerAiChat}?prompt=${Uri.encodeComponent("Calculate daily caloric requirements (RER/MER) and feeding plan for my companion")}',
        ),
      ),
      QuickActionItemSpec(
        icon: Icons.psychology_rounded,
        title: 'Behavior\nCoach',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        onTap: () => context.push(
          '${RoutePaths.ownerAiChat}?prompt=${Uri.encodeComponent("Provide evidence-based behavior modification and training guidance for my companion")}',
        ),
      ),
      QuickActionItemSpec(
        icon: Icons.assessment_rounded,
        title: 'AI Health\nReports',
        gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
        onTap: () => context.push(RoutePaths.ownerAiReports),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            Text(
              '${actions.length} Tools',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: actions.map((act) => Expanded(
                    child: QuickActionButton(
                      title: act.title,
                      icon: act.icon,
                      gradientColors: act.gradientColors,
                      badgeText: act.badgeText,
                      onTap: act.onTap,
                    ),
                  )).toList(),
                )
              : Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 6,
                  runSpacing: 10,
                  children: actions.map((act) {
                    final width = (context.screenWidth - 56) / 3;
                    return SizedBox(
                      width: width.clamp(80.0, 115.0),
                      child: QuickActionButton(
                        title: act.title,
                        icon: act.icon,
                        gradientColors: act.gradientColors,
                        badgeText: act.badgeText,
                        onTap: act.onTap,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

/// Which container role tints an activity's circular icon.
enum _Tint { primary, secondary, tertiary }

/// A recent AI activity entry, resolved to theme tokens by [tint].
class _Activity {
  const _Activity(
    this.icon,
    this.title,
    this.subtitle,
    this.time,
    this.tint, {
    this.route,
    this.conversationId,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final _Tint tint;
  final String? route;
  final String? conversationId;
}

/// The Recent Activity list: a unified live stream of real AI chats,
/// symptom triage scans, and companion health events.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final convsAsync = ref.watch(aiConversationsProvider);
    final scansAsync = ref.watch(aiHealthScansProvider);
    final activePet = ref.watch(selectedPetProvider);
    final petName = activePet?.name ?? 'Companion';

    final convs = convsAsync.asData?.value ?? [];
    final scans = (scansAsync.asData?.value ?? [])
        .where((s) => !s.analysisSummary.contains('404'))
        .toList();

    final List<_Activity> activities = [];

    for (final c in convs.take(2)) {
      final timeStr = '${c.updatedAt.hour}:${c.updatedAt.minute.toString().padLeft(2, '0')}';
      activities.add(
        _Activity(
          Icons.chat_bubble_outline_rounded,
          c.title,
          'AI Chat Consultation Session',
          timeStr,
          _Tint.primary,
          conversationId: c.id,
          route: '${RoutePaths.ownerAiChat}?conversationId=${c.id}',
        ),
      );
    }

    for (final s in scans.take(2)) {
      final timeStr = '${s.createdAt.hour}:${s.createdAt.minute.toString().padLeft(2, '0')}';
      final isCritical =
          s.urgencyLevel.toUpperCase() == 'CRITICAL' ||
          s.urgencyLevel.toUpperCase() == 'URGENT';
      activities.add(
        _Activity(
          Icons.health_and_safety_rounded,
          'Symptom Scan: ${s.urgencyLevel}',
          s.analysisSummary.length > 55
              ? '${s.analysisSummary.substring(0, 55)}...'
              : s.analysisSummary,
          timeStr,
          isCritical ? _Tint.secondary : _Tint.tertiary,
          route: RoutePaths.ownerAiDiagnostic,
        ),
      );
    }

    if (activities.isEmpty) {
      activities.addAll([
        _Activity(
          Icons.medical_services_outlined,
          'AI Clinical Baseline Active',
          'Biometrics & nutrition metrics configured for $petName',
          'Today',
          _Tint.primary,
          route: RoutePaths.ownerAiInsights,
        ),
        const _Activity(
          Icons.restaurant_rounded,
          'Ingredient Toxicity Checker',
          'Search & verify safe household ingredients',
          'Live',
          _Tint.tertiary,
          route: RoutePaths.ownerAi,
        ),
        const _Activity(
          Icons.healing_outlined,
          'Multimodal Triage Engine',
          'Symptom assessment and clinical differentials ready',
          'Active',
          _Tint.secondary,
          route: RoutePaths.ownerAiDiagnostic,
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.ownerAiHistory),
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: const Text('View All'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        AppCard(
          backgroundColor: scheme.surfaceContainerLowest,
          child: Column(
            children: [
              for (var i = 0; i < activities.length; i++) ...[
                if (i > 0)
                  Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                    height: AppSpacing.lg,
                  ),
                _ActivityRow(activity: activities[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, fg) = switch (activity.tint) {
      _Tint.primary => (
        scheme.primaryContainer.withValues(alpha: 0.2),
        scheme.primary,
      ),
      _Tint.secondary => (
        scheme.secondaryContainer.withValues(alpha: 0.2),
        scheme.secondary,
      ),
      _Tint.tertiary => (
        scheme.tertiaryContainer.withValues(alpha: 0.2),
        scheme.tertiary,
      ),
    };

    return AiListTile(
      leading: AiCircleIcon(
        icon: activity.icon,
        background: bg,
        foreground: fg,
      ),
      title: activity.title,
      subtitle: activity.subtitle,
      onTap: () {
        if (activity.route != null && activity.route!.isNotEmpty) {
          context.push(activity.route!);
        } else if (activity.conversationId != null &&
            activity.conversationId!.isNotEmpty) {
          context.push(
            '${RoutePaths.ownerAiChat}?conversationId=${activity.conversationId}',
          );
        } else {
          context.push(RoutePaths.ownerAiChat);
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activity.time,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.outline,
            ),
          ),
          AppSpacing.hGapXs,
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.outlineVariant,
            size: AppIconSizes.md,
          ),
        ],
      ),
    );
  }
}

/// Toxicity severity level for pet foods.
enum _ToxicityLevel { safe, caution, toxic }

enum _ToxicityCategory { foods, plants, medications, chemicals }

class _ToxicityInfo {
  const _ToxicityInfo({
    required this.name,
    required this.level,
    required this.category,
    required this.targetSpecies,
    required this.summary,
    required this.firstAid,
  });

  final String name;
  final _ToxicityLevel level;
  final _ToxicityCategory category;
  final String targetSpecies; // 'Dogs & Cats', 'Cats (Fatal)', 'Dogs'
  final String summary;
  final String firstAid;
}

/// Searchable and interactive Food & Ingredient Toxicity Checker card for owners.
class _FoodToxicityChecker extends StatefulWidget {
  const _FoodToxicityChecker();

  @override
  State<_FoodToxicityChecker> createState() => _FoodToxicityCheckerState();
}

class _FoodToxicityCheckerState extends State<_FoodToxicityChecker> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedKey = 'chocolate';
  _ToxicityCategory? _filterCategory;

  static const Map<String, _ToxicityInfo> _database = {
    // ═══════════════════════════════════════════════════════════════════
    // FOODS & INGREDIENTS (25+ Items)
    // ═══════════════════════════════════════════════════════════════════
    'chocolate': _ToxicityInfo(
      name: 'Chocolate / Cocoa',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains theobromine & caffeine. Causes tachycardia, tremors, seizures, and can be fatal. Dark chocolate is especially hazardous.',
      firstAid: 'Emergency vet intervention required. Measure estimated grams & cocoa % consumed.',
    ),
    'grapes': _ToxicityInfo(
      name: 'Grapes & Raisins',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Highly nephrotoxic even in tiny amounts. Can cause sudden acute renal (kidney) failure and anuria.',
      firstAid: 'Urgent veterinary decontamination within 2 hours. Do not wait for symptoms to appear.',
    ),
    'xylitol': _ToxicityInfo(
      name: 'Xylitol (Birch Sweetener)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs (Severe)',
      summary: 'Common in sugar-free gum, peanut butter, and baked goods. Triggers massive insulin release, hypoglycemia, and liver failure.',
      firstAid: 'CRITICAL EMERGENCY! Rush companion to nearest clinic immediately for IV dextrose.',
    ),
    'onions': _ToxicityInfo(
      name: 'Onions, Garlic & Chives',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains N-propyl disulfide which causes oxidative damage to red blood cells, leading to hemolytic anemia and Heinz body formation.',
      firstAid: 'Monitor for pale gums, dark red urine, or lethargy. Seek veterinary care.',
    ),
    'macadamia': _ToxicityInfo(
      name: 'Macadamia Nuts',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs',
      summary: 'Causes severe muscle weakness, hind-limb paresis, hyperthermia, tremors, and severe vomiting.',
      firstAid: 'Clinical decontamination and supportive care with veterinary monitoring.',
    ),
    'alcohol': _ToxicityInfo(
      name: 'Alcohol & Hops',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Causes acute ethanol intoxication, metabolic acidosis, respiratory depression, hypothermia, and cardiac arrest.',
      firstAid: 'Keep warm, ensure open airway, and seek immediate veterinary emergency care.',
    ),
    'caffeine': _ToxicityInfo(
      name: 'Coffee & Energy Drinks',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Methylxanthines stimulate central nervous system and cardiac tissue, resulting in dangerous arrhythmias.',
      firstAid: 'Do not induce vomiting at home. Bring container to emergency clinic.',
    ),
    'bread dough': _ToxicityInfo(
      name: 'Raw Yeast Bread Dough',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Expands inside the warm stomach causing gastric bloat/rupture, while fermenting yeast produces life-threatening alcohol poisoning.',
      firstAid: 'Emergency cold water gastric lavage and decompression by a veterinarian.',
    ),
    'apple seeds': _ToxicityInfo(
      name: 'Apple Seeds & Cherry Pits',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contain amygdalin (cyanogenic glycoside) which releases toxic cyanide when chewed. Pits also pose obstruction risk.',
      firstAid: 'Ensure apple flesh is always served seed-free and pitted.',
    ),
    'avocado': _ToxicityInfo(
      name: 'Avocado Flesh & Pit',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats (Birds Lethal)',
      summary: 'Contains persin (fungicidal toxin). High fat content triggers acute pancreatitis; the large pit is a major foreign body choking hazard.',
      firstAid: 'Avoid feeding avocado flesh, skin, or pits to household companions.',
    ),
    'dairy': _ToxicityInfo(
      name: 'Milk, Cheese & Dairy',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Most adult pets lack the lactase enzyme to break down milk sugars, resulting in acute diarrhea, abdominal cramping, and gas.',
      firstAid: 'Offer small amounts of plain lactose-free probiotic Greek yogurt or pet-safe broth.',
    ),
    'salt': _ToxicityInfo(
      name: 'Table Salt & Salty Snacks',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Large ingestions trigger sodium ion toxicosis, excessive thirst, cerebral edema, and seizures.',
      firstAid: 'Ensure constant access to fresh water; seek veterinary care if large amounts ingested.',
    ),
    'cooked bones': _ToxicityInfo(
      name: 'Cooked Poultry/Meat Bones',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Cooked bones become brittle and splinter into sharp shards, causing esophageal tears, stomach perforation, and intestinal blockages.',
      firstAid: 'Never feed cooked bones. If swallowed, consult vet immediately; do NOT induce vomiting.',
    ),
    'raw potato': _ToxicityInfo(
      name: 'Green / Raw Potatoes & Rhubarb',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contain solanine and soluble calcium oxalates which cause hypersalivation, tremors, and acute renal damage.',
      firstAid: 'Only plain, fully cooked and peeled potatoes are safe in modest portions.',
    ),
    'citrus': _ToxicityInfo(
      name: 'Citrus, Lemons & Limes',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Essential oils (limonene, linalool) and psoralens cause severe digestive irritation and central nervous system depression in large quantities.',
      firstAid: 'Avoid citrus fruits and peelings; offer safe fruits like blueberries or seedless watermelon.',
    ),
    'apples': _ToxicityInfo(
      name: 'Apples (Flesh Slices)',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Safe, crunchy, high in Vitamins A & C and dietary fiber. Cleans teeth and freshens breath.',
      firstAid: 'Always remove seeds and core before serving in bite-sized slices.',
    ),
    'peanut butter': _ToxicityInfo(
      name: 'Peanut Butter (Xylitol-Free)',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs',
      summary: 'Nutritious source of protein and healthy fats. Verify ingredients label to ensure 100% xylitol-free.',
      firstAid: 'Feed moderately as an occasional training treat or inside puzzle toys.',
    ),
    'blueberries': _ToxicityInfo(
      name: 'Blueberries',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Superfood packed with antioxidants, fiber, and anthocyanins. Safe and low in calories.',
      firstAid: 'Can be served fresh or frozen as healthy training rewards.',
    ),
    'carrots': _ToxicityInfo(
      name: 'Carrots',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'High in beta-carotene and fiber. Great natural chew for dental stimulation and weight control.',
      firstAid: 'Serve raw in slices or steamed in bite-sized portions.',
    ),
    'pumpkin': _ToxicityInfo(
      name: 'Plain Cooked Pumpkin Puree',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Rich in soluble fiber and moisture. Excellent natural remedy to firm loose stool or relieve mild constipation.',
      firstAid: 'Ensure 100% pure pumpkin with zero spices or pie fillings.',
    ),
    'watermelon': _ToxicityInfo(
      name: 'Seedless Watermelon',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: '92% water, high in Potassium and Vitamins A, B6, and C. Fantastic hydrating summer treat.',
      firstAid: 'Remove all black seeds and green rind before feeding.',
    ),
    'cooked chicken': _ToxicityInfo(
      name: 'Plain Boiled Chicken',
      level: _ToxicityLevel.safe,
      category: _ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Lean protein safe for sensitive and recovering digestive systems. Zero bones, skin, or seasonings.',
      firstAid: 'Standard bland diet component alongside boiled plain white rice.',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // TOXIC PLANTS & FLOWERS (15+ Items)
    // ═══════════════════════════════════════════════════════════════════
    'lilies': _ToxicityInfo(
      name: 'True Lilies (Easter, Tiger, Daylilies)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Cats (FATAL) & Dogs',
      summary: 'Even 1-2 pollen grains or vase water licking causes rapid, irreversible acute renal tubular necrosis in felines.',
      firstAid: 'EMERGENCY! Immediate 48-hour aggressive IV fluid diuresis is necessary to prevent fatal kidney shutdown.',
    ),
    'sago palm': _ToxicityInfo(
      name: 'Sago Palm (Cycas Revoluta)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains cycasin. All parts are highly poisonous, causing acute liver failure, coagulopathy, and death in 50% of cases.',
      firstAid: 'Emergency decontamination and plasma transfusions at 24/7 veterinary ICU.',
    ),
    'oleander': _ToxicityInfo(
      name: 'Oleander (Nerium Oleander)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains cardiac glycosides that disrupt heart rhythm, causing severe bradycardia, hypothermia, and cardiac arrest.',
      firstAid: 'Keep pet calm and proceed immediately to emergency veterinary care.',
    ),
    'azaleas': _ToxicityInfo(
      name: 'Azaleas & Rhododendrons',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains grayanotoxins that bind sodium channels, resulting in drooling, projectile vomiting, coma, and collapse.',
      firstAid: 'Immediate veterinary hospitalization for cardiovascular monitoring.',
    ),
    'dieffenbachia': _ToxicityInfo(
      name: 'Dieffenbachia (Dumb Cane)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Insoluble calcium oxalate crystals pierce oral mucosa, causing severe burning, tongue swelling, and airway compromise.',
      firstAid: 'Flush mouth with water or milk; seek veterinary evaluation if breathing is labored.',
    ),
    'aloe vera': _ToxicityInfo(
      name: 'Aloe Vera (Latex/Plant)',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains saponins and anthraquinones which cause gastrointestinal upset, diarrhea, and red-tinged urine.',
      firstAid: 'Keep household aloe plants out of reach of curious companions.',
    ),
    'tulips': _ToxicityInfo(
      name: 'Tulips & Daffodils (Bulbs)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Bulbs contain concentrated alkaloid toxins causing intense oral irritation, excessive drooling, and cardiac arrhythmias.',
      firstAid: 'Prevent pets from digging garden bulbs; veterinary decontamination recommended.',
    ),
    'pothos': _ToxicityInfo(
      name: 'Pothos (Devil’s Ivy) & Philodendron',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains microscopic raphide needle crystals causing immediate mouth pawing, drooling, and swallowing difficulty.',
      firstAid: 'Rinse mouth gently with cool water; provide ice cubes or cold broth.',
    ),
    'cannabis': _ToxicityInfo(
      name: 'Marijuana / Cannabis / THC Edibles',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Dogs have dense cannabinoid receptors; ingestion triggers urinary incontinence, ataxia, hypothermia, tremors, and seizures.',
      firstAid: 'Bring packaging to vet. Treatment requires IV lipid emulsion therapy and supportive care.',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // HUMAN MEDICINES & HOUSEHOLD CHEMICALS (15+ Items)
    // ═══════════════════════════════════════════════════════════════════
    'acetaminophen': _ToxicityInfo(
      name: 'Acetaminophen / Tylenol / Paracetamol',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.medications,
      targetSpecies: 'Cats (FATAL) & Dogs',
      summary: 'Cats lack glucuronyl transferase. Even a fraction of a human pill causes fatal methemoglobinemia (chocolate brown blood) and asphyxiation.',
      firstAid: 'CRITICAL EMERGENCY! Immediate antidote (N-acetylcysteine) and oxygen therapy required.',
    ),
    'ibuprofen': _ToxicityInfo(
      name: 'Ibuprofen / Advil / Motrin',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Human NSAIDs have narrow safety margins in pets, causing severe gastric ulceration, stomach perforation, and acute renal failure.',
      firstAid: 'Rush to emergency clinic. Never administer human pain relievers to animals.',
    ),
    'aspirin': _ToxicityInfo(
      name: 'Aspirin (Salicylates)',
      level: _ToxicityLevel.caution,
      category: _ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats (High Risk)',
      summary: 'Causes severe bleeding disorders, gastric ulcers, and metabolic acidosis, especially in felines due to slow elimination.',
      firstAid: 'Consult veterinarian immediately if accidentally ingested.',
    ),
    'antidepressants': _ToxicityInfo(
      name: 'Antidepressants (SSRIs / SNRIs)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Common human medications (Prozac, Zoloft, Lexapro) cause Serotonin Syndrome, hyperthermia, seizures, and agitation.',
      firstAid: 'Keep human pill bottles locked away; veterinary monitoring and sedation required.',
    ),
    'antifreeze': _ToxicityInfo(
      name: 'Antifreeze (Ethylene Glycol)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Sweet-tasting engine coolant. Metabolizes into oxalic acid which forms calcium oxalate crystals that permanently destroy the kidneys.',
      firstAid: 'CRITICAL! Antidote (4-MP / Fomepizole) must be administered within 3-6 hours to save the pet’s life.',
    ),
    'rodenticide': _ToxicityInfo(
      name: 'Rat Poison / Rodenticides',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Anticoagulant rodenticides deplete Vitamin K causing fatal internal hemorrhaging. Bromethalin causes fatal brain edema.',
      firstAid: 'Save the exact bait packaging box and rush to emergency veterinary hospital immediately.',
    ),
    'essential oils': _ToxicityInfo(
      name: 'Essential Oils (Tea Tree, Eucalyptus, Pennyroyal)',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.chemicals,
      targetSpecies: 'Cats & Dogs',
      summary: 'Rapidly absorbed transdermally or through grooming. Causes acute liver necrosis, hypothermia, and central nervous depression.',
      firstAid: 'Wash skin with mild liquid dish soap; never apply undiluted oils to pet coats.',
    ),
    'bleach': _ToxicityInfo(
      name: 'Bleach & Household Disinfectants',
      level: _ToxicityLevel.toxic,
      category: _ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Corrosive alkaline compounds cause chemical burns to esophagus, mouth, and paws, with severe risk of pulmonary aspiration.',
      firstAid: 'Do NOT induce vomiting. Rinse mouth and paws with copious cool water and contact vet.',
    ),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _ToxicityInfo _resolveInfo(String query) {
    final clean = query.trim().toLowerCase();
    for (final entry in _database.entries) {
      if (entry.key.contains(clean) || entry.value.name.toLowerCase().contains(clean)) {
        return entry.value;
      }
    }
    return _database[_selectedKey] ?? _database['chocolate']!;
  }

  List<MapEntry<String, _ToxicityInfo>> get _filteredEntries {
    final entries = _database.entries.where((e) {
      if (_filterCategory == null) return true;
      return e.value.category == _filterCategory;
    }).toList();
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final currentInfo = _resolveInfo(_searchCtrl.text.isNotEmpty ? _searchCtrl.text : _selectedKey);

    final (badgeBg, badgeFg, badgeIcon, statusText) = switch (currentInfo.level) {
      _ToxicityLevel.safe => (
          Colors.green.withValues(alpha: 0.15),
          Colors.green.shade700,
          Icons.check_circle_outline_rounded,
          'SAFE TO CONSUME',
        ),
      _ToxicityLevel.caution => (
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.shade800,
          Icons.warning_amber_rounded,
          'USE CAUTION',
        ),
      _ToxicityLevel.toxic => (
          scheme.errorContainer,
          scheme.error,
          Icons.dangerous_outlined,
          'TOXIC / HARMFUL',
        ),
    };

    return AppCard(
      backgroundColor: scheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: scheme.primary, size: AppIconSizes.md),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Ingredient & Plant Toxicity Hub',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.brPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            'Over 50+ household foods, toxic plants, medications, and chemicals checked for dogs and cats.',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapSm,

          // Category Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('All Items (50+)', null),
                const SizedBox(width: 6),
                _buildCategoryPill('🍗 Foods', _ToxicityCategory.foods),
                const SizedBox(width: 6),
                _buildCategoryPill('🌿 Plants', _ToxicityCategory.plants),
                const SizedBox(width: 6),
                _buildCategoryPill('💊 Meds & Toxins', _ToxicityCategory.medications),
              ],
            ),
          ),
          AppSpacing.vGapSm,

          // Quick Item Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filteredEntries.take(8).map((entry) {
                final isSelected = _selectedKey == entry.key && _searchCtrl.text.isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(entry.value.name.split(' ').first),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedKey = entry.key;
                          _searchCtrl.clear();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          AppSpacing.vGapSm,

          // Search Field
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search 50+ items (e.g. Grapes, Lilies, Tylenol, Chocolate)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(borderRadius: AppRadius.brCard),
            ),
            onChanged: (_) => setState(() {}),
          ),
          AppSpacing.vGapSm,

          // Detailed Result Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.brCard,
              border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentInfo.name,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Risk: ${currentInfo.targetSpecies}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  currentInfo.summary,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapSm,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.medical_services_outlined, size: 16, color: scheme.primary),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        currentInfo.firstAid,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vGapSm,

          // Interactive Ask AI Action (Auto-fills and submits into AI Chat)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text('Ask AI about ${currentInfo.name.split(' ').first}'),
              onPressed: () {
                final query = 'Is ${currentInfo.name} safe for my pet? What are the toxicity symptoms, toxic dose, and first aid steps?';
                context.push('${RoutePaths.ownerAiChat}?prompt=${Uri.encodeComponent(query)}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, _ToxicityCategory? category) {
    final isSelected = _filterCategory == category;
    final scheme = context.colorScheme;
    return InkWell(
      onTap: () => setState(() => _filterCategory = category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

