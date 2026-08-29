import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Community Events** hub connecting pet owners with local meetups,
/// veterinary health clinics, agility workshops, and live meetup hosting.
class CommunityEventsScreen extends ConsumerStatefulWidget {
  const CommunityEventsScreen({super.key});

  @override
  ConsumerState<CommunityEventsScreen> createState() =>
      _CommunityEventsScreenState();
}

class _CommunityEventsScreenState extends ConsumerState<CommunityEventsScreen> {
  static const double _maxContentWidth = 1000;
  static const String _regStorageKey = 'community_events_registered_ids_v2';
  static const String _remStorageKey = 'community_events_reminder_ids_v2';
  static const String _customEventsKey = 'community_events_custom_items_v2';

  String _selectedCategory = 'All';
  Set<String> _registeredEventIds = {};
  Set<String> _reminderEventIds = {};
  List<_CommunityEventItem> _customEvents = [];

  final List<String> _categories = const [
    'All',
    'Nearby',
    'This Week',
    'Health',
    'Workshops',
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    final prefs = ref.read(sharedPreferencesProvider);
    final reg = prefs.getStringList(_regStorageKey) ?? [];
    final rem = prefs.getStringList(_remStorageKey) ?? [];
    final rawCustom = prefs.getString(_customEventsKey);

    List<_CommunityEventItem> loaded = [];
    if (rawCustom != null && rawCustom.isNotEmpty) {
      try {
        final list = (jsonDecode(rawCustom) as List<dynamic>)
            .map((j) => _CommunityEventItem.fromJson(j as Map<String, dynamic>))
            .toList();
        loaded = list;
      } catch (_) {}
    }

    setState(() {
      _registeredEventIds = reg.toSet();
      _reminderEventIds = rem.toSet();
      _customEvents = loaded;
    });
  }

