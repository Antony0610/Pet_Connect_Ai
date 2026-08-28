import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/medication_adherence_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MedicationAdherenceNotifier Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initializes with default care routine items', () {
      final notifier = MedicationAdherenceNotifier(prefs, 'pet-123');

      expect(notifier.state.isNotEmpty, isTrue);
      expect(notifier.state.length, equals(3));
      expect(notifier.completionRate, equals(0.0));
    });

    test('toggleItem updates completion status and computes adherence rate', () async {
      final notifier = MedicationAdherenceNotifier(prefs, 'pet-123');
      final firstItemId = notifier.state.first.id;

      await notifier.toggleItem(firstItemId);

      expect(notifier.state.first.isCompleted, isTrue);
      expect(notifier.completionRate, closeTo(1 / 3, 0.01));

      // Toggling again unchecks it
      await notifier.toggleItem(firstItemId);
      expect(notifier.state.first.isCompleted, isFalse);
      expect(notifier.completionRate, equals(0.0));
    });

    test('completing all items yields 1.0 completion rate', () async {
      final notifier = MedicationAdherenceNotifier(prefs, 'pet-123');

      for (final item in notifier.state) {
        await notifier.toggleItem(item.id);
      }

      expect(notifier.completionRate, equals(1.0));
    });
  });
}
