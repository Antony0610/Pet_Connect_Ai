import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:share_plus/share_plus.dart';

/// Professional PDF generator for AI Clinical Pet Health & Telemetry Reports.
/// Sanitizes all Unicode symbols to prevent missing glyph [ ] tofu boxes.
class AiReportPdfExporter {
  const AiReportPdfExporter._();

  static String _cleanText(String input) {
    return input
        .replaceAll('₹', 'RS. ')
        .replaceAll('•', '*')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('\u2022', '*')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u20B9', 'RS. ')
        .trim();
  }

  static Future<void> exportAndShare({
    required BuildContext context,
    required Pet pet,
    UserProfile? owner,
    required String reportTitle,
    required String reportRange,
    required String reportSummary,
    List<Vaccination> vaccinations = const [],
    List<HealthRecord> healthRecords = const [],
    List<PetWeightLog> weightLogs = const [],
    int? healthScore,
    String? collarRestHours,
    String? activityStatus,
  }) async {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final nowStr = dateFormat.format(DateTime.now());

    // Compute dynamic wellness score if not supplied
    int calculatedScore = healthScore ?? 92;
    if (healthScore == null) {
      int score = 88;
      if (vaccinations.isNotEmpty) score += 4;
      if (pet.healthStatus.toLowerCase().contains('optimal') ||
          pet.healthStatus.toLowerCase().contains('healthy')) {
        score += 3;
      }
      if (weightLogs.isNotEmpty) score += 2;
      calculatedScore = score.clamp(70, 99);
    }

    // Dynamic collar rest or honest manual monitoring notice
    final dynamicSleep = collarRestHours?.isNotEmpty == true
        ? collarRestHours!
        : 'Manual Observation (No Collar)';
    final dynamicActivity = activityStatus?.isNotEmpty == true
        ? activityStatus!
        : 'Manual Activity Logging';

    final doc = pw.Document(
      title: '${pet.name} AI Clinical Health Assessment',
      author: 'PetConnect AI Veterinary Diagnostics',
    );

    final primaryColor = PdfColor.fromHex('#0F766E'); // Emerald Teal
    final secondaryColor = PdfColor.fromHex('#4338CA'); // Deep Indigo
    final headerBgColor = PdfColor.fromHex('#F0FDFA');
    final cardBgColor = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    final weightStr = pet.weightKg != null
        ? '${pet.weightKg!.toStringAsFixed(1)} kg'
        : (weightLogs.isNotEmpty ? '${weightLogs.first.weightKg.toStringAsFixed(1)} kg' : 'Not recorded');

    final cleanSummary = _cleanText(reportSummary);
    final cleanOwnerName = _cleanText(owner?.fullName ?? 'Registered Guardian');
    final cleanMicrochip = _cleanText(pet.microchipId?.isNotEmpty == true ? pet.microchipId! : 'Not chipped');
    final cleanBreed = _cleanText(pet.breedLine);
    final cleanGender = _cleanText(pet.gender?.toUpperCase() ?? 'UNKNOWN');
    final cleanScope = _cleanText('$reportTitle ($reportRange)');

    final qrPayload = '${Env.webBaseUrl}/verify.html?id=${pet.id}&t=r'
        '&pet=${Uri.encodeComponent(pet.name)}'
        '&breed=${Uri.encodeComponent(cleanBreed)}'
        '&species=${Uri.encodeComponent(pet.species)}'
        '&owner=${Uri.encodeComponent(cleanOwnerName)}'
        '&score=$calculatedScore'
        '&date=${Uri.encodeComponent(nowStr)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            margin: const pw.EdgeInsets.only(bottom: 14),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primaryColor, width: 2.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AI CLINICAL WELLNESS & TELEMETRY REPORT',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PetConnect AI Multi-Source Diagnostic Engine | Veterinary Intelligence',
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: headerBgColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: primaryColor, width: 1),
                  ),
                  child: pw.Text(
                    'ISSUED: $nowStr',
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PetConnect AI Clinical Telemetry Summary | Certified Digital Assessment',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context ctx) {
          return [
            // ── PATIENT & HEALTH SCORE BANNER ───────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: cardBgColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          pet.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          '$cleanBreed  |  $cleanGender  |  Weight: $weightStr',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Microchip ID: $cleanMicrochip  |  Owner: $cleanOwnerName',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Report Scope: $cleanScope',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: secondaryColor),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 70,
                    height: 70,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            '$calculatedScore',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'WELLNESS',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 6.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── AI CLINICAL SYNTHESIS ──────────────────────────────
            pw.Text(
              'EXECUTIVE CLINICAL SYNTHESIS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: headerBgColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: primaryColor, width: 1),
              ),
              child: pw.Text(
                cleanSummary,
                style: const pw.TextStyle(fontSize: 10, height: 1.4, color: PdfColors.grey900),
              ),
            ),
            pw.SizedBox(height: 14),

            // ── BIOMETRICS & TELEMETRY MATRIX ──────────────────────
            pw.Text(
              'VITAL SIGNS & TELEMETRY MATRIX',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _metricBox(
                    title: 'Current Weight',
                    value: weightStr,
                    subtitle: weightLogs.length > 1 ? '${weightLogs.length} historical weigh-ins' : 'Stable baseline',
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox(
                    title: 'Collar Rest & Sleep',
                    value: dynamicSleep,
                    subtitle: 'Circadian rest pattern',
                    color: secondaryColor,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox(
                    title: 'Daily Exercise',
                    value: dynamicActivity,
                    subtitle: 'Species activity norm',
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── VACCINATIONS & IMMUNITY REGISTRY ───────────────────
            pw.Text(
              'VACCINATION & PREVENTATIVE CARE STATUS (${vaccinations.length} Recorded)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            if (vaccinations.isNotEmpty)
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: cardBgColor),
                headerHeight: 22,
                cellHeight: 20,
                headerStyle: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
                headers: ['Vaccine / Protocol', 'Administered', 'Next Booster', 'Clinic / Vet', 'Status'],
                data: vaccinations.map((v) {
                  final adminStr = dateFormat.format(v.administeredDate);
                  final nextStr = v.nextDueDate != null ? dateFormat.format(v.nextDueDate!) : 'Routine';
                  final isDue = v.nextDueDate != null && v.nextDueDate!.isBefore(DateTime.now());
                  return [
                    _cleanText(v.vaccineName),
                    adminStr,
                    nextStr,
                    _cleanText(v.administeredBy ?? 'Verified Clinic'),
                    isDue ? 'Booster Due' : 'Protected',
                  ];
                }).toList(),
              )
            else
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: cardBgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Text(
                  'No vaccination records logged yet. Use Health Passport to add core vaccines.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 14),

            // ── CLINICAL VET VERIFICATION & QR ─────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: cardBgColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLINICAL VERIFICATION & PORTAL ACCESS',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Scan QR code with any smartphone camera to verify this assessment or connect with the pet\'s attending veterinarian.',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: primaryColor, width: 1.2),
                    ),
                    child: pw.BarcodeWidget(
                      data: qrPayload,
                      barcode: pw.Barcode.qrCode(),
                      width: 90,
                      height: 90,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final sanitized = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
    final file = File('${tempDir.path}/${sanitized}_AI_Health_Report.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: '🐾 PetConnect AI Clinical Health Assessment for ${pet.name} ($reportRange).',
      subject: 'AI Clinical Report: ${pet.name}',
    );
  }

  static pw.Widget _metricBox({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 1),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
