import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Community Events** screen connecting pet owners with local meetups,
/// veterinary health clinics, and educational training workshops.
class CommunityEventsScreen extends ConsumerStatefulWidget {
  const CommunityEventsScreen({super.key});

  @override
  ConsumerState<CommunityEventsScreen> createState() =>
      _CommunityEventsScreenState();
}

class _CommunityEventsScreenState extends ConsumerState<CommunityEventsScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'Nearby';
  final Set<String> _registeredEventIds = {'event-1'};
  final Set<String> _reminderEventIds = {};

  final List<String> _categories = const [
    'Nearby',
    'This Week',
    'Health',
    'Workshops',
  ];

  final List<_CommunityEventItem> _events = const [
    _CommunityEventItem(
      id: 'event-1',
      dateMonth: 'OCT',
      dateDay: '15',
      timeString: 'Sat, 10:00 AM',
      category: 'Health',
      categoryType: 'Clinic',
      distance: '2.5 km away',
      title: 'Community Wellness & Vaccine Clinic',
      description:
          'Subsidized core vaccines, microchipping, and wellness checks for registered community pets. Walk-ins welcome.',
      price: 'Free / Subsidized',
      location: 'Central Veterinary Center',
    ),
    _CommunityEventItem(
      id: 'event-2',
      dateMonth: 'OCT',
      dateDay: '18',
      timeString: 'Tue, 5:30 PM',
      category: 'Workshops',
      categoryType: 'Workshop',
      distance: '5.0 km away',
      title: 'Basic Leash & Agility Training',
      description:
          'A beginner-friendly session for leash manners, recall commands, and agility obstacle confidence.',
      price: 'Free',
      location: 'Riverside Community Park',
    ),
    _CommunityEventItem(
      id: 'event-3',
      dateMonth: 'OCT',
      dateDay: '22',
      timeString: 'Sat, 9:00 AM',
      category: 'This Week',
      categoryType: 'Meetup',
      distance: '1.8 km away',
      title: 'Morning Socialization Pack Walk',
      description:
          'Structured group walk with certified trainers to foster calm leash interactions and exercise.',
      price: 'Free',
      location: 'Greenwood Trail Entrance',
    ),
    _CommunityEventItem(
      id: 'event-4',
      dateMonth: 'OCT',
      dateDay: '28',
      timeString: 'Fri, 6:00 PM',
      category: 'Health',
      categoryType: 'Seminar',
      distance: '3.2 km away',
      title: 'Pet Nutrition & Raw Diet Essentials',
      description:
          'Learn how to balance proteins, supplements, and manage common food sensitivities in companion pets.',
      price: 'Free',
      location: 'PetConnect Education Hall',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);

    final filteredEvents = _events.where((event) {
      if (_selectedCategory == 'Health' && event.category != 'Health') return false;
      if (_selectedCategory == 'Workshops' && event.category != 'Workshops') return false;
      if (_selectedCategory == 'This Week' && event.category != 'This Week' && event.id != 'event-1') return false;
      return true;
    }).toList();

    final petName = selectedPet?.name ?? 'your companion';
    final isCat = selectedPet?.species.toLowerCase() == 'cat';

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Community Events',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_registeredEventIds.length}'),
              isLabelVisible: _registeredEventIds.isNotEmpty,
              child: const Icon(Icons.calendar_month),
            ),
            tooltip: 'My Registered Events',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_registeredEventIds.length} events registered on your schedule'),
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subtitle ───────────────────────────────────────
                Text(
                  'Discover local meetups, educational workshops, and health clinics.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
                Row(
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
                          if (selected) {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Recommended Event Hero Card ────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'AI Recommendation for $petName',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text('Sat, 10:00 AM'),
                            backgroundColor: scheme.primaryContainer,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        isCat
                            ? 'Feline Enrichment & Wellness Clinic'
                            : 'Weekend Socialization & Health Workshop',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        isCat
                            ? 'Join local feline specialists for tips on indoor enrichment, nail trims, and nutrition for $petName.'
                            : 'Join nearby pet owners for socialization tips, leash skills, and healthy habits tailored for $petName.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          AppButton.filled(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_registeredEventIds.contains('hero-event')) {
                                  _registeredEventIds.remove('hero-event');
                                } else {
                                  _registeredEventIds.add('hero-event');
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _registeredEventIds.contains('hero-event')
                                        ? 'Registered $petName for the workshop!'
                                        : 'Registration cancelled.',
                                  ),
                                ),
                              );
                            },
                            size: AppButtonSize.small,
                            child: Text(
                              _registeredEventIds.contains('hero-event')
                                  ? 'Registered ✓'
                                  : 'Register Now',
                            ),
                          ),
                          AppSpacing.hGapSm,
                          IconButton(
                            icon: Icon(
                              _reminderEventIds.contains('hero-event')
                                  ? Icons.notifications_active
                                  : Icons.notifications_none,
                              color: _reminderEventIds.contains('hero-event')
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            tooltip: 'Set Event Reminder',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_reminderEventIds.contains('hero-event')) {
                                  _reminderEventIds.remove('hero-event');
                                } else {
                                  _reminderEventIds.add('hero-event');
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _reminderEventIds.contains('hero-event')
                                        ? 'Calendar reminder set!'
                                        : 'Reminder removed.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Upcoming Events List ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Local Events',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      '${filteredEvents.length} Events',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                if (filteredEvents.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No events found in this category.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  for (final event in filteredEvents) ...[
                    _buildEventCard(context, event),
                    AppSpacing.vGapMd,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, _CommunityEventItem event) {
    final scheme = context.colorScheme;
    final isRegistered = _registeredEventIds.contains(event.id);
    final hasReminder = _reminderEventIds.contains(event.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      event.dateMonth,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.dateDay,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${event.categoryType} • ${event.distance}',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.price,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      event.title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      event.description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            hasReminder ? Icons.notifications_active : Icons.notifications_none,
                            size: 18,
                            color: hasReminder ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          tooltip: 'Reminder',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (hasReminder) {
                                _reminderEventIds.remove(event.id);
                              } else {
                                _reminderEventIds.add(event.id);
                              }
                            });
                          },
                        ),
                        AppButton.filled(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isRegistered) {
                                _registeredEventIds.remove(event.id);
                              } else {
                                _registeredEventIds.add(event.id);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  !isRegistered
                                      ? 'Registered for ${event.title}!'
                                      : 'Cancelled registration.',
                                ),
                              ),
                            );
                          },
                          size: AppButtonSize.small,
                          child: Text(isRegistered ? 'Registered ✓' : 'Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityEventItem {
  const _CommunityEventItem({
    required this.id,
    required this.dateMonth,
    required this.dateDay,
    required this.timeString,
    required this.category,
    required this.categoryType,
    required this.distance,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
  });

  final String id;
  final String dateMonth;
  final String dateDay;
  final String timeString;
  final String category;
  final String categoryType;
  final String distance;
  final String title;
  final String description;
  final String price;
  final String location;
}
