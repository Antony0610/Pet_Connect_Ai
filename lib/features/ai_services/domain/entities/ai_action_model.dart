import 'dart:convert';
import 'package:flutter/material.dart';

/// The supported actionable commands that the AI Assistant can trigger in-app.
enum AppActionType {
  bookConsultation,
  collarLostMode,
  emergencySos,
  calculateToxicity,
  calculateNutrition,
  logWeight,
  recordVaccination,
  collarBuzzer,
  geofenceAlert,
  medicationReminder,
  navigateScreen,
  generatePoster,
  unknown;

  static AppActionType fromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'book_consultation':
      case 'bookconsultation':
        return AppActionType.bookConsultation;
      case 'collar_lost_mode':
      case 'collarlostmode':
        return AppActionType.collarLostMode;
      case 'emergency_sos':
      case 'emergencysos':
        return AppActionType.emergencySos;
      case 'calculate_toxicity':
      case 'calculatetoxicity':
        return AppActionType.calculateToxicity;
      case 'calculate_nutrition':
      case 'calculatenutrition':
        return AppActionType.calculateNutrition;
      case 'log_weight':
      case 'logweight':
        return AppActionType.logWeight;
      case 'record_vaccination':
      case 'recordvaccination':
        return AppActionType.recordVaccination;
      case 'collar_buzzer':
      case 'collarbuzzer':
      case 'ring_collar':
        return AppActionType.collarBuzzer;
      case 'geofence_alert':
      case 'geofencealert':
        return AppActionType.geofenceAlert;
      case 'medication_reminder':
      case 'medicationreminder':
      case 'add_reminder':
        return AppActionType.medicationReminder;
      case 'navigate_screen':
      case 'navigatescreen':
      case 'open_page':
        return AppActionType.navigateScreen;
      case 'generate_poster':
      case 'generateposter':
        return AppActionType.generatePoster;
      default:
        return AppActionType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AppActionType.bookConsultation:
        return 'Book Vet Consultation';
      case AppActionType.collarLostMode:
        return 'Smart Collar Lost Mode';
      case AppActionType.emergencySos:
        return 'Emergency SOS Broadcast';
      case AppActionType.calculateToxicity:
        return 'Toxicity Safety Analysis';
      case AppActionType.calculateNutrition:
        return 'Dietary & Nutrition Plan';
      case AppActionType.logWeight:
        return 'Log Pet Weight';
      case AppActionType.recordVaccination:
        return 'Record Vaccination';
      case AppActionType.collarBuzzer:
        return 'Ping Collar Chime';
      case AppActionType.geofenceAlert:
        return 'Configure Safe Geofence';
      case AppActionType.medicationReminder:
        return 'Set Medication Reminder';
      case AppActionType.navigateScreen:
        return 'Open Application Screen';
      case AppActionType.generatePoster:
        return 'Create Alert Poster';
      case AppActionType.unknown:
        return 'Assistant Action';
    }
  }

  IconData get icon {
    switch (this) {
      case AppActionType.bookConsultation:
        return Icons.calendar_month_rounded;
      case AppActionType.collarLostMode:
        return Icons.campaign_rounded;
      case AppActionType.emergencySos:
        return Icons.warning_amber_rounded;
      case AppActionType.calculateToxicity:
        return Icons.medical_services_rounded;
      case AppActionType.calculateNutrition:
        return Icons.restaurant_rounded;
      case AppActionType.logWeight:
        return Icons.monitor_weight_rounded;
      case AppActionType.recordVaccination:
        return Icons.vaccines_rounded;
      case AppActionType.collarBuzzer:
        return Icons.volume_up_rounded;
      case AppActionType.geofenceAlert:
        return Icons.share_location_rounded;
      case AppActionType.medicationReminder:
        return Icons.alarm_rounded;
      case AppActionType.navigateScreen:
        return Icons.open_in_new_rounded;
      case AppActionType.generatePoster:
        return Icons.picture_as_pdf_rounded;
      case AppActionType.unknown:
        return Icons.smart_toy_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case AppActionType.emergencySos:
      case AppActionType.collarLostMode:
        return const Color(0xFFEF4444);
      case AppActionType.calculateToxicity:
        return const Color(0xFFF59E0B);
      case AppActionType.bookConsultation:
      case AppActionType.recordVaccination:
        return const Color(0xFF3B82F6);
      case AppActionType.calculateNutrition:
      case AppActionType.logWeight:
        return const Color(0xFF10B981);
      case AppActionType.collarBuzzer:
      case AppActionType.geofenceAlert:
        return const Color(0xFF8B5CF6);
      case AppActionType.medicationReminder:
        return const Color(0xFF06B6D4);
      case AppActionType.navigateScreen:
      case AppActionType.generatePoster:
      default:
        return const Color(0xFF6366F1);
    }
  }
}

