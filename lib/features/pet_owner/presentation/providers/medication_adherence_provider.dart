import 'dart:convert';
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

  String get _customItemsKey => 'care_items_custom_$_petId';

  void _loadState() {
    final completedIds = _prefs.getStringList(_dateKey) ?? [];
    final rawJson = _prefs.getString(_customItemsKey);

    List<DailyCareItem> items = [];
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        items = decoded.map((e) {
          final m = e as Map<String, dynamic>;
          final id = m['id'] as String;
          return DailyCareItem(
            id: id,
            title: m['title'] as String,
            dosage: m['dosage'] as String,
            scheduledTime: m['scheduledTime'] as String,
            instructions: m['instructions'] as String?,
            isCompleted: completedIds.contains(id),
          );
        }).toList();
      } catch (_) {}
    }

    state = items;
  }

  Future<void> addItem({
    required String title,
    required String dosage,
    required String scheduledTime,
    String? instructions,
  }) async {
    final newItem = DailyCareItem(
      id: 'care_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      dosage: dosage,
      scheduledTime: scheduledTime,
      instructions: instructions,
      isCompleted: false,
    );

    final updated = [...state, newItem];
    state = updated;
    await _saveCustomItems();
  }

  Future<void> loadStandardWellnessProtocol() async {
    final defaults = [
      DailyCareItem(
        id: 'med_heartworm_$_petId',
        title: 'Heartworm & Parasite Prevention',
        dosage: '1 chewable tablet with food',
        scheduledTime: '08:00 AM',
        instructions: 'Administer monthly protection dose',
      ),
      DailyCareItem(
        id: 'med_dental_$_petId',
        title: 'Enzymatic Dental Hygiene Treat',
        dosage: '1 dental stick',
        scheduledTime: '07:00 PM',
        instructions: 'Reduces plaque & freshens breath',
      ),
    ];

    state = defaults;
    await _saveCustomItems();
  }

  Future<void> removeItem(String itemId) async {
    final updated = state.where((i) => i.id != itemId).toList();
    state = updated;
    await _saveCustomItems();
  }

  Future<void> _saveCustomItems() async {
    final listMap = state.map((i) => {
      'id': i.id,
      'title': i.title,
      'dosage': i.dosage,
      'scheduledTime': i.scheduledTime,
      'instructions': i.instructions,
    }).toList();
    await _prefs.setString(_customItemsKey, jsonEncode(listMap));
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
