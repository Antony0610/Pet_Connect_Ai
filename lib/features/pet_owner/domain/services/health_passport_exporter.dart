import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for generating and sharing comprehensive, exportable
/// Pet Health Passport summaries for veterinary appointments, travel, and boarding.
class HealthPassportExporter {
  const HealthPassportExporter._();

  /// Generates a structured Health Passport document and opens the native device share sheet.
  static Future<void> exportAndShare({
    required BuildContext context,
    required Pet pet,
    UserProfile? owner,
    List<Vaccination> vaccinations = const [],
    List<HealthRecord> healthRecords = const [],
    List<PetWeightLog> weightLogs = const [],
  }) async {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final nowStr = dateFormat.format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('         OFFICIAL PET HEALTH PASSPORT               ');
    buffer.writeln('              PetConnect AI Core                    ');
    buffer.writeln('====================================================');
    buffer.writeln('Export Date: $nowStr');
    buffer.writeln();

    // ── 1. Pet Identity ──────────────────────────────────────────────
    buffer.writeln('--- 🐾 PET IDENTIFICATION ---');
    buffer.writeln('Name:         ${pet.name}');
    buffer.writeln('Species:      ${pet.species.toUpperCase()}');
    buffer.writeln('Breed:        ${pet.breed ?? "Not Specified"}');
    buffer.writeln('Gender:       ${pet.gender?.toUpperCase() ?? "Unknown"}');
    buffer.writeln('Date of Birth:${pet.dateOfBirth != null ? dateFormat.format(pet.dateOfBirth!) : "Unknown"}');
    buffer.writeln('Weight:       ${pet.weightKg != null ? "${pet.weightKg} kg" : "Not recorded"}');
    buffer.writeln('Microchip ID: ${pet.microchipId?.isNotEmpty == true ? pet.microchipId : "Unchipped"}');
    buffer.writeln('Health Status:${pet.healthStatus.toUpperCase()}');
    buffer.writeln();

    // ── 2. Owner Information ─────────────────────────────────────────
    buffer.writeln('--- 👤 REGISTERED OWNER ---');
    buffer.writeln('Name:         ${owner?.fullName ?? "Verified Pet Owner"}');
    buffer.writeln('Email:        ${owner?.email ?? "Protected on File"}');
    buffer.writeln();

    // ── 3. Vaccinations & Immunization ───────────────────────────────
    buffer.writeln('--- 💉 VACCINATION & IMMUNIZATION RECORD ---');
    if (vaccinations.isEmpty) {
      buffer.writeln('No official vaccination entries logged.');
    } else {
      for (final v in vaccinations) {
        final administered = dateFormat.format(v.administeredDate);
        final expiry = v.nextDueDate != null
            ? dateFormat.format(v.nextDueDate!)
            : 'N/A';
        buffer.writeln('• ${v.vaccineName}');
        buffer.writeln('  Administered: $administered | Next Due: $expiry');
        if (v.administeredBy != null && v.administeredBy!.isNotEmpty) {
          buffer.writeln('  Administered By: ${v.administeredBy}');
        }
      }
    }
    buffer.writeln();

    // ── 4. Clinical & Medical History ────────────────────────────────
    buffer.writeln('--- 📋 CLINICAL & MEDICAL HISTORY ---');
    if (healthRecords.isEmpty) {
      buffer.writeln('No acute clinical conditions or surgical history logged.');
    } else {
      for (final r in healthRecords) {
        final date = dateFormat.format(r.recordDate);
        buffer.writeln('• [${r.category.toUpperCase()}] ${r.title} ($date)');
        if (r.diagnosis != null && r.diagnosis!.isNotEmpty) {
          buffer.writeln('  Diagnosis: ${r.diagnosis}');
        }
        if (r.notes != null && r.notes!.isNotEmpty) {
          buffer.writeln('  Notes: ${r.notes}');
        }
      }
    }
    buffer.writeln();

    // ── 5. Growth & Weight Logs ──────────────────────────────────────
    buffer.writeln('--- ⚖️ WEIGHT & GROWTH TRAJECTORY ---');
    if (weightLogs.isEmpty) {
      buffer.writeln('Current weight: ${pet.weightKg != null ? "${pet.weightKg} kg" : "—"}');
    } else {
      for (final w in weightLogs.take(5)) {
        final date = dateFormat.format(w.recordedAt);
        buffer.writeln('• $date: ${w.weightKg} kg ${w.notes != null ? "(${w.notes})" : ""}');
      }
    }
    buffer.writeln();

    buffer.writeln('====================================================');
    buffer.writeln('Verified via PetConnect AI Digital Health Network   ');
    buffer.writeln('https://petconnect.ai/passport/${pet.id}            ');
    buffer.writeln('====================================================');

    final documentText = buffer.toString();

    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedPetName = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final file = File('${tempDir.path}/${sanitizedPetName}_Health_Passport.txt');
      await file.writeAsString(documentText);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        text: '🐾 Attached is the official Pet Health Passport for ${pet.name}. Generated by PetConnect AI.',
        subject: '${pet.name}\'s Pet Health Passport',
      );
    } catch (_) {
      // Fallback to text sharing if file writing is restricted
      // ignore: deprecated_member_use
      await Share.share(
        documentText,
        subject: '${pet.name}\'s Pet Health Passport',
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Health Passport for ${pet.name} ready for sharing!'),
          backgroundColor: const Color(0xFF137A63),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