enum ActionExecutionStatus {
  pending,
  executing,
  completed,
  failed,
  dismissed,
}

/// Represents an actionable command extracted from an AI Assistant response.
class AppAction {
  AppAction({
    required this.id,
    required this.type,
    required this.parameters,
    this.status = ActionExecutionStatus.pending,
    this.statusMessage,
  });

  final String id;
  final AppActionType type;
  final Map<String, dynamic> parameters;
  ActionExecutionStatus status;
  String? statusMessage;

  String get summary {
    switch (type) {
      case AppActionType.bookConsultation:
        final date = parameters['date'] ?? parameters['preferred_date'] ?? 'Upcoming slot';
        final vet = parameters['vet_name'] ?? parameters['clinic'] ?? 'Available Specialist';
        return 'Schedule appointment with $vet ($date)';
      case AppActionType.collarLostMode:
        final enable = parameters['enable'] == true || parameters['enable'] == 'true';
        return enable ? 'Activate GPS Lost Mode & High-Rate Tracking' : 'Deactivate Collar Lost Mode';
      case AppActionType.emergencySos:
        return 'Broadcast Emergency SOS to nearby clinics and responders';
      case AppActionType.calculateToxicity:
        final sub = parameters['substance'] ?? 'Food/Toxin';
        return 'Review toxicity hazard analysis for "$sub"';
      case AppActionType.calculateNutrition:
        return 'Calculate customized calorie & nutrient portion targets';
      case AppActionType.logWeight:
        final wt = parameters['weight_kg'] ?? parameters['weight'] ?? '--';
        return 'Log weight entry: $wt kg';
      case AppActionType.recordVaccination:
        final vax = parameters['vaccine_name'] ?? 'Core Vaccine';
        return 'Record vaccination entry: "$vax"';
      case AppActionType.collarBuzzer:
        return 'Ring audio buzzer on paired smart collar';
      case AppActionType.geofenceAlert:
        final r = parameters['radius_meters'] ?? '150';
        return 'Set safe boundary zone ($r meters)';
      case AppActionType.medicationReminder:
        final title = parameters['title'] ?? 'Medication';
        final time = parameters['time'] ?? '08:00 AM';
        return 'Set daily reminder for $title at $time';
      case AppActionType.navigateScreen:
        final route = parameters['route'] ?? parameters['screen'] ?? 'target';
        return 'Navigate to $route';
      case AppActionType.generatePoster:
        final pType = parameters['poster_type'] ?? 'lost';
        return 'Open $pType pet poster studio';
      case AppActionType.unknown:
        return 'Execute requested operation';
    }
  }

  /// Parses the markdown envelope:
  /// ```app_action
  /// {
  ///   "action": "book_consultation",
  ///   "parameters": { ... }
  /// }
  /// ```
  static AppAction? extractFromText(String text) {
    final regex = RegExp(
      r'```app_action\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final jsonRaw = match.group(1);
    if (jsonRaw == null || jsonRaw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonRaw) as Map<String, dynamic>;
      final actionName = decoded['action'] as String? ?? '';
      final params = (decoded['parameters'] as Map<String, dynamic>?) ?? {};
      final type = AppActionType.fromString(actionName);
      if (type == AppActionType.unknown) return null;

      return AppAction(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        parameters: params,
      );
    } catch (_) {
      return null;
    }
  }

  /// Strips the raw ```app_action ... ``` block so it doesn't show in the speech bubble.
  static String cleanDisplayText(String text) {
    return text.replaceAll(RegExp(r'```app_action\s*[\s\S]*?\s*```'), '').trim();
  }
}
