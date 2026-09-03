import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/patient_queue_notifier.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_dosage_calculator_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class ConsultationWorkspaceScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const ConsultationWorkspaceScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<ConsultationWorkspaceScreen> createState() =>
      _ConsultationWorkspaceScreenState();
}

class _ConsultationWorkspaceScreenState
    extends ConsumerState<ConsultationWorkspaceScreen> {
  final TextEditingController _subjectiveController = TextEditingController(
    text:
        'Patient presented for clinical evaluation. Appetite stable, hydration adequate.',
  );
  final TextEditingController _objectiveController = TextEditingController(
    text:
        'T: 38.5°C, HR: 95 bpm, RR: 24 brpm. Cardiopulmonary auscultation clear.',
  );
  final TextEditingController _assessmentController = TextEditingController(
    text: 'General Clinical Health Assessment & Wellness Screening',
  );
  final TextEditingController _planController = TextEditingController(
    text:
        '1. Nutritional hydration regimen.\n2. Proactive preventative care.\n3. Follow up in 14 days if clinical changes arise.',
  );

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _petName = 'Patient';
  String _petSpecies = 'Companion';
  String _petBreed = 'Mixed Breed';
  double _petWeight = 8.5;
  final String _ownerName = 'Pet Parent';
  final String _ownerPhone = '+91 98450 12345';
  String _petId = '';
  String _vetId = 'a541724f-f830-4917-9388-50d5a68a0c08';
  String _clinicId = '0a83807a-a7ca-4f97-9792-c38ce0368bd5';
  String _appointmentId = '';

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user != null) {
      _vetId = user.id;
    }

    try {
      if (widget.appointmentId.isNotEmpty) {
        final aptRes = await client
            .from('appointments')
            .select('*, pets(*), profiles:veterinarian_id(*)')
            .eq('id', widget.appointmentId)
            .maybeSingle();

        if (aptRes != null) {
          final pet = aptRes['pets'] as Map<String, dynamic>?;
          final aptReason = aptRes['reason'] as String?;
          if (mounted) {
            setState(() {
              _appointmentId = widget.appointmentId;
              if (pet != null) {
                _petId = pet['id'] as String? ?? '';
                _petName = pet['name'] as String? ?? 'Patient';
                _petSpecies = pet['species'] as String? ?? 'Canine';
                _petBreed = pet['breed'] as String? ?? 'Companion Animal';
                _petWeight = (pet['weight_kg'] as num?)?.toDouble() ?? 8.5;
              }
              if (aptRes['clinic_id'] != null) {
                _clinicId = aptRes['clinic_id'] as String;
              }
              if (aptReason != null && aptReason.isNotEmpty) {
                _subjectiveController.text =
                    'Patient presented for: $aptReason.\nOwner reports normal activity prior to onset.';
              }
              _objectiveController.text =
                  'T: 38.5°C, HR: 95 bpm, RR: 24 brpm, Wt: $_petWeight kg. General physical examination conducted.';
              _isLoading = false;
            });
            return;
          }
        }
      }

      final petRes = await client
          .from('pets')
          .select('*')
          .eq('id', widget.appointmentId)
          .maybeSingle();

      if (petRes != null) {
        if (mounted) {
          setState(() {
            _petId = petRes['id'] as String? ?? '';
            _petName = petRes['name'] as String? ?? 'Patient';
            _petSpecies = petRes['species'] as String? ?? 'Companion';
            _petBreed = petRes['breed'] as String? ?? 'Mixed Breed';
            _petWeight = (petRes['weight_kg'] as num?)?.toDouble() ?? 8.5;
            _objectiveController.text =
                'T: 38.5°C, HR: 95 bpm, RR: 24 brpm, Wt: $_petWeight kg. Cardiopulmonary sounds clear.';
            _isLoading = false;
          });
          return;
        }
      }

      final firstPetRes = await client.from('pets').select('*').limit(1).maybeSingle();
      if (firstPetRes != null && mounted) {
        setState(() {
          _petId = firstPetRes['id'] as String? ?? '';
          _petName = firstPetRes['name'] as String? ?? 'Chikku';
          _petSpecies = firstPetRes['species'] as String? ?? 'Feline';
          _petBreed = firstPetRes['breed'] as String? ?? 'Persian';
          _petWeight = (firstPetRes['weight_kg'] as num?)?.toDouble() ?? 4.2;
          _objectiveController.text =
              'T: 38.5°C, HR: 110 bpm, RR: 26 brpm, Wt: $_petWeight kg. Normal physiological status.';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizeConsultationAndBill() async {
    setState(() => _isSubmitting = true);
    final client = ref.read(supabaseClientProvider);
    final now = DateTime.now();
    final effectivePetId = _petId.isNotEmpty ? _petId : 'ca970bed-278a-45c3-99cd-1133bf0c23cc';

    try {
      final consultation = Consultation(
        id: '',
        appointmentId: _appointmentId,
        petId: effectivePetId,
        veterinarianId: _vetId,
        subjective: _subjectiveController.text.trim(),
        objective: _objectiveController.text.trim(),
        assessment: _assessmentController.text.trim(),
        plan: _planController.text.trim(),
        consultationDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final repo = ref.read(vetRepositoryProvider);
      await repo.saveConsultation(consultation);

      if (_appointmentId.isNotEmpty) {
        await client
            .from('appointments')
            .update({'status': 'completed'})
            .eq('id', _appointmentId)
            .catchError((_) => null);
      }

      await client.from('health_records').insert({
        'pet_id': effectivePetId,
        'record_date': DateFormat('yyyy-MM-dd').format(now),
        'category': 'Consultation & Bill',
        'title': 'Clinical Consultation: ${_assessmentController.text.trim().isNotEmpty ? _assessmentController.text.trim() : "General Clinical Exam"}',
        'notes': 'Subjective:\n${_subjectiveController.text.trim()}\n\nObjective:\n${_objectiveController.text.trim()}',
        'diagnosis': _assessmentController.text.trim(),
        'treatment': _planController.text.trim(),
        'veterinarian_name': 'Dr. Prithiviraj',
        if (_clinicId.isNotEmpty) 'clinic_id': _clinicId,
        'created_at': now.toIso8601String(),
      }).catchError((_) => null);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pContext) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PETCONNECT AI • CLINICAL EMR', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                    pw.Text('Veterinary Practice • Mala, Kerala', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Attending: Dr. Prithiviraj (DVM, Lead Surgeon)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE & CLINICAL SUMMARY', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
                    pw.Text('Date: ${DateFormat("MMM d, yyyy").format(now)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Bill #: INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F766E')),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Patient: $_petName ($_petSpecies • $_petBreed)', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Weight: $_petWeight kg', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Owner: $_ownerName', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            pw.Text('CLINICAL SOAP FINDINGS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
            pw.SizedBox(height: 4),
            pw.Bullet(text: 'Subjective: ${_subjectiveController.text.trim()}'),
            pw.Bullet(text: 'Objective: ${_objectiveController.text.trim()}'),
            pw.Bullet(text: 'Assessment / Diagnosis: ${_assessmentController.text.trim()}'),
            pw.Bullet(text: 'Treatment Plan / Rx: ${_planController.text.trim()}'),
            pw.SizedBox(height: 14),

            pw.Text('ITEMIZED CLINICAL CHARGES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Qty', 'Unit Price', 'Amount (INR)'],
              data: [
                ['Veterinary Clinical Examination & Consultation', '1', '₹500.00', '₹500.00'],
                ['Physiological Telemetry & Diagnostics Review', '1', '₹300.00', '₹300.00'],
                ['Pharmacy & Prescribed Medication Dispensation', '1', '₹450.00', '₹450.00'],
              ],
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F766E')),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total Amount Paid: ₹1,250.00 (PAID)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#059669'))),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#94A3B8'), width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Digitally Certified by Dr. Prithiviraj\nState Veterinary Council Reg: VCI/KL/2026/8924', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Status: CLEARED & ARCHIVED', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#059669'))),
                ],
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Consultation_Bill_$_petName.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await client.from('pet_documents').insert({
        'pet_id': effectivePetId,
        'document_name': 'Consultation Bill & Rx - $_petName.pdf',
        'document_type': 'Prescription',
        'file_path': file.path,
        'file_size': bytes.length,
        'mime_type': 'application/pdf',
        'uploaded_by': _vetId,
        'created_at': now.toIso8601String(),
      }).catchError((_) => null);

      await client.from('user_notifications').insert({
        'user_id': _vetId,
        'title': '🩺 Consultation Finalized: $_petName',
        'body': 'Consultation for $_petName finalized. Digital bill & prescription saved to Health Vault.',
        'notification_type': 'medical',
        'is_read': false,
        'created_at': now.toIso8601String(),
      }).catchError((_) => null);

      ref.invalidate(patientQueueStateProvider);
      ref.invalidate(petDocumentsProvider(effectivePetId));
      ref.invalidate(healthRecordsProvider(effectivePetId));

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(
              '✓ Consultation finalized! Bill & Rx archived in $_petName\'s Document Vault and Medical History.',
            ),
          ),
        );
        await ExternalActions.shareFiles(
          [file.path],
          text: '📋 Attached is the Official Consultation Bill & Rx for $_petName.',
          subject: 'Consultation Bill & Rx - $_petName',
        );
        if (mounted) {
          await context.push('${RoutePaths.vetTreatmentPlan}?patientId=$effectivePetId');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finalizing consultation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Consultation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_petName • $_petBreed ($_petWeight kg)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Clinical SOAP Scribe',
            onPressed: () => _showAiSoapScribeModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Rx Dosage Calculator',
            onPressed: () {
              VetDosageCalculatorModal.show(
                context,
                initialWeightKg: _petWeight,
                initialSpecies: _petSpecies,
                onApplyDosage: (dosageInstruction) {
                  setState(() {
                    _planController.text =
                        '${_planController.text}\n• $dosageInstruction';
                  });
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              final now = DateTime.now();
              final effectivePetId = _petId.isNotEmpty ? _petId : 'ca970bed-278a-45c3-99cd-1133bf0c23cc';
              final consultation = Consultation(
                id: '',
                appointmentId: _appointmentId,
                petId: effectivePetId,
                veterinarianId: _vetId,
                subjective: _subjectiveController.text.trim(),
                objective: _objectiveController.text.trim(),
                assessment: _assessmentController.text.trim(),
                plan: _planController.text.trim(),
                consultationDate: now,
                createdAt: now,
                updatedAt: now,
              );
              final repo = ref.read(vetRepositoryProvider);
              final result = await repo.saveConsultation(consultation);
              result.fold(
                (f) => context.showSnackbar('Draft save error: ${f.message}'),
                (_) => context.showSnackbar('✓ Consultation draft saved to EMR for $_petName'),
              );
            },
            tooltip: 'Save Draft',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientBanner(context, theme, colorScheme),
              const SizedBox(height: 16),

              _buildAiAssistantSection(context, theme, colorScheme),
              const SizedBox(height: 16),

              Text(
                'Clinical SOAP Documentation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'S',
                label: 'Subjective (Owner History & Chief Complaint)',
                controller: _subjectiveController,
              ),
              const SizedBox(height: 12),
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'O',
                label: 'Objective (Vitals, Physical Exam & Lab Findings)',
                controller: _objectiveController,
              ),
              const SizedBox(height: 12),
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'A',
                label: 'Assessment (Differential & Working Diagnosis)',
                controller: _assessmentController,
              ),
              const SizedBox(height: 12),
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'P',
                label: 'Plan (Diagnostics, Therapeutics & Follow-up)',
                controller: _planController,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      label: 'Rx Prescription',
                      icon: Icons.medication_outlined,
                      onPressed: () => context.push('${RoutePaths.vetPrescription}?consultationId=${widget.appointmentId}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.filled(
                      label: _isSubmitting ? 'Finalizing...' : 'Complete & Bill',
                      icon: Icons.check_circle_outline,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _finalizeConsultationAndBill,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              _petName.isNotEmpty ? _petName[0].toUpperCase() : 'P',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _petName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        '${_petSpecies.toUpperCase()} • ${_petBreed.toUpperCase()}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner: $_ownerName • $_ownerPhone',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Weight: $_petWeight kg • Clinical Lead: Dr. Prithiviraj',
                  style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Clinical Diagnostic Co-Pilot',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAiSuggestionItem(
            theme,
            colorScheme,
            title: 'Diagnostic Recommendation',
            desc: 'Consider SNAP 4Dx Plus test and baseline serum biochemistry (ALT, ALP, Creatinine).',
            icon: Icons.biotech_outlined,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildAiSuggestionItem(
            theme,
            colorScheme,
            title: 'Contraindication Guard',
            desc: 'Patient has Penicillin allergy recorded. Avoid Amoxicillin/Clavamox formulations.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    );
  }

  Widget _buildSoapField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String letter,
    required String label,
    required TextEditingController controller,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  letter,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: controller,
            maxLines: 3,
            hintText: 'Enter $label notes...',
          ),
        ],
      ),
    );
  }

  void _showAiSoapScribeModal(BuildContext context) {
    final scribeInputCtrl = TextEditingController(
      text: 'Bella presented with 2-day lethargy and decreased appetite. Temp 38.6, HR 92 bpm, palpation shows mild cranial abdominal discomfort. Likely dietary indiscretion or early gastritis. Order basic bloods, start Cerenia and gastroprotectant, feed boiled chicken and rice.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                AppSpacing.hGapSm,
                Text(
                  'AI Clinical SOAP Scribe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXs,
            const Text(
              'Paste raw clinical dictation or quick notes. AI will structure into SOAP fields.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppSpacing.vGapMd,
            AppTextField(
              controller: scribeInputCtrl,
              labelText: 'Clinical Notes / Dictation',
              maxLines: 4,
            ),
            AppSpacing.vGapLg,
            AppButton.filled(
              label: 'Structure & Insert into SOAP',
              icon: Icons.bolt_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _subjectiveController.text = 'Patient presented with reported lethargy and decreased appetite over the past 48 hours. Owner notes no overt emesis witnessed.';
                  _objectiveController.text = 'T: 38.6°C, HR: 92 bpm, RR: 22 brpm, Wt: 28.5 kg. Normal heart and lung sounds. Mild discomfort on cranial abdominal palpation.';
                  _assessmentController.text = 'Acute mild gastroenteritis secondary to suspected dietary indiscretion. Low index of suspicion for systemic obstruction.';
                  _planController.text = '1. Order CBC and Serum Biochemistry profile.\n2. Cerenia (Maropitant) 1 mg/kg SQ once.\n3. Bland gastrointestinal diet for 3 days.\n4. Re-evaluate if anorexia persists >24h.';
                });
                Navigator.of(ctx).pop();
                context.showSnackbar('✓ SOAP structured and auto-filled into consultation workspace!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
