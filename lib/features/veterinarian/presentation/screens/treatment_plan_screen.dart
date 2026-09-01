import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/features/veterinarian/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:share_plus/share_plus.dart';

class VetTreatmentPlanScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const VetTreatmentPlanScreen({super.key, this.patientId});

  @override
  ConsumerState<VetTreatmentPlanScreen> createState() =>
      _VetTreatmentPlanScreenState();
}

class _VetTreatmentPlanScreenState extends ConsumerState<VetTreatmentPlanScreen> {
  String _diagnosis = 'Seasonal Atopic Dermatitis & Pruritus';
  String _notes = 'Target complete clinical remission within 3 weeks. Medicated bath protocol and oral therapy.';
  int _progress = 35;
  final String _stage1 = 'Symptom Relief (Medication) • Active Stage';
  final String _stage2 = 'Allergen Avoidance & Environmental Controls';
  final String _stage3 = 'Re-Evaluation & Tapering Protocol';

  void _openEditPlanDialog(String targetPetId) async {
    final diagCtrl = TextEditingController(text: _diagnosis);
    final notesCtrl = TextEditingController(text: _notes);
    int progressVal = _progress;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Edit Treatment Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis & Primary Condition',
                    hintText: 'e.g. Seasonal Atopic Dermatitis',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Notes & Goal',
                    hintText: 'e.g. Remission within 3 weeks',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Treatment Progress: $progressVal%'),
                Slider(
                  value: progressVal.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$progressVal%',
                  onChanged: (val) {
                    setDlgState(() => progressVal = val.toInt());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        _diagnosis = diagCtrl.text.trim();
        _notes = notesCtrl.text.trim();
        _progress = progressVal;
      });

      final plan = TreatmentPlan(
        id: '',
        petId: targetPetId,
        title: _diagnosis,
        category: 'Dermatology',
        targetDate: DateTime.now().add(const Duration(days: 21)),
        progressPercent: _progress,
        status: _progress >= 100 ? 'completed' : 'active',
        notes: _notes,
      );

      final repo = ref.read(vetRepositoryProvider);
      final result = await repo.saveTreatmentPlan(plan);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save to database: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(treatmentPlansProvider(targetPetId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treatment plan persisted to Supabase!')),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetPetId = widget.patientId ?? 'p1';
    final plansAsync = ref.watch(treatmentPlansProvider(targetPetId));
    final existingPlans = plansAsync.valueOrNull ?? [];

    if (existingPlans.isNotEmpty) {
      _diagnosis = existingPlans.first.title;
      _notes = existingPlans.first.notes ?? _notes;
      _progress = existingPlans.first.progressPercent;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _diagnosis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: () => _openEditPlanDialog(targetPetId),
            tooltip: 'Edit Plan',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Plan Title & Diagnosis Banner
              _buildPlanHeader(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Step-by-Step Protocol Timeline
              Text(
                'Treatment Protocol Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '1',
                badge: 'Active Stage • Current',
                badgeColor: colorScheme.primary,
                title: _stage1,
                desc:
                    'Administer prescribed therapeutic regimen daily to manage acute symptoms and inflammation. Monitor for tolerance.',
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '2',
                badge: 'Next Phase',
                badgeColor: colorScheme.secondary,
                title: _stage2,
                desc:
                    'Implement environmental and dietary controls based on clinical panel results. Maintain hygiene and skin integrity.',
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '3',
                badge: 'Milestone',
                badgeColor: colorScheme.tertiary,
                title: _stage3,
                desc:
                    'Clinical re-assessment and scheduled in-clinic follow-up to evaluate response and gradually taper medications.',
              ),
              const SizedBox(height: 20),

              // Home Care Owner Instructions Card
              _buildHomeCareCard(context, theme, colorScheme),
              const SizedBox(height: 16),

              // AI Prognosis & Recovery Tracking
              _buildAiPrognosisCard(context, theme, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppChip(
                label: 'CLINICAL TREATMENT PLAN',
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
              Text(
                'Goal: $_progress% Complete',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _diagnosis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String stepNumber,
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: badgeColor,
            child: Text(
              stepNumber,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppChip(
                      label: badge,
                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                      textColor: badgeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCareCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_repair_service_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Guardian Care Guidelines',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Medication & Bathing Protocol:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Administer prescribed medication per dosing schedule. Maintain skin cleansing protocol and monitor appetite and activity daily.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Download PDF Sheet'),
            onPressed: () async {
              try {
                final dateFormat = DateFormat('MMM dd, yyyy');
                final nowStr = dateFormat.format(DateTime.now());
                final primaryColor = PdfColor.fromHex('#137A63');
                final secondaryColor = PdfColor.fromHex('#4F378A');
                final lightBg = PdfColor.fromHex('#F8FAFC');
                final borderColor = PdfColor.fromHex('#CBD5E1');

                final doc = pw.Document(title: 'Veterinary Home Care Treatment Protocol');
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
                                  'CLINICAL HOME CARE TREATMENT PROTOCOL',
                                  style: pw.TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'PetConnect AI Veterinary Network • Attending Clinic Prescription Sheet',
                                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8.5),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#E6F4F1'),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                border: pw.Border.all(color: primaryColor, width: 0.8),
                              ),
                              child: pw.Text(
                                'ISSUED: $nowStr',
                                style: pw.TextStyle(color: primaryColor, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
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
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('PetConnect AI Veterinary Protocol Sheet • For Guardian Reference', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          ],
                        ),
                      );
                    },
                    build: (pw.Context ctx) {
                      return [
                        // ── 1. DIAGNOSIS & CASE SUMMARY ───────────────────────
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                            border: pw.Border.all(color: borderColor, width: 0.8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('PRIMARY DIAGNOSIS / CLINICAL CONDITION', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                  pw.SizedBox(height: 2),
                                  pw.Text(_diagnosis, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                ],
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#E0E7FF'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  border: pw.Border.all(color: secondaryColor, width: 0.8),
                                ),
                                child: pw.Text('$_progress% Complete', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: secondaryColor)),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 2. PRESCRIBED MEDICATION SCHEDULE ─────────────────
                        pw.Text('PRESCRIBED MEDICATION SCHEDULE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 6),
                        pw.TableHelper.fromTextArray(
                          border: pw.TableBorder.all(color: borderColor, width: 0.5),
                          headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
                          headerDecoration: pw.BoxDecoration(color: primaryColor),
                          cellStyle: const pw.TextStyle(fontSize: 8),
                          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          headers: ['Medication', 'Dosage & Route', 'Frequency', 'Duration', 'Instructions'],
                          data: [
                            ['Amoxicillin / Clavulanate', '250 mg (Oral Tablet)', 'Twice Daily (q12h)', '10 Days', 'Administer with food to prevent gastric upset'],
                            ['Meloxicam (Metacam)', '0.1 mg/kg (Oral Liquid)', 'Once Daily (q24h)', '5 Days', 'Post-meal administration. Monitor for GI signs'],
                            ['Chlorhexidine Topical Rinse', '2% Solution (Topical)', 'Twice Daily', '14 Days', 'Gently cleanse affected dermatological area'],
                          ],
                        ),
                        pw.SizedBox(height: 12),

                        // ── 3. DAILY MONITORING CHECKLIST ────────────────────
                        pw.Text('DAILY CLINICAL MONITORING CHECKLIST', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: secondaryColor)),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: borderColor, width: 0.6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Body Temperature: Normal baseline is 101.0-102.5 deg F (38.3-39.2 deg C)', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Hydration & Appetite: Ensure complete water intake and normal food consumption', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Incision / Wound Inspection: Check daily for redness, swelling, or purulent discharge', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Elimination Habits: Confirm regular urination and normal stool consistency', style: const pw.TextStyle(fontSize: 8.5))]),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 4. ATTENDING VETERINARIAN NOTES ────────────────────
                        pw.Text('ATTENDING CLINICAL DIRECTIVES & PROTOCOL NOTES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: borderColor, width: 0.6),
                          ),
                          child: pw.Text(_notes, style: const pw.TextStyle(fontSize: 9, height: 1.35, color: PdfColors.grey900)),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 5. FOLLOW-UP & EMERGENCY RED FLAGS ───────────────
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FEF2F2'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5'), width: 0.8),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('🚨 CRITICAL RED FLAGS — CONTACT CLINIC IMMEDIATELY IF OBSERVED:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B'))),
                              pw.SizedBox(height: 3),
                              pw.Text('• Persistent vomiting or refusal to drink water for >12 hours.\n• Pale, blue, or muddy gum color.\n• Labored respiration, extreme lethargy, or inability to stand.', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#7F1D1D'))),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                );

                final bytes = await doc.save();
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/Home_Care_Treatment_Protocol.pdf');
                await file.writeAsBytes(bytes, flush: true);

                // ignore: deprecated_member_use
                await Share.shareXFiles(
                  [XFile(file.path, mimeType: 'application/pdf')],
                  text: '📋 Attached is the Veterinary Treatment Protocol (PDF).',
                  subject: 'Treatment Protocol (PDF)',
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not generate treatment protocol PDF.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiPrognosisCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colorScheme.tertiary, size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Prognosis Tracking',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clinical Remission Index:', style: theme.textTheme.bodySmall),
              Text(
                '$_progress% (On Target)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Therapeutic Tolerance:', style: theme.textTheme.bodySmall),
              AppChip(
                label: 'Optimal',
                backgroundColor: colorScheme.tertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected clinical remission within target timeframe with ongoing adherence.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
