import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/patient_queue_notifier.dart';

void main() {
  group('PatientQueueNotifier Unit Tests', () {
    late PatientQueueNotifier notifier;

    setUp(() {
      notifier = PatientQueueNotifier();
    });

    test('Initializes with active triage patients', () {
      expect(notifier.state.isNotEmpty, isTrue);
      expect(notifier.state.first.id, equals('p1'));
    });

    test('Advances patient through clinical triage workflow correctly', () {
      final initialPatient = notifier.state.firstWhere((p) => p.id == 'p1');
      expect(initialPatient.status, equals(TriageStatus.waiting));

      // Advance: waiting -> inTriage
      notifier.advanceStatus('p1');
      var updated = notifier.state.firstWhere((p) => p.id == 'p1');
      expect(updated.status, equals(TriageStatus.inTriage));

      // Advance: inTriage -> inConsultation
      notifier.advanceStatus('p1');
      updated = notifier.state.firstWhere((p) => p.id == 'p1');
      expect(updated.status, equals(TriageStatus.inConsultation));

      // Advance: inConsultation -> discharged
      notifier.advanceStatus('p1');
      updated = notifier.state.firstWhere((p) => p.id == 'p1');
      expect(updated.status, equals(TriageStatus.discharged));
    });

    test('Inserts critical emergency patient at head of queue', () {
      notifier.addPatient(
        name: 'Thor',
        breedAge: 'German Shepherd • 4y',
        species: 'Canine',
        priority: TriagePriority.critical,
        reason: 'Gastric Dilatation-Volvulus (GDV) Emergency',
        ownerName: 'Alex Miller',
        ownerPhone: '+1 (555) 999-1111',
      );

      expect(notifier.state.first.name, equals('Thor'));
      expect(notifier.state.first.priority, equals(TriagePriority.critical));
    });

    test('Removes patient from queue cleanly', () {
      notifier.removePatient('p2');
      expect(notifier.state.any((p) => p.id == 'p2'), isFalse);
    });
  });
}
