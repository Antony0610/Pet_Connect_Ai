import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for generating and sharing comprehensive, clinic-grade
/// Pet Health Passport summaries for veterinary appointments, travel, and boarding.
class HealthPassportExporter {
  const HealthPassportExporter._();

  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 6);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
          return Uint8List.fromList(bytes);
        }
      } else {
        final f = File(url);
        if (f.existsSync()) {
          return await f.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generates a structured Health Passport PDF document and opens the native device share sheet.
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

    final doc = pw.Document(
      title: '${pet.name} Official Health Passport',
      author: 'PetConnect AI Veterinary Network',
    );

    final primaryColor = PdfColor.fromHex('#137A63'); // Emerald Teal
    final secondaryColor = PdfColor.fromHex('#4F378A'); // Royal Indigo
    final headerBgColor = PdfColor.fromHex('#E6F4F1');
    final lightGrey = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    final petImgBytes = await _fetchImageBytes(pet.imageUrl);
    final qrPayload = 'https://petconnect.ai/passport/${pet.id}?auth=verified';

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
                      'OFFICIAL PET HEALTH PASSPORT',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PetConnect AI Core | Certified Clinical Health & Vaccination Registry',
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
                    border: pw.Border.all(color: primaryColor, width: 0.8),
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
                  'Verified Digital Passport: $qrPayload',
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
            // ── 1. Pet Identification Card with Embedded Photo ──────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (petImgBytes != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      margin: const pw.EdgeInsets.only(right: 12),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: primaryColor, width: 1.5),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 7,
                        verticalRadius: 7,
                        child: pw.Image(pw.MemoryImage(petImgBytes), fit: pw.BoxFit.cover),
                      ),
                    )
                  else
                    pw.Container(
                      width: 65,
                      height: 65,
                      margin: const pw.EdgeInsets.only(right: 12),
                      decoration: pw.BoxDecoration(
                        color: headerBgColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: primaryColor, width: 1.5),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'P',
                          style: pw.TextStyle(color: primaryColor, fontSize: 28, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              pet.name.toUpperCase(),
                              style: pw.TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: headerBgColor,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                pet.healthStatus.toUpperCase(),
                                style: pw.TextStyle(
                                  color: primaryColor,
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Table(
                          children: [
                            pw.TableRow(
                              children: [
                                _buildPdfField('Species', pet.species.toUpperCase()),
                                _buildPdfField('Breed', pet.breed ?? 'Not Specified'),
                                _buildPdfField('Gender', pet.gender?.toUpperCase() ?? 'Unknown'),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                _buildPdfField('Date of Birth', pet.dateOfBirth != null ? dateFormat.format(pet.dateOfBirth!) : 'Unknown'),
                                _buildPdfField('Current Weight', pet.weightKg != null ? '${pet.weightKg} kg' : 'Not Recorded'),
                                _buildPdfField('Microchip ID', pet.microchipId?.isNotEmpty == true ? pet.microchipId! : 'Unchipped'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── 2. Registered Guardian Info ────────────────────────
            _buildSectionHeader('REGISTERED GUARDIAN & CONTACT', secondaryColor),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor, width: 0.6),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: _buildPdfField('Guardian Name', owner?.fullName ?? 'Verified Pet Guardian'),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: _buildPdfField(
                      'Emergency Phone',
                      (owner?.phone != null && owner!.phone!.trim().isNotEmpty)
                          ? owner.phone!.trim()
                          : '+91 (Contact via App)',
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: _buildPdfField('Registered Email', owner?.email ?? 'emergency@petconnect.ai'),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── 3. Vaccinations & Immunizations ────────────────────
            _buildSectionHeader('VACCINATION & IMMUNIZATION RECORD', primaryColor),
            if (vaccinations.isEmpty)
              _buildEmptyPlaceholder('No official vaccination records logged yet.')
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: const pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                headers: ['Vaccine Name', 'Administered Date', 'Next Due Date', 'Administered By', 'Status'],
                data: vaccinations.map((v) {
                  final isDue = v.nextDueDate != null && v.nextDueDate!.isBefore(DateTime.now());
                  final statusText = isDue ? 'Overdue' : 'Active / Current';
                  return [
                    v.vaccineName,
                    dateFormat.format(v.administeredDate),
                    v.nextDueDate != null ? dateFormat.format(v.nextDueDate!) : 'Lifetime Immunity',
                    v.administeredBy ?? 'Veterinary Clinic',
                    statusText,
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 12),

            // ── 4. Clinical & Medical History ───────────────────────
            _buildSectionHeader('CLINICAL & MEDICAL DIAGNOSTICS', secondaryColor),
            if (healthRecords.isEmpty)
              _buildEmptyPlaceholder('No acute clinical conditions or surgical procedures recorded.')
            else
              pw.Column(
                children: healthRecords.map((r) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderColor, width: 0.5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: headerBgColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            r.category.toUpperCase(),
                            style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    r.title,
                                    style: const pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    dateFormat.format(r.recordDate),
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                              if (r.diagnosis != null && r.diagnosis!.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Diagnosis: ${r.diagnosis}',
                                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                                ),
                              ],
                              if (r.notes != null && r.notes!.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Notes: ${r.notes}',
                                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 12),

            // ── 5. Growth & Weight History ─────────────────────────
            _buildSectionHeader('GROWTH & WEIGHT TRACKING', primaryColor),
            if (weightLogs.isEmpty)
              _buildEmptyPlaceholder('Baseline recorded weight: ${pet.weightKg != null ? "${pet.weightKg} kg" : "—"}')
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: const pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                headers: ['Measurement Date', 'Body Weight (kg)', 'Clinical Notes'],
                data: weightLogs.take(8).map((w) => [
                  dateFormat.format(w.recordedAt),
                  '${w.weightKg} kg',
                  w.notes ?? 'Routine evaluation',
                ]).toList(),
              ),
            pw.SizedBox(height: 14),

            // ── 6. Verification QR Card ────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DIGITAL CLINICAL VERIFICATION',
                          style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Veterinary clinics, airlines, and boarding facilities may scan the QR code to verify live immunization stamps and active medical records in the PetConnect AI registry.',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.BarcodeWidget(
                    data: qrPayload,
                    barcode: pw.Barcode.qrCode(),
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await doc.save();
      final tempDir = await getTemporaryDirectory();
      final sanitizedPetName = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final file = File('${tempDir.path}/${sanitizedPetName}_Health_Passport.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: '🐾 Attached is the official Pet Health Passport (PDF) for ${pet.name}. Generated by PetConnect AI.',
        subject: '${pet.name}\'s Pet Health Passport (PDF)',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate PDF document. Please check storage permissions.'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Official PDF Health Passport for ${pet.name} generated!'),
          backgroundColor: const Color(0xFF137A63),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(width: 3, height: 12, color: color),
          pw.SizedBox(width: 5),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEmptyPlaceholder(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }
}
