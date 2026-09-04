import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:share_plus/share_plus.dart';

/// Modal dialog for generating and exporting high-impact Lost Pet Posters.
/// Designed after the classic cream-and-crimson missing pet poster template.
class LostPetPosterDialog extends ConsumerStatefulWidget {
  const LostPetPosterDialog({
    required this.pet,
    this.initialLocation,
    this.initialReward,
    this.initialPhone,
    this.initialNotes,
    super.key,
  });

  final Pet pet;
  final String? initialLocation;
  final String? initialReward;
  final String? initialPhone;
  final String? initialNotes;

  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    String? lastSeenLocation,
    String? rewardAmount,
    String? contactPhone,
    String? contactEmail,
    String? notes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => LostPetPosterDialog(
        pet: pet,
        initialLocation: lastSeenLocation,
        initialReward: rewardAmount,
        initialPhone: contactPhone,
        initialNotes: notes,
      ),
    );
  }

  @override
  ConsumerState<LostPetPosterDialog> createState() => _LostPetPosterDialogState();
}

class _LostPetPosterDialogState extends ConsumerState<LostPetPosterDialog> {
  late TextEditingController _locationController;
  late TextEditingController _rewardController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final String ownerDefaultLocation = (profile?.city != null && profile!.city!.trim().isNotEmpty)
        ? profile.city!.trim()
        : 'Home Vicinity / Local Neighborhood';

