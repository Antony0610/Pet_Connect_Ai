import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State representation of a single daily medication or care reminder.
class DailyCareItem {
  const DailyCareItem({
    required this.id,
    required this.title,
    required this.dosage,
    required this.scheduledTime,
    this.instructions,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String dosage;
  final String scheduledTime;
  final String? instructions;
  final bool isCompleted;

  DailyCareItem copyWith({bool? isCompleted}) {
    return DailyCareItem(
      id: id,
      title: title,
      dosage: dosage,
      scheduledTime: scheduledTime,
      instructions: instructions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Notifier managing daily medication checklist and compliance streak.
class MedicationAdherenceNotifier extends StateNotifier<List<DailyCareItem>> {
  MedicationAdherenceNotifier(this._prefs, this._petId) : super([]) {
    _loadState();
  }

  final SharedPreferences _prefs;
  final String _petId;

  String get _dateKey {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'care_adherence_${_petId}_$today';
  }

  void _loadState() {
    final completedIds = _prefs.getStringList(_dateKey) ?? [];

    // Standard daily care protocol default templates
    final baseItems = [
      DailyCareItem(
        id: 'med_heartworm',
        title: 'Heartworm & Parasite Prevention',
        dosage: '1 chewable tablet with food',
        scheduledTime: '08:00 AM',
        instructions: 'Administer monthly protection dose',
        isCompleted: completedIds.contains('med_heartworm'),
      ),
      DailyCareItem(
        id: 'med_omega',
        title: 'Omega-3 Joint & Coat Supplement',
        dosage: '2 softgels',
        scheduledTime: '12:30 PM',
        instructions: 'Supports hip mobility & skin hydration',
        isCompleted: completedIds.contains('med_omega'),
      ),
      DailyCareItem(
        id: 'med_dental',
        title: 'Enzymatic Dental Hygiene Treat',
        dosage: '1 dental stick',
        scheduledTime: '07:00 PM',
        instructions: 'Reduces plaque & freshens breath',
        isCompleted: completedIds.contains('med_dental'),
      ),
    ];

    state = baseItems;
  }

  /// Toggles completion of a daily care item and saves to local storage.
  Future<void> toggleItem(String itemId) async {
    final updated = state.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    state = updated;

    final completedIds = updated
        .where((i) => i.isCompleted)
        .map((i) => i.id)
        .toList();

    await _prefs.setStringList(_dateKey, completedIds);
  }

  /// Returns today's completion percentage (0.0 to 1.0).
  double get completionRate {
    if (state.isEmpty) return 1.0;
    final completed = state.where((i) => i.isCompleted).length;
    return completed / state.length;
  }
}

/// Provider family for daily medication adherence keyed by pet ID.
final medicationAdherenceProvider = StateNotifierProvider.family<
    MedicationAdherenceNotifier,
    List<DailyCareItem>,
    String>((ref, petId) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MedicationAdherenceNotifier(prefs, petId);
});
