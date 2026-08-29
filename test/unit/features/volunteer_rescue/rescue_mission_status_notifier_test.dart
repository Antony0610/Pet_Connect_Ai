import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_mission_status_notifier.dart';

void main() {
  group('RescueMissionStatusNotifier Unit Tests', () {
    late RescueMissionStatusNotifier notifier;

    setUp(() {
      notifier = RescueMissionStatusNotifier();
    });

    test('Initializes with active rescue mission telemetry', () {
      expect(notifier.state.id, equals('mission-8841'));
      expect(notifier.state.petName, equals('Luna'));
      expect(notifier.state.stage, equals(RescueStage.enRoute));
      expect(notifier.state.responders.length, equals(2));
    });

    test('Advances rescue mission stage through lifecycle', () {
      expect(notifier.state.stage, equals(RescueStage.enRoute));

      // Advance: enRoute -> onScene
      notifier.advanceStage();
      expect(notifier.state.stage, equals(RescueStage.onScene));

      // Advance: onScene -> petSecured
      notifier.advanceStage();
      expect(notifier.state.stage, equals(RescueStage.petSecured));

      // Advance: petSecured -> atClinic
      notifier.advanceStage();
      expect(notifier.state.stage, equals(RescueStage.atClinic));
    });

    test('Toggles collar beacon locator correctly', () {
      expect(notifier.state.isBeaconActive, isTrue);

      notifier.toggleCollarBeacon();
      expect(notifier.state.isBeaconActive, isFalse);

      notifier.toggleCollarBeacon();
      expect(notifier.state.isBeaconActive, isTrue);
    });

    test('Broadcasts verified civilian sighting update', () {
      notifier.addSighting('Visual Match at Bridge', 'Spotted running near south trail arch.');

      expect(notifier.state.sightingHeadline, equals('Visual Match at Bridge'));
      expect(notifier.state.sightingDetail, contains('south trail arch'));
    });

    test('Dispatches additional volunteer responder to active team', () {
      notifier.addResponder(
        const RescueResponder(
          name: 'David Kim',
          role: 'K9 Tracker & Handler',
          distanceMeters: 800,
          status: 'Dispatched',
          isLead: false,
          phone: '+1 (555) 321-4567',
        ),
      );

      expect(notifier.state.responders.length, equals(3));
      expect(notifier.state.responders.last.name, equals('David Kim'));
    });
  });
}
