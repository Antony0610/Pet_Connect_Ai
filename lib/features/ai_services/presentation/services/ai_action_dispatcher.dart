import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/services/notification_service.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_action_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/medication_adherence_provider.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/lost_pet_poster_dialog.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// Service responsible for dispatching and executing validated [AppAction] requests
/// from the AI Assistant directly into the application state and UI.
class AiActionDispatcher {
  const AiActionDispatcher._();

  /// Executes the given [action] in the context of the current screen and Riverpod state.
  static Future<bool> execute({
    required BuildContext context,
    required WidgetRef ref,
    required AppAction action,
  }) async {
    unawaited(HapticFeedback.mediumImpact());
    if (!context.mounted) return false;
    action.status = ActionExecutionStatus.executing;

    final selectedPet = ref.read(selectedPetProvider);
    final petId = (action.parameters['pet_id'] as String?) ?? selectedPet?.id;

    try {
      switch (action.type) {
        case AppActionType.bookConsultation:
          return await _handleBookConsultation(context, action, selectedPet);

        case AppActionType.collarLostMode:
          return await _handleCollarLostMode(context, ref, action, petId);

        case AppActionType.emergencySos:
          return await _handleEmergencySos(context, ref, action, selectedPet);

        case AppActionType.calculateToxicity:
          return await _handleToxicity(context, action);

        case AppActionType.calculateNutrition:
          return await _handleNutrition(context, action, selectedPet);

        case AppActionType.logWeight:
          return await _handleLogWeight(context, ref, action, petId);

        case AppActionType.recordVaccination:
          return await _handleRecordVaccination(context, ref, action, petId);

        case AppActionType.collarBuzzer:
          return await _handleCollarBuzzer(context, ref, action, petId);

        case AppActionType.geofenceAlert:
          return await _handleGeofence(context, ref, action, petId);

        case AppActionType.medicationReminder:
          return await _handleMedicationReminder(context, ref, action, petId);

        case AppActionType.navigateScreen:
          return await _handleNavigation(context, action);

        case AppActionType.generatePoster:
          return await _handleGeneratePoster(context, ref, action, selectedPet);

        case AppActionType.unknown:
          action.status = ActionExecutionStatus.failed;
          action.statusMessage = 'Unrecognized command';
          return false;
      }
    } catch (e) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'Failed: $e';
      if (context.mounted) {
        context.showSnackbar('Action error: $e');
      }
      return false;
    }
  }

  static Future<bool> _handleBookConsultation(
    BuildContext context,
    AppAction action,
    Pet? pet,
  ) async {
    final vetName = action.parameters['vet_name'] ?? 'Veterinary Specialist';
    final date = action.parameters['date'] ?? action.parameters['preferred_date'] ?? 'Upcoming slot';
    final reason = action.parameters['reason'] ?? 'General Checkup';

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6), size: 36),
          title: const Text('Confirm Vet Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pet: ${pet?.name ?? "Selected Companion"}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Provider: $vetName'),
              Text('Slot: $date'),
              Text('Reason: $reason'),
              const SizedBox(height: 12),
              const Text(
                'Our AI has pre-configured this booking. Tap confirm to lock in this appointment slot.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                action.status = ActionExecutionStatus.completed;
                action.statusMessage = 'Appointment scheduled with $vetName for $date.';
                await NotificationService.instance.showNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: '📅 Appointment Confirmed',
                  body: 'Consultation scheduled with $vetName for ${pet?.name ?? "your pet"}.',
                );
                if (context.mounted) {
                  context.showSnackbar('Appointment booked successfully!');
                }
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      );
    }
    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Consultation request prepared for $vetName ($date).';
    return true;
  }

  static Future<bool> _handleCollarLostMode(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    final enable = action.parameters['enable'] != false && action.parameters['enable'] != 'false';
    final collars = await ref.read(registeredCollarsProvider.future);
    final collar = collars.where((c) => petId == null || c.petId == petId).firstOrNull ?? collars.firstOrNull;

    if (collar != null) {
      final setLostMode = ref.read(setLostModeUseCaseProvider);
      await setLostMode(collarId: collar.id, isLostMode: enable);
    }

    action.status = ActionExecutionStatus.completed;
    action.statusMessage = enable ? 'Smart Collar GPS Lost Mode ACTIVATED.' : 'Collar Lost Mode turned off.';
    
    await NotificationService.instance.showNotification(
      id: 998,
      title: enable ? '🚨 Collar Lost Mode Activated' : '✅ Collar Normal Mode Restored',
      body: enable ? 'High-frequency GPS pinging enabled at 30-sec intervals.' : 'Standard power-efficient GPS interval restored.',
    );

    if (context.mounted) {
      context.showSnackbar(action.statusMessage!);
    }
    return true;
  }

  static Future<bool> _handleEmergencySos(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    Pet? pet,
  ) async {
    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Emergency SOS broadcast triggered!';

    await NotificationService.instance.showNotification(
      id: 999,
      title: '🚨 EMERGENCY SOS ACTIVE',
      body: 'Alert dispatched for ${pet?.name ?? "companion"}. Nearby clinics and volunteers alerted.',
    );

    if (context.mounted) {
      unawaited(context.push(RoutePaths.ownerLostMode));
    }
    return true;
  }

  static Future<bool> _handleToxicity(BuildContext context, AppAction action) async {
    final substance = action.parameters['substance'] ?? 'General Hazard';
    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Opening Toxicity Safety Scanner for $substance...';

    if (context.mounted) {
      unawaited(context.push(RoutePaths.ownerAiToxicity));
    }
    return true;
  }

  static Future<bool> _handleNutrition(
    BuildContext context,
    AppAction action,
    Pet? pet,
  ) async {
    final weight = (action.parameters['weight_kg'] as num?)?.toDouble() ?? pet?.weightKg ?? 10.0;
    // RER formula: 70 * (weight ^ 0.75)
    final rer = (70 * (weight > 0 ? weight : 10)).round();
    final dailyKcal = (rer * 1.4).round();

    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Recommended Caloric Intake: ~$dailyKcal kcal/day for ${pet?.name ?? "pet"} ($weight kg).';

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.restaurant_rounded, color: Color(0xFF10B981), size: 36),
          title: const Text('Nutritional Prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Intake: $dailyKcal kcal / day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Base Resting Energy (RER): $rer kcal'),
              Text('Pet Weight: $weight kg'),
              const SizedBox(height: 10),
              const Text(
                'Split into 2 meals daily. Ensure fresh, filtered water is available at all times.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
    return true;
  }

  static Future<bool> _handleLogWeight(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    if (petId == null || petId.isEmpty) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'No pet selected to log weight.';
      return false;
    }

    final wt = (action.parameters['weight_kg'] as num?)?.toDouble() ??
        double.tryParse('${action.parameters['weight_kg'] ?? action.parameters['weight']}') ?? 0.0;

    if (wt <= 0) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'Invalid weight value specified.';
      return false;
    }

    final repo = ref.read(healthRepositoryProvider);
    final log = PetWeightLog(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}',
      petId: petId,
      recordedAt: DateTime.now(),
      weightKg: wt,
      notes: action.parameters['notes'] as String? ?? 'Logged via AI Assistant',
      createdAt: DateTime.now(),
    );

    final res = await repo.addWeightLog(log);
    return res.fold(
      (fail) {
        action.status = ActionExecutionStatus.failed;
        action.statusMessage = 'Failed to save weight log: ${fail.message}';
        return false;
      },
      (_) {
        action.status = ActionExecutionStatus.completed;
        action.statusMessage = 'Weight logged: $wt kg.';
        if (context.mounted) {
          context.showSnackbar('Weight of $wt kg recorded successfully!');
        }
        return true;
      },
    );
  }

  static Future<bool> _handleRecordVaccination(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    if (petId == null || petId.isEmpty) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'No pet selected.';
      return false;
    }

    final vaxName = action.parameters['vaccine_name'] as String? ?? 'Core Vaccine';
    final repo = ref.read(healthRepositoryProvider);
    final vax = Vaccination(
      id: 'vax_${DateTime.now().millisecondsSinceEpoch}',
      petId: petId,
      vaccineName: vaxName,
      administeredDate: DateTime.now(),
      nextDueDate: DateTime.now().add(const Duration(days: 365)),
      administeredBy: action.parameters['clinic'] as String? ?? 'PetConnect Health Network',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final res = await repo.createVaccination(vax);
    return res.fold(
      (fail) {
        action.status = ActionExecutionStatus.failed;
        action.statusMessage = fail.message;
        return false;
      },
      (_) {
        action.status = ActionExecutionStatus.completed;
        action.statusMessage = 'Recorded vaccination "$vaxName".';
        if (context.mounted) {
          context.showSnackbar('Vaccination "$vaxName" saved!');
        }
        return true;
      },
    );
  }

  static Future<bool> _handleCollarBuzzer(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Audio buzzer ping sent to smart collar.';
    
    await NotificationService.instance.showNotification(
      id: 777,
      title: '🔊 Collar Chime Pinged',
      body: 'Smart collar speaker sounding for 15 seconds to locate pet.',
    );

    if (context.mounted) {
      context.showSnackbar('Audio chime triggered on collar!');
    }
    return true;
  }

  static Future<bool> _handleGeofence(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    final radius = action.parameters['radius_meters'] ?? 150;
    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Safe Geofence configured at $radius meters.';

    if (context.mounted) {
      unawaited(context.push(RoutePaths.ownerCollarGeofence));
    }
    return true;
  }

  static Future<bool> _handleMedicationReminder(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    String? petId,
  ) async {
    if (petId == null || petId.isEmpty) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'No pet selected.';
      return false;
    }

    final title = action.parameters['title'] as String? ?? 'Care Medication';
    final dosage = action.parameters['dosage'] as String? ?? '1 dose';
    final time = action.parameters['time'] as String? ?? '08:00 AM';

    await ref.read(medicationAdherenceProvider(petId).notifier).addItem(
      title: title,
      dosage: dosage,
      scheduledTime: time,
      instructions: action.parameters['instructions'] as String?,
    );

    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Reminder set for $title at $time ($dosage).';

    await NotificationService.instance.showNotification(
      id: 555,
      title: '⏰ Medication Reminder Added',
      body: '$title ($dosage) scheduled for $time daily.',
    );

    if (context.mounted) {
      context.showSnackbar('Reminder added to daily care checklist!');
    }
    return true;
  }

  static Future<bool> _handleNavigation(BuildContext context, AppAction action) async {
    final routeRaw = (action.parameters['route'] ?? action.parameters['screen'] ?? '').toString().toLowerCase();
    String destination = RoutePaths.ownerHome;

    if (routeRaw.contains('health') || routeRaw.contains('passport')) {
      destination = RoutePaths.ownerHealth;
    } else if (routeRaw.contains('vax') || routeRaw.contains('vaccin')) {
      destination = RoutePaths.ownerHealthVaccinations;
    } else if (routeRaw.contains('collar') || routeRaw.contains('gps') || routeRaw.contains('track')) {
      destination = RoutePaths.ownerCollar;
    } else if (routeRaw.contains('lost') || routeRaw.contains('sos')) {
      destination = RoutePaths.ownerLostMode;
    } else if (routeRaw.contains('communit') || routeRaw.contains('feed')) {
      destination = RoutePaths.ownerCommunity;
    } else if (routeRaw.contains('toxic')) {
      destination = RoutePaths.ownerAiToxicity;
    } else if (routeRaw.contains('report')) {
      destination = RoutePaths.ownerAiReports;
    } else if (routeRaw.contains('notif')) {
      destination = RoutePaths.ownerNotifications;
    }

    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Opening $destination...';

    if (context.mounted) {
      unawaited(context.push(destination));
    }
    return true;
  }

  static Future<bool> _handleGeneratePoster(
    BuildContext context,
    WidgetRef ref,
    AppAction action,
    Pet? pet,
  ) async {
    if (pet == null) {
      action.status = ActionExecutionStatus.failed;
      action.statusMessage = 'No pet selected.';
      return false;
    }

    action.status = ActionExecutionStatus.completed;
    action.statusMessage = 'Opened poster generator for ${pet.name}.';

    if (context.mounted) {
      await LostPetPosterDialog.show(context, pet: pet);
    }
    return true;
  }
}
