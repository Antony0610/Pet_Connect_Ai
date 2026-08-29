import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:share_plus/share_plus.dart';

/// Modal dialog that generates a high-visibility, official "LOST PET" poster
/// complete with pet details, editable last known location, reward badge in INR (₹),
/// and emergency QR code + full-page A4 PDF export with embedded photo.
class LostPetPosterDialog extends ConsumerStatefulWidget {
  const LostPetPosterDialog({
    super.key,
    required this.pet,
    this.initialLastSeenLocation = 'Indiranagar 100ft Road / Near Metro Station',
    this.initialRewardAmount = '₹5,000',
  });

  final Pet pet;
  final String initialLastSeenLocation;
  final String initialRewardAmount;

  /// Convenience helper to display the poster dialog.
  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    String lastSeenLocation = 'Indiranagar 100ft Road / Near Metro Station',
    String rewardAmount = '₹5,000',
  }) async {
    await HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LostPetPosterDialog(
            pet: pet,
            initialLastSeenLocation: lastSeenLocation,
            initialRewardAmount: rewardAmount,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LostPetPosterDialog> createState() => _LostPetPosterDialogState();
}

class _LostPetPosterDialogState extends ConsumerState<LostPetPosterDialog> {
  late final TextEditingController _locationController;
  late final TextEditingController _rewardController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLastSeenLocation);
    _rewardController = TextEditingController(text: widget.initialRewardAmount);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _fetchPetImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 8);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
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

  void _openEditDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Poster Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Last Seen Location',
                hintText: 'e.g. Indiranagar, Bengaluru / Near Park',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _rewardController,
              decoration: const InputDecoration(
                labelText: 'Reward Amount (INR)',
                hintText: 'e.g. ₹5,000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final scheme = context.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final rawPhone = profileAsync.valueOrNull?.phone?.trim();
    final hasRealPhone = rawPhone != null && rawPhone.isNotEmpty;
    final ownerPhone = hasRealPhone ? rawPhone : 'Contact Guardian via App';
    final ownerEmail = profileAsync.valueOrNull?.email ?? 'emergency@petconnect.ai';
    final todayStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final lastSeenLocation = _locationController.text.trim();
    final rewardAmount = _rewardController.text.trim();

    final qrPayload = 'https://petconnect.ai/emergency/${pet.id}?'
        'lost=true&'
        'name=${Uri.encodeComponent(pet.name)}&'
        'phone=${Uri.encodeComponent(ownerPhone)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: scheme.error, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── TOP HEADER BANNER ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'MISSING ${pet.species.toUpperCase()} 🚨',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // ── PET NAME ──────────────────────────────────────────────
            Text(
              pet.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: scheme.error,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              pet.breedLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            AppSpacing.vGapMd,

            // ── PET PHOTO & DETAILS ROW ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.error, width: 2),
                    borderRadius: BorderRadius.circular(52),
                  ),
                  child: UserAvatar(
                    imageUrl: pet.imageUrl,
                    name: pet.name,
                    radius: 46,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPosterField('Species', pet.species.toUpperCase()),
                      _buildPosterField('Gender', pet.gender?.toUpperCase() ?? 'UNKNOWN'),
                      _buildPosterField('Weight', pet.weightKg != null ? '${pet.weightKg} kg' : 'Not specified'),
                      _buildPosterField('Microchip', pet.microchipId?.isNotEmpty == true ? 'CHIPPED' : 'Not chipped'),
                      _buildPosterField('Date Missing', todayStr),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,

            // ── LAST SEEN LOCATION BOX ────────────────────────────────
            InkWell(
              onTap: _openEditDialog,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: scheme.error),
                              AppSpacing.hGapXs,
                              const Text(
                                'LAST SEEN LOCATION:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastSeenLocation,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // ── REWARD BADGE (INR) ────────────────────────────────────
            if (rewardAmount.isNotEmpty)
              InkWell(
                onTap: _openEditDialog,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '⭐ $rewardAmount REWARD — NO QUESTIONS ASKED ⭐',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(Icons.edit_outlined, size: 14, color: Colors.amber.shade900),
                    ],
                  ),
                ),
              ),
            AppSpacing.vGapMd,

            // ── QR CODE & DIRECT CONTACT ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PetQrCodeView(
                  data: qrPayload,
                  size: 110,
                  padding: 4,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IF SEEN PLEASE CALL IMMEDIATELY:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      Text(
                        ownerPhone,
                        style: TextStyle(
                          fontSize: hasRealPhone ? 18 : 13,
                          fontWeight: FontWeight.w900,
                          color: scheme.error,
                        ),
                      ),
                      if (!hasRealPhone) ...[
                        const SizedBox(height: 2),
                        Text(
                          '(Add phone in Profile to show direct number)',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Text(
                        'Scan QR code with any phone camera to view full pet profile & notify guardian instantly.',
                        style: TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // ── ACTION BUTTONS ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'Share Info',
                    icon: Icons.share,
                    onPressed: () async {
                      await HapticFeedback.lightImpact();
                      await ExternalActions.shareText(
                        '🚨 MISSING PET ALERT: ${pet.name.toUpperCase()}!\n'
                        'Species: ${pet.species} • Breed: ${pet.breed ?? "Unknown"}\n'
                        'Last Seen: $lastSeenLocation\n'
                        'Reward: $rewardAmount\n\n'
                        'If found, please scan or view: $qrPayload\n'
                        'Emergency Call: $ownerPhone',
                        subject: '🚨 MISSING PET: ${pet.name}',
                      );
                    },
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: AppButton.filled(
                    label: _isGeneratingPdf ? 'Generating...' : 'Export Poster (PDF)',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: _isGeneratingPdf
                        ? null
                        : () async {
                            await HapticFeedback.lightImpact();
                            setState(() => _isGeneratingPdf = true);

                            try {
                              final imgBytes = await _fetchPetImageBytes(pet.imageUrl);
                              final doc = pw.Document(title: 'Missing Pet Poster - ${pet.name}');

                              doc.addPage(
                                pw.Page(
                                  pageFormat: PdfPageFormat.a4,
                                  margin: const pw.EdgeInsets.all(28),
                                  build: (pw.Context ctx) {
                                    return pw.Container(
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(color: PdfColors.red800, width: 4),
                                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                                      ),
                                      padding: const pw.EdgeInsets.all(18),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                                        children: [
                                          // Header
                                          pw.Container(
                                            width: double.infinity,
                                            padding: const pw.EdgeInsets.symmetric(vertical: 12),
                                            decoration: const pw.BoxDecoration(
                                              color: PdfColors.red700,
                                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                                            ),
                                            child: pw.Center(
                                              child: pw.Text(
                                                'MISSING ${pet.species.toUpperCase()} 🚨',
                                                style: const pw.TextStyle(
                                                  color: PdfColors.white,
                                                  fontSize: 26,
                                                  fontWeight: pw.FontWeight.bold,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(height: 14),

                                          // Pet Name
                                          pw.Text(
                                            pet.name.toUpperCase(),
                                            style: const pw.TextStyle(
                                              fontSize: 32,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.red900,
                                            ),
                                          ),
                                          pw.SizedBox(height: 4),
                                          pw.Text(
                                            pet.breedLine,
                                            style: const pw.TextStyle(
                                              fontSize: 15,
                                              color: PdfColors.grey800,
                                            ),
                                          ),
                                          pw.SizedBox(height: 14),

                                          // Pet Photo
                                          if (imgBytes != null)
                                            pw.Container(
                                              height: 180,
                                              width: 180,
                                              decoration: pw.BoxDecoration(
                                                border: pw.Border.all(color: PdfColors.red700, width: 3),
                                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                                              ),
                                              child: pw.ClipRRect(
                                                horizontalRadius: 9,
                                                verticalRadius: 9,
                                                child: pw.Image(
                                                  pw.MemoryImage(imgBytes),
                                                  fit: pw.BoxFit.cover,
                                                ),
                                              ),
                                            )
                                          else
                                            pw.Container(
                                              height: 120,
                                              width: 120,
                                              decoration: pw.BoxDecoration(
                                                color: PdfColors.grey200,
                                                shape: pw.BoxShape.circle,
                                                border: pw.Border.all(color: PdfColors.red400, width: 2),
                                              ),
                                              child: pw.Center(
                                                child: pw.Text(
                                                  pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'PET',
                                                  style: const pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
                                                ),
                                              ),
                                            ),
                                          pw.SizedBox(height: 14),

                                          // Location Box
                                          pw.Container(
                                            width: double.infinity,
                                            padding: const pw.EdgeInsets.all(12),
                                            decoration: pw.BoxDecoration(
                                              color: PdfColor.fromHex('#FEF2F2'),
                                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                                              border: pw.Border.all(color: PdfColors.red300, width: 1.5),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Row(children: [
                                                  pw.Text('LAST SEEN LOCATION: ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red900)),
                                                  pw.Expanded(child: pw.Text(lastSeenLocation, style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                                                ]),
                                                pw.SizedBox(height: 6),
                                                pw.Row(children: [
                                                  pw.Text('SPECIES & GENDER: ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                                  pw.Text('${pet.species.toUpperCase()} (${pet.gender?.toUpperCase() ?? "UNKNOWN"})', style: const pw.TextStyle(fontSize: 11)),
                                                  pw.SizedBox(width: 20),
                                                  pw.Text('MICROCHIP: ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                                  pw.Text(pet.microchipId?.isNotEmpty == true ? 'CHIPPED' : 'NOT CHIPPED', style: const pw.TextStyle(fontSize: 11)),
                                                ]),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 12),

                                          // Reward Banner
                                          if (rewardAmount.isNotEmpty)
                                            pw.Container(
                                              width: double.infinity,
                                              padding: const pw.EdgeInsets.symmetric(vertical: 8),
                                              decoration: pw.BoxDecoration(
                                                color: PdfColor.fromHex('#FEF3C7'),
                                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                                border: pw.Border.all(color: PdfColors.amber800, width: 1.5),
                                              ),
                                              child: pw.Center(
                                                child: pw.Text(
                                                  '⭐ $rewardAmount CASH REWARD — NO QUESTIONS ASKED ⭐',
                                                  style: const pw.TextStyle(
                                                    color: PdfColors.amber900,
                                                    fontWeight: pw.FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          pw.Spacer(),

                                          // Emergency Call & QR
                                          pw.Container(
                                            width: double.infinity,
                                            padding: const pw.EdgeInsets.all(12),
                                            decoration: const pw.BoxDecoration(
                                              color: PdfColors.grey100,
                                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                                            ),
                                            child: pw.Row(
                                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                              children: [
                                                pw.Expanded(
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                    children: [
                                                      pw.Text(
                                                        'IF FOUND OR SIGHTED, PLEASE CALL IMMEDIATELY:',
                                                        style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                                                      ),
                                                      pw.SizedBox(height: 4),
                                                      pw.Text(
                                                        ownerPhone,
                                                        style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                                                      ),
                                                      pw.SizedBox(height: 2),
                                                      pw.Text('Email: $ownerEmail', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                                    ],
                                                  ),
                                                ),
                                                pw.BarcodeWidget(
                                                  data: qrPayload,
                                                  barcode: pw.Barcode.qrCode(),
                                                  width: 75,
                                                  height: 75,
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 6),
                                          pw.Text(
                                            'Generated via PetConnect AI Emergency Rescue Network • Scan QR code to notify owner immediately',
                                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
                                  const SnackBar(content: Text('Could not generate PDF poster.')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isGeneratingPdf = false);
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