    _locationController = TextEditingController(
      text: (widget.initialLocation != null && widget.initialLocation!.trim().isNotEmpty)
          ? widget.initialLocation!
          : ownerDefaultLocation,
    );
    _rewardController = TextEditingController(
      text: widget.initialReward ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialPhone ?? (profile?.phone ?? ''),
    );
    _notesController = TextEditingController(
      text: widget.initialNotes ?? 'Please help find ${widget.pet.name}. Call immediately if spotted.',
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _rewardController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openEditDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customize Poster Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Last Seen Location',
                  hintText: 'e.g. Near City Park, Elm Street',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rewardController,
                decoration: const InputDecoration(
                  labelText: 'Reward Amount (Optional)',
                  hintText: 'e.g. RS. 5,000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  hintText: 'e.g. +91 9876543210',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save & Update'),
          ),
        ],
      ),
    ).then((_) => setState(() {}));
  }

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

  Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 8);
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

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final ownerPhone = _cleanText(_phoneController.text.isNotEmpty ? _phoneController.text : (profile?.phone ?? '8921998733'));
    final ownerEmail = _cleanText(profile?.email ?? 'antonythomson0610@gmail.com');
    final lastSeenLocation = _cleanText(_locationController.text);
    final rewardAmount = _cleanText(_rewardController.text);
    final todayStr = DateFormat('dd MMM').format(DateTime.now());

    final baseUrl = Env.webBaseUrl;
    final petNameEnc = Uri.encodeComponent(pet.name);
    final phoneEnc = Uri.encodeComponent(ownerPhone);
    final locEnc = Uri.encodeComponent(lastSeenLocation);
    final rewardEnc = Uri.encodeComponent(rewardAmount);
    final notesEnc = Uri.encodeComponent(_cleanText(_notesController.text));
    final cleanImg = (pet.imageUrl != null &&
            (pet.imageUrl!.startsWith('http://') || pet.imageUrl!.startsWith('https://')))
        ? pet.imageUrl!
        : '';
    final imgEnc = Uri.encodeComponent(cleanImg);

    final qrPayload = '$baseUrl/missing/${pet.id}?name=$petNameEnc&species=${Uri.encodeComponent(pet.species)}&breed=${Uri.encodeComponent(pet.breed ?? "")}&phone=$phoneEnc&location=$locEnc&reward=$rewardEnc&notes=$notesEnc&img=$imgEnc';

    const creamBg = Color(0xFFFAF6EE);
    const crimsonColor = Color(0xFFB91C1C);
    const goldAccent = Color(0xFFB45309);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: creamBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E0D0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── TOP CRIMSON BANNER PILL ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: crimsonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'MISSING ${pet.species.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                AppSpacing.vGapMd,

                // ── PET NAME & BREED ───────────────────────────────────
                Text(
                  pet.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: crimsonColor,
                    letterSpacing: 1.5,
                    fontFamily: 'serif',
                  ),
                ),
                Text(
                  pet.breedLine.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                AppSpacing.vGapMd,

                // ── HERO PET PHOTO ─────────────────────────────────────
                Container(
                  width: 220,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFE5E7EB),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                        ? Image.network(
                            pet.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackAvatar(pet),
                          )
                        : _buildFallbackAvatar(pet),
                  ),
                ),
                AppSpacing.vGapMd,

                // ── DETAILS ROWS ───────────────────────────────────────
                InkWell(
                  onTap: _openEditDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LAST SEEN LOCATION: ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
                        ),
                        Expanded(
                          child: Text(
                            lastSeenLocation.isNotEmpty ? lastSeenLocation : 'Neighborhood / Home Area',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 12, thickness: 1.0, color: Color(0xFFD1D5DB)),
                InkWell(
                  onTap: _openEditDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Text(
                          'MISSING SINCE: ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
                        ),
                        Text(
                          todayStr,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 12, thickness: 1.0, color: Color(0xFFD1D5DB)),
                AppSpacing.vGapSm,

                // ── GOLDEN REWARD BOX ──────────────────────────────────
                if (rewardAmount.isNotEmpty)
                  InkWell(
                    onTap: _openEditDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: goldAccent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🐾 $rewardAmount CASH REWARD *',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'NO QUESTIONS ASKED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.0,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                AppSpacing.vGapMd,

                // ── EMERGENCY CONTACT & QR CODE ─────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IF FOUND OR SIGHTED, PLEASE CALL IMMEDIATELY:',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ownerPhone,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Email: $ownerEmail',
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF4B5563)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Generated via PetConnect AI Emergency Rescue Network * Scan QR code to notify owner immediately',
                            style: TextStyle(fontSize: 7.5, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    PetQrCodeView(
                      data: qrPayload,
                      size: 80,
                      padding: 2,
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── ACTION BUTTONS ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share Alert'),
                        onPressed: () async {
                          await HapticFeedback.lightImpact();
                          await ExternalActions.shareText(
                            '🚨 MISSING PET ALERT: ${pet.name.toUpperCase()}!\n'
                            'Species: ${pet.species} • Breed: ${pet.breed ?? "Unknown"}\n'
                            'Last Seen: $lastSeenLocation\n'
                            'Reward: $rewardAmount\n\n'
                            'Emergency Phone: $ownerPhone\n'
                            'Contact immediately if sighted.',
                            subject: '🚨 MISSING PET ALERT: ${pet.name}',
                          );
                        },
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: FilledButton.icon(
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF'),
                        onPressed: _isGeneratingPdf
                            ? null
                            : () async {
                                setState(() => _isGeneratingPdf = true);
                                try {
                                  final imgBytes = await _fetchImageBytes(pet.imageUrl);

                                  final doc = pw.Document(
                                    title: 'MISSING PET: ${pet.name}',
                                    author: 'PetConnect AI Emergency Rescue',
                                  );

                                  doc.addPage(
                                    pw.Page(
                                      pageFormat: PdfPageFormat.a4,
                                      margin: const pw.EdgeInsets.all(28),
                                      build: (pw.Context ctx) {
                                        return pw.Container(
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromHex('#FAF6EE'), // Template cream
                                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                                          ),
                                          padding: const pw.EdgeInsets.all(24),
                                          child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                                            children: [
                                              // ── TOP CRIMSON BANNER PILL ──
                                              pw.Container(
                                                width: double.infinity,
                                                padding: const pw.EdgeInsets.symmetric(vertical: 14),
                                                decoration: pw.BoxDecoration(
                                                  color: PdfColor.fromHex('#B91C1C'),
                                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                                                ),
                                                child: pw.Text(
                                                  'MISSING ${pet.species.toUpperCase()}',
                                                  textAlign: pw.TextAlign.center,
                                                  style: const pw.TextStyle(
                                                    color: PdfColors.white,
                                                    fontSize: 32,
                                                    fontWeight: pw.FontWeight.bold,
                                                    letterSpacing: 2.5,
                                                  ),
                                                ),
                                              ),
                                              pw.SizedBox(height: 14),

                                              // ── PET NAME & BREED ──
                                              pw.Text(
                                                pet.name.toUpperCase(),
                                                style: pw.TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColor.fromHex('#B91C1C'),
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              pw.SizedBox(height: 2),
                                              pw.Text(
                                                pet.breedLine.toLowerCase(),
                                                style: const pw.TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColors.grey900,
                                                ),
                                              ),
                                              pw.SizedBox(height: 14),

                                              // ── HERO PET PHOTO ──
                                              if (imgBytes != null)
                                                pw.Container(
                                                  height: 280,
                                                  width: 340,
                                                  child: pw.ClipRRect(
                                                    horizontalRadius: 16,
                                                    verticalRadius: 16,
                                                    child: pw.Image(
                                                      pw.MemoryImage(imgBytes),
                                                      fit: pw.BoxFit.cover,
                                                    ),
                                                  ),
                                                )
                                              else
                                                pw.Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: pw.BoxDecoration(
                                                    color: PdfColor.fromHex('#E5E7EB'),
                                                    shape: pw.BoxShape.circle,
                                                  ),
                                                  child: pw.Center(
                                                    child: pw.Text(
                                                      pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'PET',
                                                      style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B91C1C')),
                                                    ),
                                                  ),
                                                ),
                                              pw.SizedBox(height: 16),

                                              // ── DETAILS ROWS ──
                                              pw.Row(
                                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                children: [
                                                  pw.Text(
                                                    'LAST SEEN LOCATION: ',
                                                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black),
                                                  ),
                                                  pw.Expanded(
                                                    child: pw.Text(
                                                      lastSeenLocation.isNotEmpty ? lastSeenLocation : 'Neighborhood / Home Area',
                                                      style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey900),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              pw.SizedBox(height: 6),
                                              pw.Divider(color: PdfColor.fromHex('#D1D5DB'), thickness: 1.0),
                                              pw.SizedBox(height: 6),
                                              pw.Row(
                                                children: [
                                                  pw.Text(
                                                    'MISSING SINCE: ',
                                                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black),
                                                  ),
                                                  pw.Text(
                                                    todayStr,
                                                    style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey900),
                                                  ),
                                                ],
                                              ),
                                              pw.SizedBox(height: 6),
                                              pw.Divider(color: PdfColor.fromHex('#D1D5DB'), thickness: 1.0),
                                              pw.SizedBox(height: 12),

                                              // ── GOLDEN REWARD BANNER ──
                                              if (rewardAmount.isNotEmpty)
                                                pw.Container(
                                                  width: double.infinity,
                                                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                  decoration: pw.BoxDecoration(
                                                    color: PdfColor.fromHex('#FEF3C7'),
                                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                                                    border: pw.Border.all(color: PdfColor.fromHex('#B45309'), width: 1.5),
                                                  ),
                                                  child: pw.Column(
                                                    children: [
                                                      pw.Text(
                                                        '* $rewardAmount CASH REWARD *',
                                                        style: pw.TextStyle(
                                                          color: PdfColor.fromHex('#78350F'),
                                                          fontWeight: pw.FontWeight.bold,
                                                          fontSize: 16,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      pw.SizedBox(height: 2),
                                                      pw.Text(
                                                        'NO QUESTIONS ASKED',
                                                        style: pw.TextStyle(
                                                          color: PdfColor.fromHex('#78350F'),
                                                          fontWeight: pw.FontWeight.bold,
                                                          fontSize: 16,
                                                          letterSpacing: 1.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              pw.Spacer(),

                                              // ── EMERGENCY CONTACT & QR CODE ──
                                              pw.Row(
                                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                                children: [
                                                  pw.Expanded(
                                                    child: pw.Column(
                                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                      children: [
                                                        pw.Text(
                                                          'IF FOUND OR SIGHTED, PLEASE CALL IMMEDIATELY:',
                                                          style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                                        ),
                                                        pw.SizedBox(height: 4),
                                                        pw.Text(
                                                          ownerPhone,
                                                          style: const pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                                        ),
                                                        pw.SizedBox(height: 2),
                                                        pw.Text('Email: $ownerEmail', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                                        pw.SizedBox(height: 4),
                                                        pw.Text(
                                                          'Generated via PetConnect AI Emergency Rescue Network * Scan QR code to notify owner immediately',
                                                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  pw.SizedBox(width: 14),
                                                  pw.BarcodeWidget(
                                                    data: qrPayload,
                                                    barcode: pw.Barcode.qrCode(),
                                                    width: 85,
                                                    height: 85,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );

                                  final pdfBytes = await doc.save();
                                  final tempDir = await getTemporaryDirectory();
                                  final sanitized = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
                                  final file = File('${tempDir.path}/${sanitized}_Missing_Poster.pdf');
                                  await file.writeAsBytes(pdfBytes, flush: true);

                                  // ignore: deprecated_member_use
                                  await Share.shareXFiles(
                                    [XFile(file.path, mimeType: 'application/pdf')],
                                    text: '🚨 Missing Pet Poster (PDF) for ${pet.name}. Print or distribute immediately.',
                                    subject: 'MISSING PET POSTER: ${pet.name}',
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to generate poster PDF. Please try again.')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isGeneratingPdf = false);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(Pet pet) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: Text(
          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'P',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB91C1C),
          ),
        ),
      ),
    );
  }
}