  Future<void> _saveRegistrations() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_regStorageKey, _registeredEventIds.toList());
  }

  Future<void> _saveReminders() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_remStorageKey, _reminderEventIds.toList());
  }

  Future<void> _addCustomEvent(_CommunityEventItem event) async {
    final updated = [event, ..._customEvents];
    setState(() => _customEvents = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _customEventsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  void _openHostEventDialog() {
    HapticFeedback.lightImpact();
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Cubbon Park Dog Park, Bengaluru');
    final descCtrl = TextEditingController();
    DateTime eventDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay eventTime = const TimeOfDay(hour: 10, minute: 0);
    String category = 'Meetup';
    String price = 'Free';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.event_available_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text('Host Community Meetup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event / Meetup Title *',
                    hintText: 'e.g. Weekend Indie Paws Playdate',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Meetup', child: Text('Meetup')),
                          DropdownMenuItem(value: 'Clinic', child: Text('Health Clinic')),
                          DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                          DropdownMenuItem(value: 'Seminar', child: Text('Seminar')),
                        ],
                        onChanged: (v) => setDlgState(() => category = v ?? 'Meetup'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: price,
                        decoration: const InputDecoration(
                          labelText: 'Admission',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Free', child: Text('Free')),
                          DropdownMenuItem(value: 'Subsidized', child: Text('Subsidized')),
                          DropdownMenuItem(value: '₹200 Entry', child: Text('₹200 Entry')),
                        ],
                        onChanged: (v) => setDlgState(() => price = v ?? 'Free'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text('Date: ${DateFormat('EEE, MMM dd, yyyy').format(eventDate)}'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: eventDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setDlgState(() => eventDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text('Time: ${eventTime.format(ctx)}'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: eventTime,
                    );
                    if (picked != null) {
                      setDlgState(() => eventTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Venue / Address *',
                    hintText: 'e.g. Cubbon Park / Pet Sanctuary',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Event Details & Schedule',
                    hintText: 'Bring water, leashes, and friendly pets...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newEvent = _CommunityEventItem(
                  id: 'event-user-${DateTime.now().millisecondsSinceEpoch}',
                  dateMonth: DateFormat('MMM').format(eventDate).toUpperCase(),
                  dateDay: DateFormat('dd').format(eventDate),
                  timeString: '${DateFormat('E').format(eventDate)}, ${eventTime.format(ctx)}',
                  category: category == 'Clinic' ? 'Health' : (category == 'Workshop' ? 'Workshops' : 'This Week'),
                  categoryType: category,
                  distance: 'Local Event',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : 'A welcoming community gathering for pet lovers and companions.',
                  price: price,
                  location: locationCtrl.text.trim(),
                  attendeeCount: 1,
                );

                _addCustomEvent(newEvent);
                Navigator.pop(ctx);
                context.showSnackbar('🎉 Published "${newEvent.title}" event successfully!');
              },
              child: const Text('Publish Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRegisteredEventsModal() {
    HapticFeedback.lightImpact();
    final allEvents = [..._customEvents, ..._buildDefaultUpcomingEvents()];
    final registered = allEvents.where((e) => _registeredEventIds.contains(e.id)).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Registered Events',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            if (registered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      AppSpacing.vGapSm,
                      Text(
                        'No Registered Events Yet',
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'RSVP for upcoming workshops and clinics to see them here.',
                        style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: registered.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final ev = registered[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ev.dateMonth, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colorScheme.primary)),
                            Text(ev.dateDay, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colorScheme.primary)),
                          ],
                        ),
                      ),
                      title: Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${ev.timeString} • ${ev.location}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        tooltip: 'Cancel RSVP',
                        onPressed: () {
                          setState(() => _registeredEventIds.remove(ev.id));
                          _saveRegistrations();
                          Navigator.pop(ctx);
                          context.showSnackbar('Cancelled registration for ${ev.title}');
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_CommunityEventItem> _buildDefaultUpcomingEvents() {
    final now = DateTime.now();
    final d1 = now.add(const Duration(days: 2));
    final d2 = now.add(const Duration(days: 5));
    final d3 = now.add(const Duration(days: 8));
    final d4 = now.add(const Duration(days: 14));

    return [
      _CommunityEventItem(
        id: 'event-1',
        dateMonth: DateFormat('MMM').format(d1).toUpperCase(),
        dateDay: DateFormat('dd').format(d1),
        timeString: '${DateFormat('E').format(d1)}, 10:00 AM',
        category: 'Health',
        categoryType: 'Clinic',
        distance: '2.5 km away (Indiranagar)',
        title: 'Community Wellness & Vaccine Clinic',
        description:
            'Subsidized core vaccines, microchipping, and wellness checks for registered community pets. Walk-ins welcome.',
        price: 'Free / Subsidized',
        location: 'Central Veterinary Hospital',
        attendeeCount: 18,
      ),
      _CommunityEventItem(
        id: 'event-2',
        dateMonth: DateFormat('MMM').format(d2).toUpperCase(),
        dateDay: DateFormat('dd').format(d2),
        timeString: '${DateFormat('E').format(d2)}, 5:30 PM',
        category: 'Workshops',
        categoryType: 'Workshop',
        distance: '5.0 km away (Koramangala)',
        title: 'Basic Leash & Agility Training',
        description:
            'A beginner-friendly session for leash manners, recall commands, and agility obstacle confidence.',
        price: 'Free',
        location: 'Koramangala Pet Park',
        attendeeCount: 12,
      ),
      _CommunityEventItem(
        id: 'event-3',
        dateMonth: DateFormat('MMM').format(d3).toUpperCase(),
        dateDay: DateFormat('dd').format(d3),
        timeString: '${DateFormat('E').format(d3)}, 9:00 AM',
        category: 'This Week',
        categoryType: 'Meetup',
        distance: '1.8 km away (Cubbon Park)',
        title: 'Morning Socialization Pack Walk',
        description:
            'Structured group walk with certified trainers to foster calm leash interactions and exercise.',
        price: 'Free',
        location: 'Cubbon Park Dog Zone',
        attendeeCount: 24,
      ),
      _CommunityEventItem(
        id: 'event-4',
        dateMonth: DateFormat('MMM').format(d4).toUpperCase(),
        dateDay: DateFormat('dd').format(d4),
        timeString: '${DateFormat('E').format(d4)}, 6:00 PM',
        category: 'Health',
        categoryType: 'Seminar',
        distance: '3.2 km away (HSR Layout)',
        title: 'Pet Nutrition & Diet Essentials',
        description:
            'Learn how to balance proteins, supplements, and manage common food sensitivities in companion pets.',
        price: 'Free',
        location: 'Pet Care & Nutrition Center',
        attendeeCount: 15,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final pet = ref.watch(selectedPetProvider);
    final petName = pet?.name ?? 'your companion';

    final allEvents = [..._customEvents, ..._buildDefaultUpcomingEvents()];
    final filteredEvents = allEvents.where((e) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Nearby') return true;
      return e.category == _selectedCategory;
    }).toList();

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
            onPressed: _openRegisteredEventsModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openHostEventDialog,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Host Meetup'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
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
                Text(
                  'Discover local pet meetups, educational workshops, and subsidized health clinics.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
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
                            if (selected) {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Featured AI Recommended Event ──────────────────
                _buildAiRecommendationCard(context, petName),
                AppSpacing.vGapXl,

                // ── Upcoming Events List ──────────────────────────
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
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          AppSpacing.vGapSm,
                          Text('No Events in this Category', style: context.textTheme.titleMedium),
                          AppSpacing.vGapXs,
                          Text('Be the first to host a meetup in your neighborhood!', style: context.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredEvents.length,
                    separatorBuilder: (_, __) => AppSpacing.vGapMd,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return _buildEventCard(context, event);
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiRecommendationCard(BuildContext context, String petName) {
    final scheme = context.colorScheme;
    const recId = 'event-rec-ai';
    final isRegistered = _registeredEventIds.contains(recId);
    final hasReminder = _reminderEventIds.contains(recId);

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: scheme.primary,
                size: AppIconSizes.sm,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'AI Recommendation for $petName',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: AppTypography.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'This Weekend, 10:00 AM',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Text(
            'Feline & Canine Enrichment & Wellness Clinic',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Join local veterinary specialists for tips on active indoor enrichment, nail trims, and customized nutrition plans for $petName.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          AppSpacing.vGapLg,
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isRegistered) {
                      _registeredEventIds.remove(recId);
                    } else {
                      _registeredEventIds.add(recId);
                    }
                  });
                  _saveRegistrations();
                  context.showSnackbar(
                    isRegistered ? 'Cancelled RSVP.' : '🎉 Confirmed RSVP for Enrichment Clinic!',
                  );
                },
                icon: Icon(isRegistered ? Icons.check_circle : Icons.event_available, size: 16),
                label: Text(isRegistered ? 'Registered (RSVP)' : 'Register Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: isRegistered ? const Color(0xFF10B981) : scheme.primary,
                ),
              ),
              AppSpacing.hGapSm,
              IconButton.outlined(
                icon: Icon(
                  hasReminder ? Icons.notifications_active : Icons.notifications_none,
                  color: hasReminder ? scheme.primary : scheme.onSurfaceVariant,
                ),
                tooltip: hasReminder ? 'Reminder Set' : 'Set Reminder',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (hasReminder) {
                      _reminderEventIds.remove(recId);
                    } else {
                      _reminderEventIds.add(recId);
                    }
                  });
                  _saveReminders();
                  context.showSnackbar(
                    hasReminder ? 'Reminder cleared.' : '🔔 Calendar alert set for this event!',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, _CommunityEventItem event) {
    final scheme = context.colorScheme;
    final isRegistered = _registeredEventIds.contains(event.id);
    final hasReminder = _reminderEventIds.contains(event.id);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.dateMonth,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: AppTypography.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  event.dateDay,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: scheme.onSurface,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${event.categoryType} • ${event.distance}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: AppTypography.semiBold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.price,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSecondaryContainer,
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vGapSm,
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      event.timeString,
                      style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.group_outlined, size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${event.attendeeCount + (isRegistered ? 1 : 0)} attending',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      tooltip: 'Get Directions',
                      onPressed: () {
                        ExternalActions.openMapSearch(event.location, context: context);
                      },
                    ),
                    AppSpacing.hGapXs,
                    IconButton.outlined(
                      icon: Icon(
                        hasReminder ? Icons.notifications_active : Icons.notifications_none,
                        size: 18,
                        color: hasReminder ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      tooltip: hasReminder ? 'Reminder Active' : 'Set Calendar Reminder',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (hasReminder) {
                            _reminderEventIds.remove(event.id);
                          } else {
                            _reminderEventIds.add(event.id);
                          }
                        });
                        _saveReminders();
                        context.showSnackbar(
                          hasReminder ? 'Reminder removed.' : '🔔 Reminder alert scheduled for ${event.title}',
                        );
                      },
                    ),
                    AppSpacing.hGapXs,
                    IconButton.outlined(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: 'Share Event',
                      onPressed: () {
                        ExternalActions.shareText(
                          '📅 Pet Event: ${event.title}\n'
                          '⏰ Time: ${event.timeString}\n'
                          '📍 Location: ${event.location}\n'
                          'Admission: ${event.price}\n\n'
                          '${event.description}\n\n'
                          'RSVP via PetConnect AI Community Hub!',
                          subject: 'Pet Community Event: ${event.title}',
                        );
                      },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: Icon(
                        isRegistered ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                        size: 15,
                      ),
                      label: Text(isRegistered ? 'Going' : 'RSVP'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isRegistered ? const Color(0xFF10B981) : scheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isRegistered) {
                            _registeredEventIds.remove(event.id);
                          } else {
                            _registeredEventIds.add(event.id);
                          }
                        });
                        _saveRegistrations();
                        context.showSnackbar(
                          isRegistered ? 'Cancelled RSVP.' : '🎉 RSVP Confirmed for "${event.title}"!',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
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
    this.attendeeCount = 10,
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
  final int attendeeCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateMonth': dateMonth,
    'dateDay': dateDay,
    'timeString': timeString,
    'category': category,
    'categoryType': categoryType,
    'distance': distance,
    'title': title,
    'description': description,
    'price': price,
    'location': location,
    'attendeeCount': attendeeCount,
  };

  factory _CommunityEventItem.fromJson(Map<String, dynamic> j) => _CommunityEventItem(
    id: j['id'] as String,
    dateMonth: j['dateMonth'] as String,
    dateDay: j['dateDay'] as String,
    timeString: j['timeString'] as String,
    category: j['category'] as String,
    categoryType: j['categoryType'] as String,
    distance: j['distance'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    price: j['price'] as String,
    location: j['location'] as String,
    attendeeCount: (j['attendeeCount'] as num?)?.toInt() ?? 10,
  );
}
